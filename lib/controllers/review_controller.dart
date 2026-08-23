import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../models/session_report.dart';
import '../routes/app_routes.dart';
import '../services/api/review_analytics_service.dart';
import '../services/database/database_helper.dart';
import '../services/database/tables/review_report_table.dart';

export '../models/session_report.dart';

class ReviewController extends GetxController {
  final ReviewAnalyticsService _analyticsService = ReviewAnalyticsService();

  var sessionConfig = <String, dynamic>{}.obs;
  var report = Rxn<SessionReport>();
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  void loadInitialData() {
    _loadReportData();
  }

  Future<void> retryLoadReport() async {
    await _loadReportData();
  }

  Future<void> _loadReportData() async {
    isLoading.value = true;
    errorMessage.value = '';

    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      sessionConfig.value = Map<String, dynamic>.from(Get.arguments as Map<String, dynamic>);
    }

    // Auto-fallback: if sessionConfig is empty, load most recent active session from database
    if (sessionConfig.isEmpty) {
      try {
        final recentSessions = await DatabaseHelper.instance.getAllChatSessions();
        if (recentSessions.isNotEmpty) {
          final latestSession = recentSessions.first; // SQLite order DESC
          final savedConfigModel = await DatabaseHelper.instance.getSessionConfig(latestSession.sessionId);
          if (savedConfigModel != null) {
            sessionConfig.value = savedConfigModel.toSessionConfigMap();
          } else {
            sessionConfig.value = {
              'sessionId': latestSession.sessionId,
              'module': latestSession.module,
            };
          }
        }
      } catch (_) {}
    }

    final sessionId = sessionConfig['sessionId']?.toString() ?? '';
    final module = sessionConfig['module']?.toString() ?? 'interview';

    // Collect complete conversation history (all user and AI messages)
    List<Map<String, dynamic>> conversationMessages = [];

    if (sessionConfig['messages'] is List && (sessionConfig['messages'] as List).isNotEmpty) {
      for (final item in (sessionConfig['messages'] as List)) {
        if (item is Map) {
          conversationMessages.add({
            'text': item['text']?.toString() ?? '',
            'isUser': item['isUser'] == true,
          });
        }
      }
    }

    // If messages list not passed in arguments, retrieve from SQLite database
    if (conversationMessages.isEmpty && sessionId.isNotEmpty) {
      final dbMessages = await DatabaseHelper.instance.getChatMessages(sessionId);
      conversationMessages = dbMessages
          .map((m) => {
                'text': m.text,
                'isUser': m.isUser,
              })
          .toList();
    }

    // Check if report was already saved in SQLite database (only if new messages were not passed)
    final hasNewMessagesPassed = sessionConfig['messages'] is List && (sessionConfig['messages'] as List).isNotEmpty;
    if (!hasNewMessagesPassed && sessionId.isNotEmpty) {
      final savedReportModel = await DatabaseHelper.instance.getSessionReport(sessionId);
      if (savedReportModel != null) {
        final cached = savedReportModel.toSessionReport();
        final isEcho = (cached.overallScore == 8.2 || cached.overallScore == 8.5) &&
            cached.strengths.any((s) => s.contains("Clear articulation") || s.contains("Engaging conversational flow"));
        if (!isEcho) {
          report.value = cached;
          isLoading.value = false;
          return;
        }
      }
    }

    // Enforce 5+ chat messages requirement
    if (!_analyticsService.canGenerateReview(conversationMessages.length)) {
      errorMessage.value =
          "A user can request a session review only after completing at least 5 chat messages.\n"
          "Current session messages: ${conversationMessages.length}/5.";
      isLoading.value = false;
      return;
    }

    // Generate dynamic review via Groq AI / Smart Local Analytics system
    try {
      final generatedReport = await _analyticsService.generateReview(
        sessionConfig: sessionConfig,
        conversationMessages: conversationMessages,
      );

      report.value = generatedReport;
      isLoading.value = false;

      // Save generated report to SQLite DB asynchronously
      if (sessionId.isNotEmpty) {
        final model = SessionReportModel(
          sessionId: sessionId,
          module: module,
          overallScore: generatedReport.overallScore,
          metrics: generatedReport.metrics,
          strengths: generatedReport.strengths,
          areasToImprove: generatedReport.areasToImprove,
          improvementTips: generatedReport.improvementTips,
        );
        DatabaseHelper.instance.saveSessionReport(model).catchError((_) {});
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll("Exception: ", "");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> shareReport() async {
    final r = report.value;
    if (r == null) {
      Get.snackbar(
        'Review Not Ready',
        'Please wait until the review report finishes generating.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final isInterview = r.module.toLowerCase() == 'interview';
    final moduleTitle = isInterview ? 'Mock Interview' : 'English Conversation';

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('  PROFESSIONAL COMMUNICATION SIMULATOR  ');
    buffer.writeln('      PERFORMANCE REVIEW REPORT         ');
    buffer.writeln('========================================\n');
    buffer.writeln('Module: $moduleTitle');
    buffer.writeln('Overall Performance Score: ${r.overallScore.toStringAsFixed(1)} / 10.0\n');

    buffer.writeln('--- ASSESSMENT METRICS ---');
    for (final m in r.metrics) {
      buffer.writeln('• ${m.name}: ${m.score}/10');
    }
    buffer.writeln('');

    if (r.strengths.isNotEmpty) {
      buffer.writeln('--- KEY STRENGTHS ---');
      for (final s in r.strengths) {
        buffer.writeln('✓ $s');
      }
      buffer.writeln('');
    }

    if (r.areasToImprove.isNotEmpty) {
      buffer.writeln('--- AREAS TO IMPROVE ---');
      for (final a in r.areasToImprove) {
        buffer.writeln('• [${a.category}] ${a.description}');
      }
      buffer.writeln('');
    }

    if (r.improvementTips.isNotEmpty) {
      buffer.writeln('--- ACTIONABLE TIPS ---');
      for (final t in r.improvementTips) {
        buffer.writeln('★ [${t.category}] ${t.tip}');
      }
      buffer.writeln('');
    }

    buffer.writeln('Generated with Professional Communication Simulator AI.');

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: buffer.toString(),
          subject: 'PCS Performance Review - $moduleTitle (${r.overallScore.toStringAsFixed(1)}/10)',
        ),
      );
    } catch (e) {
      // Fallback: Copy to clipboard if system share fails
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      Get.snackbar(
        'Copied to Clipboard',
        'Review report copied to clipboard successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void newChat() {
    Get.offAllNamed(AppRoutes.sessionSelection);
  }

  void resumeChat() {
    if (Get.previousRoute == AppRoutes.chat && (Get.key.currentState?.canPop() ?? false)) {
      Get.back();
      return;
    }

    final sessionId = sessionConfig['sessionId']?.toString() ?? '';
    final module = sessionConfig['module']?.toString() ?? 'interview';

    Map<String, dynamic> chatArgs = Map<String, dynamic>.from(sessionConfig);
    chatArgs['sessionId'] = sessionId;
    chatArgs['module'] = module;
    chatArgs['isRestoredSession'] = true;

    Get.offNamed(AppRoutes.chat, arguments: chatArgs);
  }

  void restartPractice() {
    Get.offAllNamed(AppRoutes.sessionSelection);
  }

  void goHome() {
    Get.offAllNamed(AppRoutes.sessionSelection);
  }
}
