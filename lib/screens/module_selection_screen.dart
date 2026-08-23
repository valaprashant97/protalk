import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../controllers/module_selection_controller.dart';
import '../core/constants/app_colors.dart';
import '../routes/app_routes.dart';

class ModuleSelectionScreen extends GetView<ModuleSelectionController> {
  const ModuleSelectionScreen({super.key});

  ModuleSelectionController get _controller => controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 110,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      _buildModuleSection(context),
                      const SizedBox(height: 24),
                      Obx(
                        () => _controller.selectedModule.value == 'interview'
                            ? _buildInterviewFields(context)
                            : _buildEnglishFields(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customize Session',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Choose your practice mode and personalize your AI session.',
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.getTextSecondary(context),
            fontWeight: FontWeight.normal,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildModuleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRACTICE MODULE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: AppColors.getTextMuted(context),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;

            final interviewCard = _buildModuleCard(
              context: context,
              id: 'interview',
              title: 'Mock Interview',
              description: 'Technical, HR & domain questions.',
              icon: Icons.work_outline_rounded,
            );

            final englishCard = _buildModuleCard(
              context: context,
              id: 'english',
              title: 'English Conversation',
              description: 'Interactive spoken English practice.',
              icon: Icons.translate_rounded,
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: interviewCard),
                  const SizedBox(width: 12),
                  Expanded(child: englishCard),
                ],
              );
            }

            return Column(
              children: [
                interviewCard,
                const SizedBox(height: 10),
                englishCard,
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String id,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isSelected = _controller.selectedModule.value == id;

      final cardBg = isSelected
          ? (isDark ? const Color(0xFF202534) : Colors.black)
          : AppColors.getSurface(context);
      final cardBorder = isSelected
          ? (isDark ? const Color(0xFF384358) : Colors.black)
          : AppColors.getBorder(context);
      final titleColor = isSelected
          ? (isDark ? const Color(0xFFE2E8F0) : Colors.white)
          : AppColors.getTextPrimary(context);
      final descColor = isSelected
          ? (isDark ? const Color(0xFF94A3B8) : Colors.white.withValues(alpha: 0.8))
          : AppColors.getTextSecondary(context);
      final iconBg = isSelected
          ? (isDark ? const Color(0xFF2B3245) : const Color(0xFF27272A))
          : AppColors.getCard(context);

      return InkWell(
        onTap: () => _controller.setModule(id),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border.all(
              color: cardBorder,
              width: isSelected ? 1.8 : 1.0,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? (isDark ? const Color(0xFFE2E8F0) : Colors.white)
                      : AppColors.getTextPrimary(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: descColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // --- INTERVIEW FORM FIELDS ---
  Widget _buildInterviewFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final isError = _controller.showValidationErrors.value && !_controller.isCourseValid;
          return _buildCustomSelectorCard(
            context: context,
            label: 'EDUCATION / COURSE',
            hint: 'Select Course',
            value: _controller.selectedCourse.value,
            icon: Icons.school_outlined,
            isError: isError,
            errorMessage: 'Please select course',
            onTap: () => _showSelectionBottomSheet(
              context: context,
              title: 'Select Course',
              items: _controller.courses,
              selectedValue: _controller.selectedCourse.value,
              onSelected: (val) => _controller.selectedCourse.value = val,
            ),
          );
        }),
        const SizedBox(height: 16),
        Obx(() {
          final isError = _controller.showValidationErrors.value && !_controller.isInterviewTypeValid;
          return _buildCustomSelectorCard(
            context: context,
            label: 'INTERVIEW TYPE',
            hint: 'Select Type (e.g., Technical, HR)',
            value: _controller.selectedInterviewType.value,
            icon: Icons.assignment_ind_outlined,
            isError: isError,
            errorMessage: 'Please select interview type',
            onTap: () => _showSelectionBottomSheet(
              context: context,
              title: 'Select Interview Type',
              items: _controller.interviewTypes,
              selectedValue: _controller.selectedInterviewType.value,
              onSelected: (val) => _controller.selectedInterviewType.value = val,
            ),
          );
        }),
        const SizedBox(height: 16),
        Obx(() {
          final isError = _controller.showValidationErrors.value && !_controller.isJobRoleValid;
          return _buildCustomSelectorCard(
            context: context,
            label: 'JOB ROLE',
            hint: 'Select Target Job Role',
            value: _controller.selectedJobRole.value,
            icon: Icons.badge_outlined,
            isError: isError,
            errorMessage: 'Please select job role',
            onTap: () => _showSelectionBottomSheet(
              context: context,
              title: 'Select Job Role',
              items: _controller.jobRoles,
              selectedValue: _controller.selectedJobRole.value,
              onSelected: (val) => _controller.selectedJobRole.value = val,
            ),
          );
        }),
        const SizedBox(height: 16),
        // Soft Skills Field
        _buildSkillChipsSection(
          context: context,
          label: 'SOFT SKILLS',
          skills: _controller.softSkills,
        ),
        const SizedBox(height: 16),
        // Technical Skills Field
        _buildSkillChipsSection(
          context: context,
          label: 'TECHNICAL SKILLS',
          skills: _controller.technicalSkills,
          showValidationError: true,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          context: context,
          label: 'TARGET COMPANY (OPTIONAL)',
          hint: 'e.g., Google, TCS, Startup',
          icon: Icons.business_outlined,
          onChanged: (val) => _controller.companyName.value = val,
        ),
        const SizedBox(height: 24),
        _buildDifficultySection(
          context: context,
          selectedVal: _controller.selectedInterviewDifficulty,
        ),
      ],
    );
  }

  // --- HORIZONTAL SCROLL SKILLS FIELD ---
  Widget _buildSkillChipsSection({
    required BuildContext context,
    required String label,
    required List<String> skills,
    bool showValidationError = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isError = showValidationError &&
          _controller.showValidationErrors.value &&
          !_controller.isSkillsValid;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: isError ? Colors.red.shade700 : AppColors.getTextMuted(context),
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal Scrollable Choice Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: skills.map((skill) {
                final isSelected = _controller.selectedSkills.contains(skill);
                final selectedBg = isDark ? const Color(0xFF242938) : Colors.black;
                final selectedFg = isDark ? const Color(0xFFE2E8F0) : Colors.white;
                final selectedBorder = isDark ? const Color(0xFF3B4459) : Colors.black;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (_) => _controller.toggleSkill(skill),
                    backgroundColor: AppColors.getSurface(context),
                    selectedColor: selectedBg,
                    checkmarkColor: selectedFg,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? selectedFg
                          : (isError ? Colors.red.shade700 : AppColors.getTextPrimary(context)),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? selectedBorder
                            : (isError ? Colors.red.shade400 : AppColors.getBorder(context)),
                        width: isError && !isSelected ? 1.2 : 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          ),
          if (isError)
            Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 4.0),
              child: Text(
                'Please select at least one skill',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
            ),
        ],
      );
    });
  }

  // --- ENGLISH CONVERSATION FORM FIELDS ---
  Widget _buildEnglishFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final isError = _controller.showValidationErrors.value &&
              !_controller.isTopicValid &&
              _controller.selectedConversationTopic.value != 'Custom Topic';
          return _buildCustomSelectorCard(
            context: context,
            label: 'CONVERSATION TOPIC',
            hint: 'Select Topic (e.g., Daily Life, Travel)',
            value: _controller.selectedConversationTopic.value,
            icon: Icons.list_alt_rounded,
            isError: isError,
            errorMessage: 'Please select conversation topic',
            onTap: () => _showSelectionBottomSheet(
              context: context,
              title: 'Select Conversation Topic',
              items: _controller.conversationTopics,
              selectedValue: _controller.selectedConversationTopic.value,
              onSelected: (val) {
                _controller.selectedConversationTopic.value = val;
                if (val != 'Custom Topic') {
                  _controller.conversationTopic.value = val;
                }
              },
            ),
          );
        }),
        Obx(() {
          if (_controller.selectedConversationTopic.value == 'Custom Topic') {
            final isCustomError = _controller.showValidationErrors.value &&
                _controller.customConversationTopic.value.trim().isEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildInputField(
                  context: context,
                  label: 'CUSTOM TOPIC NAME',
                  hint: 'Type custom topic here...',
                  icon: Icons.edit_note_rounded,
                  isError: isCustomError,
                  errorMessage: 'Please enter custom topic name',
                  onChanged: (val) {
                    _controller.customConversationTopic.value = val;
                    _controller.conversationTopic.value = val;
                  },
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 16),
        Obx(() {
          final isError = _controller.showValidationErrors.value && !_controller.isAiPersonalityValid;
          return _buildCustomSelectorCard(
            context: context,
            label: 'AI PERSONALITY',
            hint: 'Select AI Personality',
            value: _controller.selectedAiPersonality.value,
            icon: Icons.smart_toy_outlined,
            isError: isError,
            errorMessage: 'Please select AI personality',
            onTap: () => _showSelectionBottomSheet(
              context: context,
              title: 'Select AI Personality',
              items: _controller.aiPersonalities,
              selectedValue: _controller.selectedAiPersonality.value,
              onSelected: (val) => _controller.selectedAiPersonality.value = val,
            ),
          );
        }),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;

            final langCard = Obx(() {
              final isError = _controller.showValidationErrors.value && !_controller.isLanguageValid;
              return _buildCustomSelectorCard(
                context: context,
                label: 'LANGUAGE',
                hint: 'Select Language',
                value: _controller.selectedLanguage.value,
                icon: Icons.language_rounded,
                isError: isError,
                errorMessage: 'Please select language',
                onTap: () => _showSelectionBottomSheet(
                  context: context,
                  title: 'Select Language',
                  items: _controller.languages,
                  selectedValue: _controller.selectedLanguage.value,
                  onSelected: (val) => _controller.selectedLanguage.value = val,
                ),
              );
            });

            final correctionCard = Obx(() {
              final isError = _controller.showValidationErrors.value && !_controller.isCorrectionModeValid;
              return _buildCustomSelectorCard(
                context: context,
                label: 'CORRECTION MODE',
                hint: 'Select Mode',
                value: _controller.selectedCorrectionMode.value,
                icon: Icons.auto_fix_high_outlined,
                isError: isError,
                errorMessage: 'Please select mode',
                onTap: () => _showSelectionBottomSheet(
                  context: context,
                  title: 'Select Correction Mode',
                  items: _controller.correctionModes,
                  selectedValue: _controller.selectedCorrectionMode.value,
                  onSelected: (val) => _controller.selectedCorrectionMode.value = val,
                ),
              );
            });

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: langCard),
                  const SizedBox(width: 12),
                  Expanded(child: correctionCard),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                langCard,
                const SizedBox(height: 16),
                correctionCard,
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;

            final styleCard = Obx(() {
              final isError = _controller.showValidationErrors.value && !_controller.isConversationStyleValid;
              return _buildCustomSelectorCard(
                context: context,
                label: 'CONVERSATION STYLE',
                hint: 'Select Style',
                value: _controller.selectedConversationStyle.value,
                icon: Icons.people_outline_rounded,
                isError: isError,
                errorMessage: 'Please select style',
                onTap: () => _showSelectionBottomSheet(
                  context: context,
                  title: 'Select Conversation Style',
                  items: _controller.conversationStyles,
                  selectedValue: _controller.selectedConversationStyle.value,
                  onSelected: (val) => _controller.selectedConversationStyle.value = val,
                ),
              );
            });

            final responseCard = Obx(() {
              final isError = _controller.showValidationErrors.value && !_controller.isResponseStyleValid;
              return _buildCustomSelectorCard(
                context: context,
                label: 'AI RESPONSE STYLE',
                hint: 'Select Response Style',
                value: _controller.selectedResponseStyle.value,
                icon: Icons.forum_outlined,
                isError: isError,
                errorMessage: 'Please select style',
                onTap: () => _showSelectionBottomSheet(
                  context: context,
                  title: 'Select Response Style',
                  items: _controller.responseStyles,
                  selectedValue: _controller.selectedResponseStyle.value,
                  onSelected: (val) => _controller.selectedResponseStyle.value = val,
                ),
              );
            });

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: styleCard),
                  const SizedBox(width: 12),
                  Expanded(child: responseCard),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                styleCard,
                const SizedBox(height: 16),
                responseCard,
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _buildDifficultySection(
          context: context,
          selectedVal: _controller.selectedEnglishDifficulty,
        ),
      ],
    );
  }

  // --- COMMON UI COMPONENTS ---
  Widget _buildInputField({
    required BuildContext context,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    bool isError = false,
    String? errorMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: isError ? Colors.red.shade700 : AppColors.getTextMuted(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.getSurface(context),
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: AppColors.getTextMuted(context),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: isError ? Colors.red.shade400 : AppColors.getTextPrimary(context),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isError ? Colors.red.shade400 : AppColors.getBorder(context),
                width: isError ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isError ? Colors.red.shade400 : AppColors.getTextPrimary(context),
                width: 1.8,
              ),
            ),
          ),
        ),
        if (isError && errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              errorMessage,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomSelectorCard({
    required BuildContext context,
    required String label,
    required String hint,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    bool isError = false,
    String? errorMessage,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: isError ? Colors.red.shade700 : AppColors.getTextMuted(context),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              border: Border.all(
                color: isError
                    ? Colors.red.shade400
                    : (hasValue
                        ? (isDark ? const Color(0xFF384358) : Colors.black)
                        : AppColors.getBorder(context)),
                width: isError ? 1.5 : (hasValue ? 1.4 : 1),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isError
                      ? Colors.red.shade400
                      : (hasValue ? AppColors.getTextPrimary(context) : AppColors.getTextSecondary(context)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasValue ? value : hint,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? AppColors.getTextPrimary(context)
                          : AppColors.getTextMuted(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isError ? Colors.red.shade400 : AppColors.getTextSecondary(context),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isError && errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              errorMessage,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDifficultySection({
    required BuildContext context,
    required RxString selectedVal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DIFFICULTY LEVEL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: AppColors.getTextMuted(context),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _controller.difficultyLevels
              .map((level) => _buildDifficultyChip(context, level, selectedVal))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDifficultyChip(
    BuildContext context,
    String label,
    RxString selectedVal,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isSelected = selectedVal.value == label;
      final selectedBg = isDark ? const Color(0xFF242938) : Colors.black;
      final selectedFg = isDark ? const Color(0xFFE2E8F0) : Colors.white;
      final selectedBorder = isDark ? const Color(0xFF3B4459) : Colors.black;

      return GestureDetector(
        onTap: () => selectedVal.value = label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : AppColors.getSurface(context),
            border: Border.all(
              color: isSelected ? selectedBorder : AppColors.getBorder(context),
              width: isSelected ? 1.4 : 1,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? selectedFg : AppColors.getTextSecondary(context),
            ),
          ),
        ),
      );
    });
  }

  void _showSelectionBottomSheet({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String? selectedValue,
    required Function(String) onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.48;

    Get.bottomSheet(
      ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: maxSheetHeight,
              maxWidth: 640,
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF0D0F15) : Colors.white).withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(
                  color: AppColors.getBorder(context).withValues(alpha: 0.60),
                  width: 1.2,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.getTextMuted(context).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = item == selectedValue;

                      return InkWell(
                        onTap: () {
                          onSelected(item);
                          Get.back();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFF202534).withValues(alpha: 0.70)
                                    : const Color(0xFFF1F5F9))
                                : (isDark
                                    ? const Color(0xFF1C202C).withValues(alpha: 0.70)
                                    : const Color(0xFFF8F9FA)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF384358) : Colors.black)
                                  : AppColors.getBorder(context).withValues(alpha: 0.60),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: isDark ? const Color(0xFFCBD5E1) : Colors.black,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      isScrollControlled: true,
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context).withValues(alpha: 0.92),
              border: Border(
                top: BorderSide(
                  color: AppColors.getBorder(context).withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _onStartPractice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF222736) : Colors.black,
                        foregroundColor: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                        elevation: 0,
                        splashFactory: InkRipple.splashFactory,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isDark ? const BorderSide(color: Color(0xFF333B50)) : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start Practice',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onStartPractice() {
    if (!_controller.validateForm()) {
      return;
    }

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final isInterview = _controller.selectedModule.value == 'interview';
    final Map<String, dynamic> config = isInterview
        ? {
            'sessionId': sessionId,
            'module': 'interview',
            'interviewType': _controller.selectedInterviewType.value,
            'jobRole': _controller.selectedJobRole.value,
            'skills': _controller.selectedSkills.toList(),
            'course': _controller.selectedCourse.value,
            'company': _controller.companyName.value,
            'difficulty': _controller.selectedInterviewDifficulty.value,
          }
        : {
            'sessionId': sessionId,
            'module': 'english',
            'englishTopic': _controller.effectiveConversationTopic,
            'aiPersonality': _controller.selectedAiPersonality.value,
            'language': _controller.selectedLanguage.value,
            'correctionMode': _controller.selectedCorrectionMode.value,
            'conversationStyle': _controller.selectedConversationStyle.value,
            'responseStyle': _controller.selectedResponseStyle.value,
            'difficulty': _controller.selectedEnglishDifficulty.value,
          };

    _controller.saveSessionConfig(config);
    if (Get.isRegistered<ChatController>()) {
      Get.delete<ChatController>(force: true);
    }
    Get.offNamed(AppRoutes.chat, arguments: config);
  }
}
