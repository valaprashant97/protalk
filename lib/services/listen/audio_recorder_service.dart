import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service for recording audio from the device microphone.
///
/// Uses the `record` package — no Android SpeechRecognizer,
/// no start/stop beeps. Records AAC audio to a temp .m4a file
/// that Groq Whisper accepts.
/// Supports Voice Activity Detection (silence detection) for Live Auto Mode.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _silenceTimer;
  bool _hasSpoken = false;
  Function()? _onSilenceDetected;

  /// Checks whether the app has microphone permission.
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Starts recording audio to a temporary .m4a file.
  ///
  /// Optionally takes [onSilenceDetected] to auto-trigger when the user
  /// finishes speaking (1.5s of silence after speech is detected).
  Future<String?> startRecording({Function()? onSilenceDetected}) async {
    final permitted = await hasPermission();
    if (!permitted) return null;

    await _stopMonitoring();

    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/groq_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 16000,
      numChannels: 1,
      bitRate: 64000,
    );

    await _recorder.start(config, path: filePath);
    _isRecording = true;
    _onSilenceDetected = onSilenceDetected;
    _hasSpoken = false;

    if (_onSilenceDetected != null) {
      _startSilenceMonitoring();
    }

    return filePath;
  }

  int _speechSampleCount = 0;

  void _startSilenceMonitoring() {
    _amplitudeSubscription?.cancel();
    _speechSampleCount = 0;
    _hasSpoken = false;

    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 150))
        .listen((amp) {
      if (!_isRecording) return;

      final db = amp.current;

      // Active speech threshold: > -32 dB (requires 2 consecutive samples ~300ms of sustained voice energy)
      if (db > -32.0) {
        _speechSampleCount++;
        if (_speechSampleCount >= 2) {
          _hasSpoken = true;
          _silenceTimer?.cancel();
          _silenceTimer = null;
        }
      } else {
        _speechSampleCount = 0;
        if (_hasSpoken && db <= -38.0) {
          // User was confirmed speaking and has now been silent for 1.8s
          _silenceTimer ??= Timer(const Duration(milliseconds: 1400), () {
            if (_isRecording) {
              _onSilenceDetected?.call();
            }
          });
        }
      }
    });
  }

  Future<void> _stopMonitoring() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _speechSampleCount = 0;
    _hasSpoken = false;
    _onSilenceDetected = null;
  }

  /// Stops the current recording and returns the file path of the
  /// recorded audio, or `null` if nothing was recording.
  Future<String?> stopRecording() async {
    await _stopMonitoring();
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;
    return path;
  }

  /// Cancels the current recording and deletes the temp file.
  Future<void> cancelRecording() async {
    await _stopMonitoring();
    if (!_isRecording) return;

    final path = await _recorder.stop();
    _isRecording = false;

    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  /// Releases recorder resources.
  void dispose() {
    _stopMonitoring();
    _recorder.dispose();
  }
}
