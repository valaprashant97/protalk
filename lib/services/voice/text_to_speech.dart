import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'female_voice.dart';
import 'male_voice.dart';

class TextToSpeechService {
  TextToSpeechService._internal();
  static final TextToSpeechService instance = TextToSpeechService._internal();

  final FlutterTts _flutterTts = FlutterTts();

  // Reactive state using GetX
  final RxDouble volume = 1.0.obs;
  final RxDouble speechSpeed = 0.45.obs;
  final RxString voiceGender = 'female'.obs;
  final RxBool isSpeaking = false.obs;
  final RxBool isInitialized = false.obs;
  final RxMap<String, String> activeVoice = <String, String>{}.obs;
  final RxBool isGenderVerified = false.obs;
  final RxString genderStatusLabel = ''.obs;

  final RxList<Map<String, String>> availableVoices = <Map<String, String>>[].obs;

  // SharedPreferences Keys
  static const String _keyVolume = 'voice_volume';
  static const String _keySpeed = 'speech_speed';
  static const String _keyGender = 'voice_gender';
  static const String _keyVoiceName = 'selected_voice_name';
  static const String _keyVoiceLocale = 'selected_voice_locale';

  void Function()? _onSpeechCompleted;

  /// Initializes the TTS engine, loads available device voices, restores persisted settings, and applies parameters.
  Future<void> init() async {
    if (isInitialized.value) return;

    try {
      // Enable awaiting speak completion for reliable completion tracking
      await _flutterTts.awaitSpeakCompletion(true);

      // Setup TTS handlers
      _flutterTts.setStartHandler(() {
        isSpeaking.value = true;
      });

      _flutterTts.setCompletionHandler(() {
        isSpeaking.value = false;
        final callback = _onSpeechCompleted;
        _onSpeechCompleted = null;
        callback?.call();
      });

      _flutterTts.setCancelHandler(() {
        isSpeaking.value = false;
        _onSpeechCompleted = null;
      });

      _flutterTts.setErrorHandler((msg) {
        developer.log('TTS Error: $msg');
        isSpeaking.value = false;
        final callback = _onSpeechCompleted;
        _onSpeechCompleted = null;
        callback?.call();
      });

      // Load device voices safely
      await _loadDeviceVoices();

      // Load saved settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      volume.value = prefs.getDouble(_keyVolume) ?? 1.0;
      speechSpeed.value = prefs.getDouble(_keySpeed) ?? 0.45;
      voiceGender.value = prefs.getString(_keyGender) ?? 'female';

      final savedVoiceName = prefs.getString(_keyVoiceName);
      final savedVoiceLocale = prefs.getString(_keyVoiceLocale);

      // Apply primary language
      await _flutterTts.setLanguage('en-US');

      // Resolve voice
      if (savedVoiceName != null && savedVoiceName.isNotEmpty) {
        final matchingVoice = availableVoices.firstWhere(
          (v) => v['name'] == savedVoiceName && (savedVoiceLocale == null || v['locale'] == savedVoiceLocale),
          orElse: () => <String, String>{},
        );

        if (matchingVoice.isNotEmpty) {
          activeVoice.value = matchingVoice;
          isGenderVerified.value = true;
          genderStatusLabel.value = voiceGender.value == 'female' ? 'Saved Female Voice' : 'Saved Male Voice';
          await _flutterTts.setVoice(matchingVoice);
        } else {
          await _applyGenderVoice(voiceGender.value);
        }
      } else {
        await _applyGenderVoice(voiceGender.value);
      }

      // Apply rate, volume, and natural pitch 1.0
      await _flutterTts.setVolume(volume.value);
      await _flutterTts.setSpeechRate(speechSpeed.value);
      await _flutterTts.setPitch(1.0);

      isInitialized.value = true;
      developer.log('TextToSpeechService initialized successfully with ${availableVoices.length} voices');
    } catch (e, stack) {
      developer.log('Error initializing TextToSpeechService: $e\n$stack');
      isInitialized.value = true; // prevent blocking UI indefinitely
    }
  }

  /// Safely extracts device voices into clean map format
  Future<void> _loadDeviceVoices() async {
    try {
      final rawVoices = await _flutterTts.getVoices;
      final List<Map<String, String>> parsedVoices = [];

      if (rawVoices is List) {
        for (final item in rawVoices) {
          if (item is Map) {
            final Map<String, String> voiceMap = {};
            item.forEach((key, val) {
              if (key != null && val != null) {
                voiceMap[key.toString()] = val.toString();
              }
            });
            if (voiceMap.containsKey('name') || voiceMap.containsKey('locale') || voiceMap.containsKey('language')) {
              parsedVoices.add(voiceMap);
            }
          }
        }
      }
      availableVoices.value = parsedVoices;
    } catch (e) {
      developer.log('Failed to fetch TTS voices: $e');
      availableVoices.clear();
    }
  }

  /// Speaks text after stopping any currently active audio
  Future<void> speak(String text, {void Function()? onComplete}) async {
    if (text.trim().isEmpty) {
      onComplete?.call();
      return;
    }
    try {
      await stop(triggerCallback: false);
      isSpeaking.value = true;
      _onSpeechCompleted = onComplete;

      await _flutterTts.setVolume(volume.value);
      await _flutterTts.setSpeechRate(speechSpeed.value);

      if (activeVoice.isNotEmpty) {
        await _flutterTts.setVoice(activeVoice);
      }
      await _flutterTts.speak(text);

      // Failsafe trigger when speak() completes
      isSpeaking.value = false;
      final cb = _onSpeechCompleted;
      if (cb != null) {
        _onSpeechCompleted = null;
        cb();
      }
    } catch (e) {
      developer.log('Error speaking text: $e');
      isSpeaking.value = false;
      final cb = _onSpeechCompleted;
      _onSpeechCompleted = null;
      cb?.call();
    }
  }

  /// Stops active speech
  Future<void> stop({bool triggerCallback = false}) async {
    final callback = _onSpeechCompleted;
    if (!triggerCallback) {
      _onSpeechCompleted = null;
    }
    try {
      await _flutterTts.stop();
    } catch (e) {
      developer.log('Error stopping TTS: $e');
    } finally {
      isSpeaking.value = false;
      if (triggerCallback && callback != null) {
        _onSpeechCompleted = null;
        callback();
      }
    }
  }

  /// Pauses active speech
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      developer.log('Error pausing TTS: $e');
    }
  }

  /// Resumes speech if supported
  Future<void> resume() async {
    try {
      // FlutterTts pause/resume fallback
    } catch (e) {
      developer.log('Error resuming TTS: $e');
    }
  }

  /// Updates speech volume (0.0 to 1.0) and persists choice
  Future<void> setVolume(double vol) async {
    final clamped = vol.clamp(0.0, 1.0);
    volume.value = clamped;
    try {
      await _flutterTts.setVolume(clamped);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyVolume, clamped);
    } catch (e) {
      developer.log('Error setting TTS volume: $e');
    }
  }

  /// Updates speech rate/speed (0.25 to 0.75) and persists choice
  Future<void> setSpeechSpeed(double speed) async {
    final clamped = speed.clamp(0.25, 0.75);
    speechSpeed.value = clamped;
    try {
      await _flutterTts.setSpeechRate(clamped);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keySpeed, clamped);
    } catch (e) {
      developer.log('Error setting TTS speed: $e');
    }
  }

  /// Dynamically selects male or female voice and persists choice
  Future<void> setVoiceGender(String gender) async {
    final targetGender = gender.toLowerCase() == 'male' ? 'male' : 'female';
    voiceGender.value = targetGender;
    await _applyGenderVoice(targetGender);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyGender, targetGender);
      if (activeVoice.containsKey('name')) {
        await prefs.setString(_keyVoiceName, activeVoice['name']!);
      }
      if (activeVoice.containsKey('locale')) {
        await prefs.setString(_keyVoiceLocale, activeVoice['locale']!);
      }
    } catch (e) {
      developer.log('Error persisting voice gender: $e');
    }
  }

  /// Resolves actual voice selection via FemaleVoice or MaleVoice helpers
  Future<void> _applyGenderVoice(String gender) async {
    final VoiceSelectionResult result = gender == 'male'
        ? MaleVoice.selectMaleVoice(availableVoices)
        : FemaleVoice.selectFemaleVoice(availableVoices);

    activeVoice.value = result.voice;
    isGenderVerified.value = result.isVerifiedGender;
    genderStatusLabel.value = result.genderLabel;

    if (result.voice.isNotEmpty) {
      try {
        await _flutterTts.setVoice(result.voice);
      } catch (e) {
        developer.log('Error applying voice $result.voice: $e');
      }
    }
  }

  /// Plays a natural, professional test sentence matching selected interviewer voice
  Future<void> testVoice() async {
    final isMale = voiceGender.value == 'male';
    final sampleSentence = isMale
        ? 'This is the male voice. This voice is designed for professional interviewer and natural English conversations.'
        : 'This is the female voice. This voice is designed for professional interviewer and natural English conversations.';
    await speak(sampleSentence);
  }
}
