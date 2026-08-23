import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/theme/theme_service.dart';
import '../services/voice/text_to_speech.dart';

class SettingsController extends GetxController {
  final TextToSpeechService _ttsService = TextToSpeechService.instance;
  final ThemeService _themeService = ThemeService.to;

  // TTS Properties
  RxDouble get volume => _ttsService.volume;
  RxDouble get speechSpeed => _ttsService.speechSpeed;
  RxString get voiceGender => _ttsService.voiceGender;
  RxBool get isSpeaking => _ttsService.isSpeaking;
  RxMap<String, String> get activeVoice => _ttsService.activeVoice;
  RxBool get isGenderVerified => _ttsService.isGenderVerified;
  RxString get genderStatusLabel => _ttsService.genderStatusLabel;

  // Theme Properties
  Rx<ThemeMode> get themeMode => _themeService.themeModeRx;
  bool get isDarkMode => _themeService.isDarkMode;

  @override
  void onInit() {
    super.onInit();
    _ttsService.init();
  }

  void setThemeMode(ThemeMode mode) {
    _themeService.setThemeMode(mode);
  }

  void setVolume(double val) {
    _ttsService.setVolume(val);
  }

  void setSpeechSpeed(double val) {
    _ttsService.setSpeechSpeed(val);
  }

  void setGender(String gender) {
    _ttsService.setVoiceGender(gender);
  }

  void testVoice() {
    _ttsService.testVoice();
  }

  void stopSpeech() {
    _ttsService.stop();
  }
}
