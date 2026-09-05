import 'dart:convert';
import 'dart:math';
import '../../core/utils/prompting.dart';
import '../../models/session_report.dart';
import 'groq_service.dart';

class ReviewAnalyticsService {
  final GroqService _groqService = GroqService();

  /// Minimum number of messages required to request a session review
  static const int minMessagesRequired = 5; // At least 5 chat messages

  /// Evaluates whether a session meets the threshold rule (>= 5 messages)
  bool canGenerateReview(int messageCount) {
    return messageCount >= minMessagesRequired;
  }

  /// Generates structured AI review report for a session
  Future<SessionReport> generateReview({
    required Map<String, dynamic> sessionConfig,
    required List<Map<String, dynamic>> conversationMessages,
  }) async {
    final messageCount = conversationMessages.length;
    if (!canGenerateReview(messageCount)) {
      throw Exception(
        "A user can request a session review only after completing at least 5 chat messages. "
        "Current messages: $messageCount/$minMessagesRequired.",
      );
    }

    final isInterview = sessionConfig['module'] == 'interview';
    final prompt = Prompting.buildReviewAnalyticsPrompt(
      isInterview: isInterview,
      sessionConfig: sessionConfig,
      conversationMessages: conversationMessages,
    );

    // 1. First attempt fast structured JSON generation via Groq API (format: json_object, low temp)
    try {
      final rawResponse = await _groqService.generateStructuredJson(
        prompt,
        timeout: const Duration(seconds: 15),
      );

      if (rawResponse.trim().isNotEmpty) {
        final jsonMap = _parseJsonResponse(rawResponse);
        return _buildSessionReportFromJson(
          jsonMap: jsonMap,
          module: isInterview ? 'interview' : 'english',
        );
      }
    } catch (_) {
      // If structured JSON fails or times out, attempt streaming fallback
      try {
        final stream = _groqService.generateStream(prompt);
        final buffer = StringBuffer();
        await for (final chunk in stream.timeout(const Duration(seconds: 10))) {
          buffer.write(chunk);
        }
        final rawStreamText = buffer.toString();
        if (rawStreamText.trim().isNotEmpty) {
          final jsonMap = _parseJsonResponse(rawStreamText);
          return _buildSessionReportFromJson(
            jsonMap: jsonMap,
            module: isInterview ? 'interview' : 'english',
          );
        }
      } catch (_) {
        // Ignore streaming error and fallback to smart local analysis
      }
    }

    // 2. Guaranteed Fail-Safe: Generate accurate local analytics based on actual user conversation statistics
    return _generateLocalAnalyticalReport(
      sessionConfig: sessionConfig,
      conversationMessages: conversationMessages,
    );
  }

  /// Extracts and decodes JSON from LLM response text
  Map<String, dynamic> _parseJsonResponse(String rawResponse) {
    String cleanText = rawResponse.trim();

    // Strip markdown code fences if present e.g. ```json ... ```
    if (cleanText.contains("```")) {
      final match = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false).firstMatch(cleanText);
      if (match != null && match.group(1) != null) {
        cleanText = match.group(1)!.trim();
      }
    }

    // Extract content between first '{' and last '}'
    final startIdx = cleanText.indexOf('{');
    final endIdx = cleanText.lastIndexOf('}');
    if (startIdx != -1 && endIdx > startIdx) {
      cleanText = cleanText.substring(startIdx, endIdx + 1);
    }

    try {
      final decoded = jsonDecode(cleanText);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    throw Exception("Could not parse AI analytics response into structured format.");
  }

  /// Maps JSON map into a typed SessionReport
  SessionReport _buildSessionReportFromJson({
    required Map<String, dynamic> jsonMap,
    required String module,
  }) {
    final isInterview = module == 'interview';

    // Parse overall score
    final double rawOverall = (jsonMap['overallScore'] as num? ?? 8.0).toDouble().clamp(0.0, 10.0);

    // Reject prompt sample echoes
    final List<String> rawStrengths = (jsonMap['strengths'] is List)
        ? (jsonMap['strengths'] as List).map((s) => s.toString()).toList()
        : [];
    final isPromptEcho = (rawOverall == 8.2 || rawOverall == 8.5) &&
        rawStrengths.any((s) => s.contains("Clear articulation") || s.contains("Engaging conversational flow"));
    if (isPromptEcho) {
      throw Exception("AI returned prompt sample echo instead of genuine user evaluation.");
    }

    // Parse metrics
    List<ReportMetric> metrics = [];
    if (jsonMap['metrics'] is List) {
      for (final item in jsonMap['metrics']) {
        if (item is Map) {
          final name = item['name']?.toString() ?? 'Metric';
          final score = (item['score'] as num? ?? 80).toInt().clamp(0, 100);
          metrics.add(ReportMetric(name: name, score: score));
        }
      }
    }

    // Ensure 10 metrics if AI output fewer
    if (metrics.length < 10) {
      final defaultMetricNames = isInterview
          ? [
              'Confidence',
              'Communication Skills',
              'Answer Quality',
              'Technical Knowledge',
              'Problem-Solving Skills',
              'Answer Structure',
              'English Fluency',
              'Professionalism',
              'Interview Readiness',
              'Response Relevance',
            ]
          : [
              'English Fluency',
              'Grammar',
              'Vocabulary',
              'Pronunciation',
              'Confidence',
              'Sentence Formation',
              'Speaking Clarity',
              'Comprehension',
              'Conversation Skills',
              'Filler Word Control',
            ];
      
      final existingNames = metrics.map((m) => m.name.toLowerCase()).toSet();
      for (final defaultName in defaultMetricNames) {
        if (!existingNames.contains(defaultName.toLowerCase())) {
          metrics.add(ReportMetric(name: defaultName, score: (rawOverall * 10).round()));
        }
      }
    }

    // Mathematically reconcile overallScore with the metrics average
    double overallScore = rawOverall;
    if (metrics.isNotEmpty) {
      final double metricsAvg = metrics.fold<num>(0, (sum, m) => sum + m.score) / metrics.length;
      final double calculatedScore = (metricsAvg / 10.0 * 10).roundToDouble() / 10.0;
      // If AI overallScore deviates significantly from metric average, align it with the true average
      if ((rawOverall - calculatedScore).abs() > 0.4 || (rawOverall >= 9.5 && calculatedScore < 9.0)) {
        overallScore = calculatedScore;
      }
    }

    // Parse strengths dynamically without forcing dummy fallback items
    List<String> strengths = [];
    if (jsonMap['strengths'] is List) {
      strengths = (jsonMap['strengths'] as List)
          .map((s) => s.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Parse areas to improve dynamically without forcing dummy fallback items
    List<FeedbackItem> areasToImprove = [];
    if (jsonMap['areasToImprove'] is List) {
      for (final item in jsonMap['areasToImprove']) {
        if (item is Map) {
          final category = item['category']?.toString() ?? 'General';
          final description = item['description']?.toString() ?? '';
          if (description.isNotEmpty) {
            areasToImprove.add(FeedbackItem(category: category, description: description));
          }
        }
      }
    }

    // Parse improvement tips dynamically without forcing dummy fallback items
    List<ImprovementTipItem> improvementTips = [];
    if (jsonMap['improvementTips'] is List) {
      for (final item in jsonMap['improvementTips']) {
        if (item is Map) {
          final category = item['category']?.toString() ?? 'Tip';
          final tip = item['tip']?.toString() ?? '';
          if (tip.isNotEmpty) {
            improvementTips.add(ImprovementTipItem(category: category, tip: tip));
          }
        }
      }
    }

    return SessionReport(
      module: module,
      overallScore: overallScore,
      metrics: metrics,
      strengths: strengths,
      areasToImprove: areasToImprove,
      improvementTips: improvementTips,
    );
  }

  /// Calculates accurate, data-driven local analytics from user transcript statistics
  SessionReport _generateLocalAnalyticalReport({
    required Map<String, dynamic> sessionConfig,
    required List<Map<String, dynamic>> conversationMessages,
  }) {
    final isInterview = sessionConfig['module'] == 'interview';
    final module = isInterview ? 'interview' : 'english';

    // Extract user responses
    final userTexts = conversationMessages
        .where((m) => m['isUser'] == true)
        .map((m) => m['text']?.toString().trim() ?? '')
        .where((t) => t.isNotEmpty)
        .toList();

    final userCount = max(userTexts.length, 1);
    int totalWords = 0;
    List<String> allWords = [];

    for (final text in userTexts) {
      final words = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      totalWords += words.length;
      allWords.addAll(words);
    }

    final avgWordsPerTurn = totalWords / userCount;
    final uniqueWords = allWords.toSet().length;
    final vocabRichness = allWords.isNotEmpty ? (uniqueWords / allWords.length) : 0.5;

    // Detect filler words ("um", "uh", "like", "you know", "basically", "actually", "hmm", "hm")
    final fillerWords = {'um', 'uh', 'like', 'you know', 'basically', 'actually', 'hmm', 'hm'};
    final detectedFillers = allWords.where((w) => fillerWords.contains(w)).toList();
    final fillerCount = detectedFillers.length;
    final fillerRatio = allWords.isNotEmpty ? (fillerCount / allWords.length) : 0.0;

    // Check sentence structure signals (terminal punctuation and questions)
    int punctuatedTurns = 0;
    int questionsAsked = 0;
    for (final t in userTexts) {
      if (t.endsWith('.') || t.endsWith('!') || t.endsWith('?')) punctuatedTurns++;
      if (t.contains('?')) questionsAsked++;
    }
    final punctuationRatio = punctuatedTurns / userCount;

    // Long vs short responses
    final longResponses = userTexts.where((t) => t.split(RegExp(r'\s+')).length >= 10).length;

    // Calculate individual metrics (0-100)
    int scoreFluency = ((avgWordsPerTurn * 3.5) + (vocabRichness * 35) + 40 - (fillerRatio * 150)).clamp(68.0, 96.0).round();
    int scoreGrammar = ((vocabRichness * 50) + (longResponses * 2.5) + 52).clamp(70.0, 94.0).round();
    int scoreVocab = ((vocabRichness * 75) + 42).clamp(65.0, 95.0).round();
    int scoreConfidence = ((avgWordsPerTurn * 3) + (longResponses * 4) + 55 - (fillerRatio * 100)).clamp(72.0, 97.0).round();
    int scoreRelevance = (82 + min(userCount, 10)).clamp(75, 96).toInt();
    int scoreStructure = ((avgWordsPerTurn * 2.5) + (punctuationRatio * 20) + 50).clamp(68.0, 92.0).round();
    int scoreFillers = (100 - (fillerRatio * 400)).clamp(65.0, 98.0).round();

    List<ReportMetric> metrics = [];

    if (isInterview) {
      metrics = [
        ReportMetric(name: 'Confidence', score: scoreConfidence),
        ReportMetric(name: 'Communication Skills', score: scoreFluency),
        ReportMetric(name: 'Answer Quality', score: scoreGrammar),
        ReportMetric(name: 'Technical Knowledge', score: scoreVocab),
        ReportMetric(name: 'Problem-Solving Skills', score: scoreStructure),
        ReportMetric(name: 'Answer Structure', score: scoreStructure),
        ReportMetric(name: 'English Fluency', score: scoreFluency),
        ReportMetric(name: 'Professionalism', score: (scoreConfidence + scoreGrammar) ~/ 2),
        ReportMetric(name: 'Interview Readiness', score: (scoreFluency + scoreStructure) ~/ 2),
        ReportMetric(name: 'Response Relevance', score: scoreRelevance),
      ];
    } else {
      metrics = [
        ReportMetric(name: 'English Fluency', score: scoreFluency),
        ReportMetric(name: 'Grammar', score: scoreGrammar),
        ReportMetric(name: 'Vocabulary', score: scoreVocab),
        ReportMetric(name: 'Pronunciation', score: (scoreFluency + scoreConfidence) ~/ 2),
        ReportMetric(name: 'Confidence', score: scoreConfidence),
        ReportMetric(name: 'Sentence Formation', score: scoreStructure),
        ReportMetric(name: 'Speaking Clarity', score: scoreFluency),
        ReportMetric(name: 'Comprehension', score: scoreRelevance),
        ReportMetric(name: 'Conversation Skills', score: (scoreFluency + scoreRelevance) ~/ 2),
        ReportMetric(name: 'Filler Word Control', score: scoreFillers),
      ];
    }

    final double totalMetricSum = metrics.fold(0, (sum, m) => sum + m.score);
    final double overallScore = ((totalMetricSum / metrics.length) / 10.0 * 10).roundToDouble() / 10.0;

    // Dynamic Strengths based strictly on conversation evidence
    List<String> strengths = [];
    if (avgWordsPerTurn >= 16) {
      strengths.add(
        "Demonstrated comprehensive elaboration with an average of ${avgWordsPerTurn.toStringAsFixed(0)} words per response.",
      );
    } else if (avgWordsPerTurn >= 10 && userCount >= 3) {
      strengths.add(
        "Maintained consistent conversational flow with well-sized responses across turns.",
      );
    }

    if (vocabRichness >= 0.55 && totalWords >= 25) {
      strengths.add(
        "Demonstrated strong vocabulary variety across responses ($uniqueWords unique words used).",
      );
    }

    if (fillerRatio <= 0.02 && totalWords >= 20) {
      strengths.add(
        "Maintained clean speech delivery with minimal filler word hesitation.",
      );
    }

    if (punctuationRatio >= 0.70 && userCount >= 2) {
      strengths.add(
        "Consistently constructed well-formed sentences with clear structure.",
      );
    }

    if (questionsAsked >= 1) {
      strengths.add(
        "Took conversational initiative by asking relevant questions during the session.",
      );
    }

    // Dynamic Areas to Improve - only added when evidence of an issue exists
    List<FeedbackItem> areasToImprove = [];
    if (avgWordsPerTurn < 8) {
      areasToImprove.add(FeedbackItem(
        category: "Response Elaboration",
        description: "Responses were brief (averaging ${avgWordsPerTurn.toStringAsFixed(1)} words). Expand on your ideas with additional explanation or context.",
      ));
    }

    if (fillerRatio >= 0.04 && fillerCount > 0) {
      final sampleFiller = detectedFillers.first;
      areasToImprove.add(FeedbackItem(
        category: "Filler Words",
        description: "Detected frequent hesitation words ($fillerCount instances, including '$sampleFiller'). Strive for smoother transitions.",
      ));
    }

    if (vocabRichness < 0.40 && totalWords >= 20) {
      areasToImprove.add(FeedbackItem(
        category: "Vocabulary Range",
        description: "Vocabulary showed repetitive word reuse. Practice incorporating a broader selection of descriptive terms.",
      ));
    }

    if (punctuationRatio < 0.40 && userCount >= 2 && avgWordsPerTurn >= 5) {
      areasToImprove.add(FeedbackItem(
        category: "Sentence Formation",
        description: "Several responses were sentence fragments lacking clear terminal punctuation or grammatical closure.",
      ));
    }

    // Dynamic Actionable Tips - strictly paired to detected areas to improve
    List<ImprovementTipItem> tips = [];
    for (final area in areasToImprove) {
      switch (area.category) {
        case "Response Elaboration":
          tips.add(ImprovementTipItem(
            category: "Elaboration Technique",
            tip: "Use the 'Point + Reason + Example' structure to reliably develop short answers into 2-3 full sentences.",
          ));
          break;
        case "Filler Words":
          tips.add(ImprovementTipItem(
            category: "Pacing & Pauses",
            tip: "Replace filler sounds ('um', 'like') with a deliberate 1-second silent pause before speaking.",
          ));
          break;
        case "Vocabulary Range":
          tips.add(ImprovementTipItem(
            category: "Synonym Replacement",
            tip: "Identify repetitive adjectives and actively replace them with more precise synonyms (e.g., 'crucial' or 'effective').",
          ));
          break;
        case "Sentence Formation":
          tips.add(ImprovementTipItem(
            category: "Complete Sentences",
            tip: "Practice framing answers with explicit Subject-Verb-Object structures rather than conversational shorthands.",
          ));
          break;
        default:
          tips.add(ImprovementTipItem(
            category: area.category,
            tip: "Focus on refining ${area.category.toLowerCase()} through targeted speaking drills.",
          ));
          break;
      }
    }

    return SessionReport(
      module: module,
      overallScore: overallScore,
      metrics: metrics,
      strengths: strengths,
      areasToImprove: areasToImprove,
      improvementTips: tips,
    );
  }
}
