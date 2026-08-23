import 'dart:developer' as developer;
import 'female_voice.dart' show VoiceSelectionResult;

class MaleVoice {
  /// Priority ordered natural, professional adult male voice patterns across Android (Google TTS / Samsung TTS) and iOS (Apple TTS).
  static const List<String> preferredMaleVoicePatterns = [
    // Highest quality neural/network Google TTS adult male voices
    'en-us-x-iom-network', // Deep, authoritative adult male interviewer
    'en-us-x-tpd-network', // Clear, confident adult male interviewer
    'en-us-x-sfc-network', // Calm, articulate adult male
    'en-us-x-iol-network', // Confident professional male
    'en-us-x-tpc-network', // Professional adult male
    'en-us-x-dfz-network',
    'en-us-x-rog-network',
    'iom',
    'tpd',
    'sfc',
    'iol',
    'tpc',
    'dfz',
    'rog',
    'wavenet-b',
    'wavenet-d',
    'wavenet-j',
    'studio-b',
    'neural2-d',

    // Top-tier adult male voices (Apple iOS TTS & standard engines)
    'alex',      // com.apple.ttsbundle.Alex (Gold-standard natural US male)
    'daniel',    // com.apple.ttsbundle.Daniel (Crisp adult male interviewer)
    'oliver',    // com.apple.ttsbundle.Oliver (Adult male)
    'nathan',    // com.apple.voice.compact.en-US.Nathan
    'evan',      // com.apple.voice.compact.en-US.Evan
    'aaron',     // com.apple.ttsbundle.Aaron
    'arthur',    // com.apple.ttsbundle.Arthur
    'tom',       // com.apple.ttsbundle.Tom
    'fred',      // com.apple.ttsbundle.Fred
    'george',    // George
    'david',     // David (Microsoft / Apple / Android)
    'james',     // James
    'john',      // John
    'michael',   // Michael
    'stephen',   // Stephen
    'guy',       // Guy
    'male',      // Generic male descriptor
    'man',       // Generic man descriptor
  ];

  /// Strictly exclude any female voice patterns
  static const List<String> femaleExclusionPatterns = [
    'female',
    'woman',
    'girl',
    'lady',
    '-f-',
    '_f_',
    'sfg',      // Google TTS female voice
    'tpf',      // Google TTS female voice
    'samantha',
    'victoria',
    'karen',
    'zira',
    'sarah',
    'ava',
    'emily',
    'serena',
    'wavenet-a',
    'wavenet-c',
    'wavenet-e',
    'wavenet-f',
  ];

  /// Dynamically detects and returns a genuine, natural-sounding, professional adult male English voice.
  static VoiceSelectionResult selectMaleVoice(List<Map<String, String>> voices) {
    if (voices.isEmpty) {
      return VoiceSelectionResult(
        voice: {'name': '', 'locale': 'en-US'},
        isVerifiedGender: false,
        genderLabel: 'Default (No voices loaded)',
      );
    }

    // Step 1: Filter English voices (en-US primary, then en-*)
    final englishVoices = voices.where((v) {
      final loc = (v['locale'] ?? v['language'] ?? '').toLowerCase();
      return loc.startsWith('en');
    }).toList();

    final candidateList = englishVoices.isNotEmpty ? englishVoices : voices;

    // Step 2: Match against ordered priority list of natural adult male voice identifiers
    for (final pattern in preferredMaleVoicePatterns) {
      for (final v in candidateList) {
        final name = (v['name'] ?? '').toLowerCase();
        final isFemaleName = femaleExclusionPatterns.any((kw) => name.contains(kw));

        if (!isFemaleName && name.contains(pattern)) {
          return VoiceSelectionResult(
            voice: {
              'name': v['name'] ?? '',
              'locale': v['locale'] ?? v['language'] ?? 'en-US',
            },
            isVerifiedGender: true,
            genderLabel: 'Verified Male Interviewer (${_formatVoiceDisplayName(v['name'] ?? '')})',
          );
        }
      }
    }

    // Step 3: Check explicit platform gender metadata ('male' or '1')
    for (final v in candidateList) {
      final genderMeta = (v['gender'] ?? '').toString().toLowerCase();
      final name = (v['name'] ?? '').toLowerCase();

      final isExplicitMale = genderMeta == 'male' || genderMeta == '1';
      final isFemaleName = femaleExclusionPatterns.any((kw) => name.contains(kw));

      if (isExplicitMale && !isFemaleName) {
        return VoiceSelectionResult(
          voice: {
            'name': v['name'] ?? '',
            'locale': v['locale'] ?? v['language'] ?? 'en-US',
          },
          isVerifiedGender: true,
          genderLabel: 'Verified Male Interviewer (${_formatVoiceDisplayName(v['name'] ?? '')})',
        );
      }
    }

    // Step 4: Fallback to non-female English voice (strictly avoiding female voices)
    final nonFemaleEnglishVoices = candidateList.where((v) {
      final name = (v['name'] ?? '').toLowerCase();
      return !femaleExclusionPatterns.any((kw) => name.contains(kw));
    }).toList();

    final fallbackVoice = nonFemaleEnglishVoices.isNotEmpty
        ? nonFemaleEnglishVoices.firstWhere(
            (v) {
              final loc = (v['locale'] ?? v['language'] ?? '').toUpperCase();
              return loc == 'EN-US' || loc == 'EN_US';
            },
            orElse: () => nonFemaleEnglishVoices.first,
          )
        : candidateList.first;

    developer.log(
      'Male voice metadata unverified; selecting non-female fallback voice: ${fallbackVoice['name']}',
    );

    return VoiceSelectionResult(
      voice: {
        'name': fallbackVoice['name'] ?? '',
        'locale': fallbackVoice['locale'] ?? fallbackVoice['language'] ?? 'en-US',
      },
      isVerifiedGender: false,
      genderLabel: 'Professional English Male (Fallback)',
    );
  }

  static String _formatVoiceDisplayName(String rawName) {
    if (rawName.isEmpty) return 'Male Voice';
    final parts = rawName.split('-');
    if (parts.length > 2) {
      return parts.sublist(0, parts.length - 1).join('-');
    }
    return rawName;
  }
}
