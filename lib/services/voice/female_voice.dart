import 'dart:developer' as developer;

class VoiceSelectionResult {
  final Map<String, String> voice;
  final bool isVerifiedGender;
  final String genderLabel;

  VoiceSelectionResult({
    required this.voice,
    required this.isVerifiedGender,
    required this.genderLabel,
  });
}

class FemaleVoice {
  /// Priority ordered warm, articulate, professional adult female voice patterns across Android (Google TTS) and iOS (Apple TTS).
  static const List<String> preferredFemaleVoicePatterns = [
    // Highest quality neural/network Google TTS adult female voices
    'en-us-x-sfg-network', // Warm, articulate, authoritative female interviewer
    'en-us-x-tpf-network', // Confident, clear adult female interviewer
    'en-us-x-iob-network', // Articulate adult female
    'sfg',
    'tpf',
    'iob',
    'wavenet-a',
    'wavenet-c',
    'wavenet-e',
    'wavenet-f',
    'studio-o',
    'neural2-f',

    // Top-tier adult female voices (Apple iOS TTS & standard engines)
    'samantha',  // com.apple.ttsbundle.Samantha (Clear, natural US female)
    'victoria',  // Victoria (Confident mature female)
    'karen',     // Karen (Articulate female)
    'zira',      // Zira
    'sarah',     // Sarah
    'ava',       // Ava
    'emily',     // Emily
    'serena',    // Serena
    'female',    // Generic female descriptor
    'woman',     // Generic woman descriptor
  ];

  /// Strictly exclude any male voice patterns
  static const List<String> maleExclusionPatterns = [
    'male',
    'man',
    'boy',
    'guy',
    '-m-',
    '_m_',
    'iom',       // Google male voice iom
    'tpd',       // Google male voice tpd
    'sfc',       // Google male voice sfc
    'iol',       // Google male voice iol
    'tpc',       // Google male voice tpc
    'dfz',
    'rog',
    'david',
    'daniel',
    'alex',
    'oliver',
    'nathan',
    'evan',
    'george',
    'john',
    'james',
    'fred',
  ];

  /// Dynamically detects and returns a warm, articulate, professional adult female English voice.
  static VoiceSelectionResult selectFemaleVoice(List<Map<String, String>> voices) {
    if (voices.isEmpty) {
      return VoiceSelectionResult(
        voice: {'name': '', 'locale': 'en-US'},
        isVerifiedGender: false,
        genderLabel: 'Default (No voices loaded)',
      );
    }

    // Step 1: Filter English voices
    final englishVoices = voices.where((v) {
      final loc = (v['locale'] ?? v['language'] ?? '').toLowerCase();
      return loc.startsWith('en');
    }).toList();

    final candidateList = englishVoices.isNotEmpty ? englishVoices : voices;

    // Step 2: Match against ordered priority list of natural adult female voice identifiers
    for (final pattern in preferredFemaleVoicePatterns) {
      for (final v in candidateList) {
        final name = (v['name'] ?? '').toLowerCase();
        final isMaleName = maleExclusionPatterns.any((kw) => name.contains(kw));

        if (!isMaleName && name.contains(pattern)) {
          return VoiceSelectionResult(
            voice: {
              'name': v['name'] ?? '',
              'locale': v['locale'] ?? v['language'] ?? 'en-US',
            },
            isVerifiedGender: true,
            genderLabel: 'Verified Female Interviewer (${_formatVoiceDisplayName(v['name'] ?? '')})',
          );
        }
      }
    }

    // Step 3: Check explicit platform gender metadata ('female' or '2')
    for (final v in candidateList) {
      final genderMeta = (v['gender'] ?? '').toString().toLowerCase();
      final name = (v['name'] ?? '').toLowerCase();

      final isExplicitFemale = genderMeta == 'female' || genderMeta == '2';
      final isMaleName = maleExclusionPatterns.any((kw) => name.contains(kw));

      if (isExplicitFemale && !isMaleName) {
        return VoiceSelectionResult(
          voice: {
            'name': v['name'] ?? '',
            'locale': v['locale'] ?? v['language'] ?? 'en-US',
          },
          isVerifiedGender: true,
          genderLabel: 'Verified Female Interviewer (${_formatVoiceDisplayName(v['name'] ?? '')})',
        );
      }
    }

    // Step 4: Fallback to non-male English voice
    final nonMaleEnglishVoices = candidateList.where((v) {
      final name = (v['name'] ?? '').toLowerCase();
      return !maleExclusionPatterns.any((kw) => name.contains(kw));
    }).toList();

    final fallbackVoice = nonMaleEnglishVoices.isNotEmpty
        ? nonMaleEnglishVoices.firstWhere(
            (v) {
              final loc = (v['locale'] ?? v['language'] ?? '').toUpperCase();
              return loc == 'EN-US' || loc == 'EN_US';
            },
            orElse: () => nonMaleEnglishVoices.first,
          )
        : candidateList.first;

    developer.log(
      'Female voice metadata unverified; selecting non-male fallback voice: ${fallbackVoice['name']}',
    );

    return VoiceSelectionResult(
      voice: {
        'name': fallbackVoice['name'] ?? '',
        'locale': fallbackVoice['locale'] ?? fallbackVoice['language'] ?? 'en-US',
      },
      isVerifiedGender: false,
      genderLabel: 'Professional English Female (Fallback)',
    );
  }

  static String _formatVoiceDisplayName(String rawName) {
    if (rawName.isEmpty) return 'Female Voice';
    final parts = rawName.split('-');
    if (parts.length > 2) {
      return parts.sublist(0, parts.length - 1).join('-');
    }
    return rawName;
  }
}
