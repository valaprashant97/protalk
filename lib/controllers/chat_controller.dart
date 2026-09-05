import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/utils/prompting.dart';
import '../models/chat_message.dart';
import '../routes/app_routes.dart';
import '../services/api/groq_service.dart';
import '../services/database/database_helper.dart';
import '../services/database/tables/chat_history_table.dart';
import '../services/listen/audio_recorder_service.dart';
import '../services/listen/groq_whisper_service.dart';
import '../services/voice/text_to_speech.dart';

export '../models/chat_message.dart';

class ChatController extends GetxController with WidgetsBindingObserver {
  // GroqService object
  final GroqService _groqService = GroqService();

  // STT services
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  final GroqWhisperService _groqWhisper = GroqWhisperService();

  // Live speech variable
  RxString liveSpeech = "".obs;

  final ScrollController scrollController = ScrollController();

  var currentState = VoiceState.idle.obs;
  var currentModule = "Interview Preparation".obs;
  var selectedSessionId = "1".obs;

  // Conversation Mode (false = Manual, true = Auto Conversation)
  var isAutoMode = false.obs;
  var isAutoPaused = false.obs;

  // Concurrency guard flags to prevent duplicate listeners or duplicate message processing
  bool _isStartingListening = false;
  bool _isStoppingListening = false;

  var messages = <ChatMessage>[].obs;
  var sessionConfig = <String, dynamic>{}.obs;

  var recentSessions = <RecentHistory>[].obs;

  /// Currently active speaking message (if any)
  final Rxn<ChatMessage> speakingMessage = Rxn<ChatMessage>();

  /// Checks if a given chat message is currently being spoken
  bool isMessageSpeaking(ChatMessage message) {
    return speakingMessage.value == message && TextToSpeechService.instance.isSpeaking.value;
  }

  /// Main title for AppBar ("Interview" or "English Conversation")
  String get appBarTitle {
    if (sessionConfig.containsKey('module')) {
      return sessionConfig['module'] == 'english' ? "English Conversation" : "Interview Preparation";
    }
    return currentModule.value.contains("English") ? "English Conversation" : "Interview Preparation";
  }

  /// List of all selected modules/configurations for the current session
  List<String> get selectedModulesList {
    final List<String> items = [];
    if (sessionConfig.isEmpty) return items;

    final isInterview = sessionConfig['module'] == 'interview';
    if (isInterview) {
      if (sessionConfig['course'] != null && sessionConfig['course'].toString().trim().isNotEmpty) {
        items.add(sessionConfig['course'].toString().trim());
      }
      if (sessionConfig['interviewType'] != null && sessionConfig['interviewType'].toString().trim().isNotEmpty) {
        items.add(sessionConfig['interviewType'].toString().trim());
      }
      if (sessionConfig['jobRole'] != null && sessionConfig['jobRole'].toString().trim().isNotEmpty) {
        items.add(sessionConfig['jobRole'].toString().trim());
      }
      if (sessionConfig['skills'] != null && sessionConfig['skills'] is List && (sessionConfig['skills'] as List).isNotEmpty) {
        final skillsList = List<String>.from(sessionConfig['skills']);
        items.add(skillsList.join(', '));
      }
      if (sessionConfig['company'] != null && sessionConfig['company'].toString().trim().isNotEmpty) {
        items.add(sessionConfig['company'].toString().trim());
      }
      if (sessionConfig['difficulty'] != null && sessionConfig['difficulty'].toString().trim().isNotEmpty) {
        items.add(sessionConfig['difficulty'].toString().trim());
      }
    } else {
      if (sessionConfig['englishTopic'] != null && sessionConfig['englishTopic'].toString().trim().isNotEmpty) {
        items.add(sessionConfig['englishTopic'].toString().trim());
      }
      if (sessionConfig['aiPersonality'] != null && sessionConfig['aiPersonality'].toString().trim().isNotEmpty) {
        items.add(sessionConfig['aiPersonality'].toString().trim());
      }
      if (sessionConfig['language'] != null && sessionConfig['language'].toString().trim().isNotEmpty) {
        items.add(sessionConfig['language'].toString().trim());
      }
      if (sessionConfig['correctionMode'] != null && sessionConfig['correctionMode'].toString().trim().isNotEmpty) {
        items.add(sessionConfig['correctionMode'].toString().trim());
      }
      if (sessionConfig['conversationStyle'] != null && sessionConfig['conversationStyle'].toString().trim().isNotEmpty) {
        items.add(sessionConfig['conversationStyle'].toString().trim());
      }
      if (sessionConfig['responseStyle'] != null && sessionConfig['responseStyle'].toString().trim().isNotEmpty) {
        items.add(sessionConfig['responseStyle'].toString().trim());
      }
      if (sessionConfig['difficulty'] != null && sessionConfig['difficulty'].toString().trim().isNotEmpty) {
        items.add(sessionConfig['difficulty'].toString().trim());
      }
    }
    return items;
  }

  /// Formatted subtitle showing all selected modules separated by bullet points
  String get appBarSubtitle {
    return selectedModulesList.join(' • ');
  }

  bool _isAppMinimized = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadRecentSessionsFromDb();

    // Reset speaking message whenever TTS stops speaking
    ever(TextToSpeechService.instance.isSpeaking, (bool speaking) {
      if (!speaking) {
        speakingMessage.value = null;
      }
    });

    // Load arguments from ModuleSelectionScreen or SessionSelectionScreen
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      sessionConfig.value = Get.arguments as Map<String, dynamic>;

      final isInterview = sessionConfig['module'] == 'interview';
      currentModule.value = isInterview
          ? "Interview: ${sessionConfig['jobRole'] ?? 'Software Developer'}"
          : "English Conversation: ${sessionConfig['englishTopic'] ?? 'General'}";

      final bool isRestored = sessionConfig['isRestoredSession'] == true;

      if (isRestored) {
        selectedSessionId.value = sessionConfig['sessionId'] ?? '';
        _restoreMessagesFromDb(selectedSessionId.value);
      } else {
        _initChatSessionInDb();
        _sendInitialGreeting();
      }
    }
  }

  Future<void> _restoreMessagesFromDb(String sessionId) async {
    if (sessionId.isEmpty) return;
    try {
      final dbMessages = await DatabaseHelper.instance.getChatMessages(sessionId);
      if (dbMessages.isNotEmpty) {
        messages.clear();
        for (final m in dbMessages) {
          messages.add(ChatMessage(
            text: m.text,
            isUser: m.isUser,
            timestamp: m.timestamp,
            isGenerating: false,
          ));
        }
        scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _loadRecentSessionsFromDb() async {
    try {
      final dbSessions = await DatabaseHelper.instance.getAllChatSessions();
      recentSessions.value = dbSessions
          .map((s) => RecentHistory(id: s.sessionId, title: s.title, module: s.module))
          .toList();
    } catch (_) {
      recentSessions.clear();
    }
  }

  Future<void> _initChatSessionInDb() async {
    final sessionId = sessionConfig['sessionId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    sessionConfig['sessionId'] = sessionId;
    selectedSessionId.value = sessionId;

    final isInterview = sessionConfig['module'] == 'interview';
    final title = isInterview
        ? (sessionConfig['jobRole'] ?? 'Software Developer Interview')
        : "English: ${sessionConfig['englishTopic'] ?? 'General Conversation'}";

    final sessionModel = ChatSessionModel(
      sessionId: sessionId,
      title: title,
      module: sessionConfig['module'] ?? 'interview',
    );

    await DatabaseHelper.instance.saveChatSession(sessionModel);
    await _loadRecentSessionsFromDb();
  }

  Future<void> _saveMessageToDb(String text, bool isUser) async {
    final sessionId = selectedSessionId.value;
    if (sessionId.isEmpty || text.trim().isEmpty) return;

    final messageModel = ChatMessageModel(
      sessionId: sessionId,
      text: text.trim(),
      isUser: isUser,
      timestamp: DateTime.now(),
    );

    await DatabaseHelper.instance.saveChatMessage(messageModel);
  }

  /// Callback invoked when TTS completes speaking an AI response
  void _onTtsComplete() {
    speakingMessage.value = null;
    if (isAutoMode.value && !isAutoPaused.value) {
      // In Live Auto Mode, immediately start listening for the user's next turn
      startListening();
    } else {
      currentState.value = VoiceState.idle;
    }
  }

  /// Sends initial greeting message using streaming
  Future<void> _sendInitialGreeting() async {
    currentState.value = VoiceState.processing;
    final aiMessage = ChatMessage(text: "", isUser: false, isGenerating: true);
    messages.add(aiMessage);
    scrollToBottom();

    try {
      final prompt = _buildInitialGreetingPrompt();
      var responseText = "";

      final index = messages.indexOf(aiMessage);
      final stream = _groqService.generateStream(prompt);
      await for (final chunk in stream) {
        responseText += chunk;
      }

      if (index != -1 && index < messages.length) {
        final time = messages[index].timestamp;
        final updatedAiMsg = ChatMessage(
          text: responseText,
          isUser: false,
          isGenerating: false,
          timestamp: time,
        );
        messages[index] = updatedAiMsg;
        messages.refresh();
        if (responseText.trim().isNotEmpty) {
          _saveMessageToDb(responseText, false);
          if (!_isAppMinimized) {
            currentState.value = VoiceState.aiSpeaking;
            speakingMessage.value = updatedAiMsg;
            await TextToSpeechService.instance.speak(
              responseText,
              onComplete: _onTtsComplete,
            );
          } else {
            currentState.value = VoiceState.idle;
          }
        } else {
          _onTtsComplete();
        }
      }

      scrollToBottom();
    } catch (e) {
      messages.remove(aiMessage);
      currentState.value = VoiceState.idle;
    }
  }

  /// Format initial greeting prompt
  String _buildInitialGreetingPrompt() {
    final isInterview = sessionConfig['module'] == 'interview';
    return Prompting.buildInitialGreetingPrompt(
      isInterview: isInterview,
      localTime: DateTime.now(),
      course: sessionConfig['course'],
      interviewType: sessionConfig['interviewType'],
      jobRole: sessionConfig['jobRole'],
      skills: sessionConfig['skills'] != null ? List<String>.from(sessionConfig['skills']) : null,
      company: sessionConfig['company'],
      difficulty: sessionConfig['difficulty'],
      englishTopic: sessionConfig['englishTopic'],
      aiPersonality: sessionConfig['aiPersonality'],
      language: sessionConfig['language'],
      correctionMode: sessionConfig['correctionMode'],
      conversationStyle: sessionConfig['conversationStyle'],
      responseStyle: sessionConfig['responseStyle'],
      experienceLevel: sessionConfig['experienceLevel'],
      educationBackground: sessionConfig['educationBackground'] ?? sessionConfig['course'],
      projectDetails: sessionConfig['projectDetails'],
      companyType: sessionConfig['companyType'],
      goal: sessionConfig['goal'],
    );
  }

  /// Builds prompt using conversation history
  String _buildAiPrompt() {
    final isInterview = sessionConfig['module'] == 'interview';
    final difficulty = sessionConfig['difficulty'] ?? 'Beginner';
    return Prompting.buildChatPrompt(
      isInterview: isInterview,
      difficulty: difficulty,
      messages: messages,
      localTime: DateTime.now(),
      course: sessionConfig['course'],
      interviewType: sessionConfig['interviewType'],
      jobRole: sessionConfig['jobRole'],
      skills: sessionConfig['skills'] != null ? List<String>.from(sessionConfig['skills']) : null,
      company: sessionConfig['company'],
      englishTopic: sessionConfig['englishTopic'],
      aiPersonality: sessionConfig['aiPersonality'],
      language: sessionConfig['language'],
      correctionMode: sessionConfig['correctionMode'],
      conversationStyle: sessionConfig['conversationStyle'],
      responseStyle: sessionConfig['responseStyle'],
      experienceLevel: sessionConfig['experienceLevel'],
      educationBackground: sessionConfig['educationBackground'] ?? sessionConfig['course'],
      projectDetails: sessionConfig['projectDetails'],
      companyType: sessionConfig['companyType'],
      goal: sessionConfig['goal'],
    );
  }

  // Start recording audio via microphone
  Future<void> startListening() async {
    if (_isAppMinimized) return;
    if (_isStartingListening) return;
    _isStartingListening = true;

    try {
      await TextToSpeechService.instance.stop();
      liveSpeech.value = "";
      currentState.value = VoiceState.listening;

      final permitted = await _audioRecorder.hasPermission();
      if (!permitted) {
        currentState.value = VoiceState.idle;
        return;
      }

      // In Live Auto Mode, register silence detection callback (1.8s silence after speech auto-stops)
      final path = await _audioRecorder.startRecording(
        onSilenceDetected: isAutoMode.value && !isAutoPaused.value
            ? () {
                if (currentState.value == VoiceState.listening && !_isStoppingListening) {
                  stopListening();
                }
              }
            : null,
      );

      if (path == null) {
        currentState.value = VoiceState.idle;
      }
    } catch (_) {
      currentState.value = VoiceState.idle;
    } finally {
      _isStartingListening = false;
    }
  }

  /// Checks whether a transcribed string represents actual meaningful user speech,
  /// filtering out Whisper silence hallucinations (like '.', 'I', 'Thank you.', '...', etc.)
  bool _isMeaningfulSpeech(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return false;

    // Remove punctuation to inspect actual words/letters
    final wordsOnly = clean
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF\u0A80-\u0AFF\u0900-\u097F]'), '')
        .trim();
    if (wordsOnly.isEmpty) return false; // Pure punctuation like '.', '...', '?'

    // Filter single-character noise tokens like 'I', 'a', 'm' from silence audio
    if (wordsOnly.length <= 1) return false;

    // Filter known Whisper silence hallucinations
    final lower = wordsOnly.toLowerCase();
    const hallucinations = {
      'thank you',
      'thanks for watching',
      'subtitles',
      'subtitles by',
      'amaraorg',
      'subscribe',
      'you',
      'bye',
      'uh',
      'um',
      'mm',
      'hmm',
    };

    if (hallucinations.contains(lower)) return false;

    return true;
  }

  // Stop recording and transcribe via Groq Whisper
  Future<void> stopListening() async {
    if (_isStoppingListening) return;
    _isStoppingListening = true;

    try {
      final audioPath = await _audioRecorder.stopRecording();

      if (audioPath == null || audioPath.isEmpty) {
        liveSpeech.value = "";
        if (isAutoMode.value && !isAutoPaused.value) {
          startListening();
        } else {
          currentState.value = VoiceState.idle;
        }
        return;
      }

      // Show transcribing state
      currentState.value = VoiceState.processing;
      liveSpeech.value = "Transcribing...";

      try {
        final transcription = await _groqWhisper.transcribe(audioPath);
        liveSpeech.value = transcription;

        if (_isMeaningfulSpeech(transcription)) {
          sendUserMessage(transcription.trim());
        } else {
          // Ignored noise / hallucination / empty speech -> resume listening seamlessly
          liveSpeech.value = "";
          if (isAutoMode.value && !isAutoPaused.value) {
            startListening();
          } else {
            currentState.value = VoiceState.idle;
          }
        }
      } catch (e) {
        liveSpeech.value = "";

        if (isAutoMode.value && !isAutoPaused.value) {
          Future.delayed(const Duration(seconds: 2), () {
            if (isAutoMode.value && !isAutoPaused.value && currentState.value == VoiceState.idle) {
              startListening();
            }
          });
        } else {
          currentState.value = VoiceState.idle;
        }
      }
    } finally {
      _isStoppingListening = false;
    }
  }

  /// Send user message and stream AI response
  Future<void> sendUserMessage(String value) async {
    messages.add(ChatMessage(text: value, isUser: true));
    _saveMessageToDb(value, true);
    liveSpeech.value = "";
    currentState.value = VoiceState.processing;
    scrollToBottom();

    // Prepare stream response placeholder with isGenerating = true
    final aiMessage = ChatMessage(text: "", isUser: false, isGenerating: true);
    messages.add(aiMessage);
    scrollToBottom();

    try {
      final prompt = _buildAiPrompt();
      var responseText = "";

      final index = messages.indexOf(aiMessage);
      final stream = _groqService.generateStream(prompt);
      await for (final chunk in stream) {
        responseText += chunk;
      }

      // Complete response received: remove loading indicator and reveal full AI message
      if (index != -1 && index < messages.length) {
        final time = messages[index].timestamp;
        final updatedAiMsg = ChatMessage(
          text: responseText,
          isUser: false,
          isGenerating: false,
          timestamp: time,
        );
        messages[index] = updatedAiMsg;
        messages.refresh();
        if (responseText.trim().isNotEmpty) {
          _saveMessageToDb(responseText, false);
          if (!_isAppMinimized) {
            currentState.value = VoiceState.aiSpeaking;
            speakingMessage.value = updatedAiMsg;
            await TextToSpeechService.instance.speak(
              responseText,
              onComplete: _onTtsComplete,
            );
          } else {
            currentState.value = VoiceState.idle;
          }
        } else {
          _onTtsComplete();
        }
      }

      scrollToBottom();
    } catch (e) {
      // Remove the empty placeholder message on error
      messages.remove(aiMessage);
      currentState.value = VoiceState.idle;

      if (isAutoMode.value && !isAutoPaused.value) {
        Future.delayed(const Duration(seconds: 3), () {
          if (isAutoMode.value && !isAutoPaused.value && currentState.value == VoiceState.idle) {
            startListening();
          }
        });
      }
    }
  }

  /// Speaks an AI message using centralized TTS service, or toggles playback off if already speaking
  Future<void> replayAiMessage(ChatMessage message) async {
    if (_isAppMinimized || message.text.trim().isEmpty) return;

    if (speakingMessage.value == message && TextToSpeechService.instance.isSpeaking.value) {
      await TextToSpeechService.instance.stop();
      speakingMessage.value = null;
      if (currentState.value == VoiceState.aiSpeaking) {
        currentState.value = VoiceState.idle;
      }
      return;
    }

    speakingMessage.value = message;
    currentState.value = VoiceState.aiSpeaking;
    await TextToSpeechService.instance.speak(
      message.text,
      onComplete: () {
        if (speakingMessage.value == message) {
          speakingMessage.value = null;
        }
        _onTtsComplete();
      },
    );
  }

  /// Replays raw text using centralized TTS service (legacy compatibility)
  Future<void> replayAiMessageText(String text) async {
    if (text.trim().isEmpty) return;
    await TextToSpeechService.instance.speak(text);
  }

  /// Deletes target message and all subsequent messages, updates DB, and enters mic listening mode
  Future<void> deleteMessageAndSubsequent(ChatMessage targetMessage) async {
    final index = messages.indexOf(targetMessage);
    if (index == -1) return;

    // Stop active TTS audio speaking if any
    await TextToSpeechService.instance.stop();
    speakingMessage.value = null;

    // Cancel current active recording if listening
    if (currentState.value == VoiceState.listening) {
      await _audioRecorder.cancelRecording();
    }

    // Remove target message and all messages after it
    messages.removeRange(index, messages.length);
    messages.refresh();

    // Sync remaining messages with SQLite database for session
    final sessionId = selectedSessionId.value;
    if (sessionId.isNotEmpty) {
      final remainingModels = messages
          .map((m) => ChatMessageModel(
                sessionId: sessionId,
                text: m.text,
                isUser: m.isUser,
                timestamp: m.timestamp,
              ))
          .toList();
      await DatabaseHelper.instance.syncChatMessages(sessionId, remainingModels);
    }

    // Reset live speech buffer and trigger mic listening mode
    liveSpeech.value = "";
    startListening();
  }

  /// Triggers user voice input (legacy compatibility)
  Future<void> speakAgainUserMessage() async {
    startListening();
  }

  /// Send AI message (standard fallback)
  void sendAiMessage(String value) {
    final aiMsg = ChatMessage(text: value, isUser: false);
    messages.add(aiMsg);
    _saveMessageToDb(value, false);
    liveSpeech.value = "";
    scrollToBottom();
    if (value.trim().isNotEmpty) {
      currentState.value = VoiceState.aiSpeaking;
      speakingMessage.value = aiMsg;
      TextToSpeechService.instance.speak(value, onComplete: _onTtsComplete);
    } else {
      _onTtsComplete();
    }
  }

  void onMicTap() {
    if (isAutoMode.value) {
      if (currentState.value == VoiceState.idle) {
        // In Auto Mode, tapping the mic starts listening
        startListening();
      } else {
        // Tapping the mic while Auto Mode is active stops Auto Mode and returns to normal Live Mode
        stopAutoModeToManual();
      }
    } else {
      // Manual Live Mode
      if (currentState.value == VoiceState.idle) {
        startListening();
      } else if (currentState.value == VoiceState.listening) {
        stopListening();
      } else if (currentState.value == VoiceState.aiSpeaking) {
        TextToSpeechService.instance.stop();
        currentState.value = VoiceState.idle;
      }
    }
  }

  /// Stops Auto Mode and cleanly returns to normal Manual Live Mode
  Future<void> stopAutoModeToManual() async {
    isAutoMode.value = false;
    isAutoPaused.value = false;
    await TextToSpeechService.instance.stop();
    await _audioRecorder.cancelRecording();
    liveSpeech.value = "";
    currentState.value = VoiceState.idle;
  }

  /// Toggle mode between Manual & Auto Conversation by holding mic for 3 seconds
  void toggleModeHold3s() {
    if (!isAutoMode.value) {
      // In Manual Mode, holding the mic for 3 seconds switches to Auto Mode
      isAutoMode.value = true;
      isAutoPaused.value = false;
      liveSpeech.value = "";

      if (currentState.value == VoiceState.idle) {
        startListening();
      }
    } else {
      // Holding mic in Auto Mode switches back to Manual Mode
      stopAutoModeToManual();
    }
  }

  void setMode(bool isAuto) {
    if (isAutoMode.value != isAuto) {
      isAutoMode.value = isAuto;
      isAutoPaused.value = false;

      if (isAuto) {
        if (currentState.value == VoiceState.idle) {
          startListening();
        }
      } else {
        if (currentState.value == VoiceState.listening) {
          _audioRecorder.cancelRecording();
          currentState.value = VoiceState.idle;
        }
      }
    }
  }

  void pauseAutoConversation() {
    isAutoPaused.value = true;
    _audioRecorder.cancelRecording();
    TextToSpeechService.instance.stop();
    currentState.value = VoiceState.idle;
  }

  void startAutoConversation() {
    isAutoPaused.value = false;
    isAutoMode.value = true;
    if (currentState.value == VoiceState.idle) {
      startListening();
    }
  }

  void stopAutoConversation() {
    isAutoPaused.value = false;
    isAutoMode.value = false;
    _audioRecorder.cancelRecording();
    TextToSpeechService.instance.stop();
    currentState.value = VoiceState.idle;
    liveSpeech.value = "";
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Immediately stops/cancels ongoing AI speech playback and resets speaking state
  Future<void> stopSpeech() async {
    speakingMessage.value = null;
    if (currentState.value == VoiceState.aiSpeaking) {
      currentState.value = VoiceState.idle;
    }
    try {
      await TextToSpeechService.instance.stop();
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  /// New chat
  void startNewChat() {
    stopSpeech();
    stopListening();
    try {
      _audioRecorder.stopRecording();
    } catch (_) {}
    currentState.value = VoiceState.idle;
    Get.toNamed(AppRoutes.moduleSelection);
  }

  /// Restores session history & messages from SQLite database
  Future<void> loadSession(String id, String title) async {
    // If already in this session, do nothing extra
    if (selectedSessionId.value == id && messages.isNotEmpty) {
      return;
    }

    stopListening();
    try {
      _audioRecorder.stopRecording();
    } catch (_) {}
    try {
      TextToSpeechService.instance.stop();
    } catch (_) {}

    liveSpeech.value = "";
    currentState.value = VoiceState.idle;
    selectedSessionId.value = id;

    // Load session config from SQLite DB
    final savedConfigModel = await DatabaseHelper.instance.getSessionConfig(id);
    if (savedConfigModel != null) {
      sessionConfig.value = savedConfigModel.toSessionConfigMap();
    } else {
      if (title.toLowerCase().contains("english")) {
        sessionConfig.value = {'sessionId': id, 'module': 'english', 'englishTopic': title};
      } else {
        sessionConfig.value = {'sessionId': id, 'module': 'interview', 'jobRole': title};
      }
    }

    final isInterview = sessionConfig['module'] == 'interview';
    currentModule.value = isInterview
        ? "Interview: ${sessionConfig['jobRole'] ?? 'Software Developer'}"
        : "English Conversation: ${sessionConfig['englishTopic'] ?? 'General'}";

    // Load messages from SQLite DB
    final dbMessages = await DatabaseHelper.instance.getChatMessages(id);
    messages.clear();
    if (dbMessages.isNotEmpty) {
      for (final m in dbMessages) {
        messages.add(ChatMessage(
          text: m.text,
          isUser: m.isUser,
          timestamp: m.timestamp,
          isGenerating: false,
        ));
      }
    }

    scrollToBottom();
  }

  /// Whether a session review can be requested (must have completed at least 5 chat messages)
  bool get isReviewAvailable => messages.length >= 5;

  /// Current number of chat messages in this session
  int get messageCount => messages.length;

  /// Requests session review after checking threshold requirement (>= 5 messages)
  void endSession() {
    if (!isReviewAvailable) {
      return;
    }

    final args = Map<String, dynamic>.from(sessionConfig);
    args['messages'] = messages
        .map((m) => {
              'text': m.text,
              'isUser': m.isUser,
              'timestamp': m.timestamp.toIso8601String(),
            })
        .toList();

    Get.toNamed(
      AppRoutes.review,
      arguments: args,
    );
  }

  /// Renames a chat session in database and state
  Future<void> renameSession(String sessionId, String newTitle) async {
    final cleanTitle = newTitle.trim();
    if (cleanTitle.isEmpty) return;

    try {
      await DatabaseHelper.instance.updateChatSessionTitle(sessionId, cleanTitle);

      final index = recentSessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        recentSessions[index] = recentSessions[index].copyWith(title: cleanTitle);
        recentSessions.refresh();
      }

      // If the current active session is being renamed, update active session title
      if (sessionId == selectedSessionId.value) {
        final isInterview = sessionConfig['module'] == 'interview';
        if (isInterview) {
          sessionConfig['jobRole'] = cleanTitle;
          currentModule.value = "Interview: $cleanTitle";
        } else {
          sessionConfig['englishTopic'] = cleanTitle;
          currentModule.value = "English Conversation: $cleanTitle";
        }
        sessionConfig.refresh();
      }
    } catch (e) {
      debugPrint('Error renaming session: $e');
    }
  }

  /// Deletes a chat session from database and state
  Future<void> deleteSession(String sessionId) async {
    try {
      await DatabaseHelper.instance.deleteChatSession(sessionId);
      recentSessions.removeWhere((s) => s.id == sessionId);
      recentSessions.refresh();

      // If the deleted session was the currently active session
      if (sessionId == selectedSessionId.value) {
        // Stop current audio operations
        await TextToSpeechService.instance.stop();
        await _audioRecorder.cancelRecording();
        liveSpeech.value = "";
        currentState.value = VoiceState.idle;

        if (recentSessions.isNotEmpty) {
          final nextSession = recentSessions.first;
          await loadSession(nextSession.id, nextSession.title);
        } else {
          messages.clear();
          Get.offNamed(AppRoutes.moduleSelection);
        }
      }
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _isAppMinimized = true;
      _handleAppMinimized();
    } else if (state == AppLifecycleState.resumed) {
      _isAppMinimized = false;
    }
  }

  /// Stops and cancels ongoing speech and recording when the app is minimized
  void _handleAppMinimized() {
    stopSpeech();
    if (currentState.value == VoiceState.listening) {
      stopListening();
      try {
        _audioRecorder.cancelRecording();
      } catch (_) {}
      liveSpeech.value = "";
      currentState.value = VoiceState.idle;
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    TextToSpeechService.instance.stop();
    speakingMessage.value = null;
    _audioRecorder.dispose();
    scrollController.dispose();
    super.onClose();
  }
}


