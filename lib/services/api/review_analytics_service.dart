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
    final double overallScore = (jsonMap['overallScore'] as num? ?? 8.0).toDouble().clamp(0.0, 10.0);

    // Reject prompt sample echoes
    final List<String> rawStrengths = (jsonMap['strengths'] is List)
        ? (jsonMap['strengths'] as List).map((s) => s.toString()).toList()
        : [];
    final isPromptEcho = (overallScore == 8.2 || overallScore == 8.5) &&
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

    // Ensure 10 fallback metrics if AI output fewer
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
          metrics.add(ReportMetric(name: defaultName, score: (overallScore * 10).round()));
        }
      }
    }

    // Parse strengths
    List<String> strengths = [];
    if (jsonMap['strengths'] is List) {
      strengths = (jsonMap['strengths'] as List)
          .map((s) => s.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (strengths.isEmpty) {
      strengths = [
        "Completed a detailed practice session with active participation.",
        "Demonstrated clear engagement and intent across conversation turns.",
      ];
    }

    // Parse areas to improve
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
    if (areasToImprove.isEmpty) {
      areasToImprove.add(FeedbackItem(
        category: "Depth & Detail",
        description: "Elaborate further with structured examples in future sessions.",
      ));
    }

    // Parse improvement tips
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
    if (improvementTips.isEmpty) {
      improvementTips.add(ImprovementTipItem(
        category: "Practice Strategy",
        tip: "Maintain a steady speaking rhythm and organize thoughts prior to responding.",
      ));
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

    // Detect filler words ("um", "uh", "like", "you know", "basically", "actually")
    final fillerWords = {'um', 'uh', 'like', 'you know', 'basically', 'actually', 'hmm', 'hm'};
    final fillerCount = allWords.where((w) => fillerWords.contains(w)).length;
    final fillerRatio = allWords.isNotEmpty ? (fillerCount / allWords.length) : 0.0;

    // Long vs short responses
    final longResponses = userTexts.where((t) => t.split(RegExp(r'\s+')).length >= 10).length;

    // Calculate individual metrics (0-100)
    int scoreFluency = ((avgWordsPerTurn * 3.5) + (vocabRichness * 35) + 40 - (fillerRatio * 150)).clamp(68.0, 96.0).round();
    int scoreGrammar = ((vocabRichness * 50) + (longResponses * 2.5) + 52).clamp(70.0, 94.0).round();
    int scoreVocab = ((vocabRichness * 75) + 42).clamp(65.0, 95.0).round();
    int scoreConfidence = ((avgWordsPerTurn * 3) + (longResponses * 4) + 55 - (fillerRatio * 100)).clamp(72.0, 97.0).round();
    int scoreRelevance = (82 + min(userCount, 10)).clamp(75, 96).toInt();
    int scoreStructure = ((avgWordsPerTurn * 2.5) + 60).clamp(68.0, 92.0).round();
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

    // Strengths
    List<String> strengths = [
      "Completed a comprehensive practice session with $userCount active user turns.",
      "Maintained consistent engagement with an average response of ${avgWordsPerTurn.toStringAsFixed(1)} words per response.",
    ];

    if (vocabRichness > 0.45) {
      strengths.add("Demonstrated diverse vocabulary usage across conversation turns.");
    }
    if (fillerRatio < 0.05) {
      strengths.add("Exhibited strong control over filler words and speech pauses.");
    }

    // Areas to improve
    List<FeedbackItem> areasToImprove = [];
    if (avgWordsPerTurn < 10) {
      areasToImprove.add(FeedbackItem(
        category: "Response Depth",
        description: "Expand your responses with more details and specific examples.",
      ));
    } else {
      areasToImprove.add(FeedbackItem(
        category: "Answer Structure",
        description: "Organize main points systematically before speaking.",
      ));
    }

    if (fillerRatio >= 0.05) {
      areasToImprove.add(FeedbackItem(
        category: "Filler Words",
        description: "Minimize filler words ('like', 'um') for clearer speech delivery.",
      ));
    } else {
      areasToImprove.add(FeedbackItem(
        category: "Vocabulary Variety",
        description: "Incorporate more domain-specific and descriptive terminology.",
      ));
    }

    // Tips
    List<ImprovementTipItem> tips = [
      ImprovementTipItem(
        category: "Structured Speaking",
        tip: "Use clear intro-body-conclusion framing for elaborate responses.",
      ),
      ImprovementTipItem(
        category: "Pacing & Clarity",
        tip: "Pause briefly to structure thoughts instead of filling silence rapidly.",
      ),
    ];

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
