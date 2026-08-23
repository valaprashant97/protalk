import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../routes/app_routes.dart';
import '../services/database/database_helper.dart';
import '../services/database/tables/chat_history_table.dart';

class SessionSelectionController extends GetxController {
  final RxList<SessionSummaryModel> recentSessions = <SessionSummaryModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadSessions();
  }

  Future<void> loadSessions() async {
    isLoading.value = true;
    try {
      final sessions = await DatabaseHelper.instance.getAllSessionSummaries();
      recentSessions.value = sessions;
      if (sessions.isEmpty) {
        Get.offNamed(AppRoutes.moduleSelection);
      }
    } catch (_) {
      recentSessions.clear();
      Get.offNamed(AppRoutes.moduleSelection);
    } finally {
      isLoading.value = false;
    }
  }

  void createNewSession() {
    Get.toNamed(AppRoutes.moduleSelection)?.then((_) {
      // Reload sessions when returning back from module selection / chat
      loadSessions();
    });
  }

  Future<void> openRecentSession(SessionSummaryModel session) async {
    try {
      // Fetch saved session configuration
      final configModel = await DatabaseHelper.instance.getSessionConfig(session.sessionId);
      Map<String, dynamic> sessionArgs;

      if (configModel != null) {
        sessionArgs = configModel.toSessionConfigMap();
      } else {
        final isEnglish = session.module.toLowerCase() == 'english' ||
            session.title.toLowerCase().contains('english');
        sessionArgs = {
          'sessionId': session.sessionId,
          'module': isEnglish ? 'english' : 'interview',
          if (isEnglish) 'englishTopic': session.title else 'jobRole': session.title,
        };
      }

      sessionArgs['sessionId'] = session.sessionId;
      sessionArgs['isRestoredSession'] = true;

      if (Get.isRegistered<ChatController>()) {
        Get.delete<ChatController>(force: true);
      }

      Get.toNamed(AppRoutes.chat, arguments: sessionArgs)?.then((_) {
        // Refresh session list on return
        loadSessions();
      });
    } catch (e) {
      debugPrint('Error opening session: $e');
    }
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    final cleanTitle = newTitle.trim();
    if (cleanTitle.isEmpty) return;
    try {
      await DatabaseHelper.instance.updateChatSessionTitle(sessionId, cleanTitle);
      final index = recentSessions.indexWhere((s) => s.sessionId == sessionId);
      if (index != -1) {
        recentSessions[index] = recentSessions[index].copyWith(title: cleanTitle);
        recentSessions.refresh();
      }
    } catch (e) {
      debugPrint('Error renaming session: $e');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await DatabaseHelper.instance.deleteChatSession(sessionId);
      recentSessions.removeWhere((s) => s.sessionId == sessionId);
      if (recentSessions.isEmpty) {
        Get.offNamed(AppRoutes.moduleSelection);
      }
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }
}
