import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../core/constants/app_colors.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const appBarHeight = 56.0;
    final totalAppBarHeight = topPadding + appBarHeight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Scrollable Settings Content (Layer 1 - Scrolls behind glass AppBar)
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsets.only(
                top: totalAppBarHeight + 16,
                bottom: 32 + bottomPadding,
                left: 20.0,
                right: 20.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // ========================================================
                  // 1. APPEARANCE & THEME SECTION
                  // ========================================================
                  Text(
                    'APPEARANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildSectionContainer(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              size: 20,
                              color: AppColors.getTextPrimary(context),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'App Theme',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose between Light, Dark, or System theme',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(() {
                          final currentMode = controller.themeMode.value;
                          return Row(
                            children: [
                              Expanded(
                                child: _buildThemeModeOption(
                                  context: context,
                                  label: 'System',
                                  icon: Icons.brightness_auto_outlined,
                                  isSelected: currentMode == ThemeMode.system,
                                  onTap: () => controller.setThemeMode(ThemeMode.system),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildThemeModeOption(
                                  context: context,
                                  label: 'Light',
                                  icon: Icons.light_mode_outlined,
                                  isSelected: currentMode == ThemeMode.light,
                                  onTap: () => controller.setThemeMode(ThemeMode.light),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildThemeModeOption(
                                  context: context,
                                  label: 'Dark',
                                  icon: Icons.dark_mode_outlined,
                                  isSelected: currentMode == ThemeMode.dark,
                                  onTap: () => controller.setThemeMode(ThemeMode.dark),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ========================================================
                  // 2. VOICE & SPEECH SETTINGS SECTION
                  // ========================================================
                  Text(
                    'VOICE & SPEECH',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Voice Gender Card
                  _buildSectionContainer(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.record_voice_over_outlined,
                              size: 20,
                              color: AppColors.getTextPrimary(context),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Voice Persona',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select preferred AI voice gender',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(() {
                          final selected = controller.voiceGender.value;
                          return Row(
                            children: [
                              Expanded(
                                child: _buildVoiceOption(
                                  context: context,
                                  label: 'Female Voice',
                                  icon: Icons.female_rounded,
                                  isSelected: selected == 'female',
                                  onTap: () => controller.setGender('female'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildVoiceOption(
                                  context: context,
                                  label: 'Male Voice',
                                  icon: Icons.male_rounded,
                                  isSelected: selected == 'male',
                                  onTap: () => controller.setGender('male'),
                                ),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 12),
                        Obx(() {
                          final label = controller.genderStatusLabel.value;
                          final isVerified = controller.isGenderVerified.value;
                          if (label.isEmpty) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1F2330) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.getBorder(context)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isVerified ? Icons.verified_rounded : Icons.info_outline,
                                  size: 15,
                                  color: AppColors.getTextPrimary(context),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Voice Volume Card
                  _buildSectionContainer(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.volume_up_outlined,
                                  size: 20,
                                  color: AppColors.getTextPrimary(context),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Voice Volume',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                            Obx(
                              () => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1F2330) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${(controller.volume.value * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Adjust speech playback volume',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(
                          () => Slider(
                            value: controller.volume.value,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            onChanged: (val) => controller.setVolume(val),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Speech Speed Card
                  _buildSectionContainer(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.speed_outlined,
                                  size: 20,
                                  color: AppColors.getTextPrimary(context),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Speech Speed',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                            Obx(
                              () => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1F2330) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${controller.speechSpeed.value.toStringAsFixed(2)}x',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set speaking rate (0.25x slow to 0.75x fast)',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(
                          () => Slider(
                            value: controller.speechSpeed.value,
                            min: 0.25,
                            max: 0.75,
                            divisions: 20,
                            onChanged: (val) => controller.setSpeechSpeed(val),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Test Voice Button
                  Obx(() {
                    final speaking = controller.isSpeaking.value;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: speaking ? controller.stopSpeech : controller.testVoice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: speaking
                              ? (isDark ? const Color(0xFF353D52) : const Color(0xFF334155))
                              : (isDark ? const Color(0xFF222738) : Colors.black),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isDark
                                ? const BorderSide(color: Color(0xFF3B4359))
                                : BorderSide.none,
                          ),
                        ),
                        icon: Icon(
                          speaking ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: Text(
                          speaking ? 'Stop Speaking' : 'Test Audio Voice',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Engine & Voice Details Card
                  _buildSectionContainer(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ENGINE & LOCALE DETAILS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppColors.getTextMuted(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          final voice = controller.activeVoice;
                          final voiceName = voice['name'] ?? 'System Default TTS Voice';
                          final locale = voice['locale'] ?? voice['language'] ?? 'en-US';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(context, 'Voice:', voiceName),
                              const SizedBox(height: 8),
                              _buildDetailRow(context, 'Language:', locale),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),

      // 2. Top Pinned Glassmorphic App Bar (Layer 2)
      Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: totalAppBarHeight,
                  padding: EdgeInsets.only(top: topPadding),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF0D0F15) : Colors.white).withValues(alpha: 0.60),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.getBorder(context).withValues(alpha: 0.60),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.getTextPrimary(context),
                          size: 24,
                        ),
                        tooltip: 'Back',
                        onPressed: () => Get.back(),
                      ),
                      Expanded(
                        child: Text(
                          'Settings',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.getTextPrimary(context),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Equal visual spacing to balance back button
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: child,
    );
  }

  Widget _buildThemeModeOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark ? const Color(0xFF222738) : Colors.black;
    final selectedFg = Colors.white;
    final selectedBorder = isDark ? const Color(0xFF475569) : Colors.black;

    final unselectedBg = AppColors.getSurface(context);
    final unselectedFg = AppColors.getTextSecondary(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedBorder : AppColors.getBorder(context),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? selectedFg : unselectedFg,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? selectedFg : AppColors.getTextPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark ? const Color(0xFF222738) : Colors.black;
    final selectedFg = Colors.white;
    final selectedBorder = isDark ? const Color(0xFF475569) : Colors.black;

    final unselectedBg = AppColors.getSurface(context);
    final unselectedFg = AppColors.getTextPrimary(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedBorder : AppColors.getBorder(context),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedFg : unselectedFg,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? selectedFg : unselectedFg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextMuted(context),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextPrimary(context),
            ),
          ),
        ),
      ],
    );
  }
}
