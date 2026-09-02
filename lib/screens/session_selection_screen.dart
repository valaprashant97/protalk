import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../controllers/session_selection_controller.dart';
import '../routes/app_routes.dart';
import '../services/database/tables/chat_history_table.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';

class SessionSelectionScreen extends GetView<SessionSelectionController> {
  const SessionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with Settings Button on top right
                  _buildHeader(context),
                  const SizedBox(height: 20),

                  // "Create New Session" Hero Button
                  _buildCreateNewSessionCard(context, controller),
                  const SizedBox(height: 24),

                  // Recent Sessions Section Header
                  _buildSectionHeader(context, controller),
                  const SizedBox(height: 12),

                  // Independently Scrollable Recent Sessions List
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.getTextPrimary(context),
                            strokeWidth: 2.5,
                          ),
                        );
                      }

                      if (controller.recentSessions.isEmpty) {
                        return _buildEmptyState(context, controller);
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: controller.recentSessions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final session = controller.recentSessions[index];
                          return _buildSessionCard(context, controller, session);
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Header with Settings Button on the top right
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Practice Sessions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextPrimary(context),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Resume a saved session or start a new simulation.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.getTextSecondary(context),
                  fontWeight: FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Settings Button on top right corner
        IconButton(
          onPressed: () => Get.toNamed(AppRoutes.settings),
          icon: Icon(
            Icons.settings_outlined,
            color: AppColors.getTextPrimary(context),
            size: 24,
          ),
          tooltip: 'Settings',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.getSurface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.getBorder(context)),
            ),
          ),
        ),
      ],
    );
  }

  // "Create New Session" Card styled identically to app's primary action components
  Widget _buildCreateNewSessionCard(
    BuildContext context,
    SessionSelectionController controller,
  ) {
    final isDark = AppColors.isDark(context);

    final cardBg = isDark ? const Color(0xFF222736) : AppColors.getSurface(context);
    final cardBorder = isDark ? const Color(0xFF333B50) : AppColors.getBorder(context);
    final iconBg = isDark ? const Color(0xFF2B3245) : AppColors.getCard(context);
    final iconBorder = isDark ? const Color(0xFF384358) : AppColors.getBorder(context);
    final iconColor = isDark ? Colors.white : AppColors.getTextPrimary(context);
    final titleColor = isDark ? Colors.white : AppColors.getTextPrimary(context);
    final descColor = isDark ? Colors.white.withValues(alpha: 0.75) : AppColors.getTextSecondary(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.createNewSession,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconBorder, width: 1),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Configure a new Mock Interview or English practice',
                      style: TextStyle(
                        fontSize: 12,
                        color: descColor,
                        fontWeight: FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(
    BuildContext context,
    SessionSelectionController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'RECENT SESSIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: AppColors.getTextMuted(context),
          ),
        ),
        Obx(() {
          final count = controller.recentSessions.length;
          if (count == 0) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.getCard(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.getBorder(context),
                width: 1,
              ),
            ),
            child: Text(
              '$count ${count == 1 ? "session" : "sessions"}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextSecondary(context),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Recent Session Card matching other screens (White in Light Mode, Charcoal in Dark Mode)
  Widget _buildSessionCard(
    BuildContext context,
    SessionSelectionController controller,
    SessionSummaryModel session,
  ) {
    final isEnglish = session.module.toLowerCase() == 'english' ||
        session.title.toLowerCase().contains('english');
    final svgAsset = isEnglish
        ? 'assets/svg/english-communication.svg'
        : 'assets/svg/interview.svg';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.openRecentSession(session),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.getBorder(context),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.15 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container: interview or english-communication SVG
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.getCard(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.getBorder(context),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    svgAsset,
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      AppColors.getTextPrimary(context),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Session Name / Title only
              Expanded(
                child: Text(
                  session.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(context),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Three Dot Menu (Rename & Delete)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: AppColors.getTextSecondary(context),
                ),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.getBorder(context)),
                ),
                color: AppColors.getSurface(context),
                elevation: 4,
                onSelected: (val) {
                  if (val == 'rename') {
                    _showRenameDialog(context, controller, session);
                  } else if (val == 'delete') {
                    controller.deleteSession(session.sessionId);
                  }
                },
                itemBuilder: (context) => [
                  // Rename Option
                  PopupMenuItem(
                    value: 'rename',
                    height: 42,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.getTextPrimary(context),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Rename',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(
                    height: 1,
                  ),
                  // Delete Option
                  PopupMenuItem(
                    value: 'delete',
                    height: 42,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppTheme.error,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Rename Session Dialog
  void _showRenameDialog(
    BuildContext context,
    SessionSelectionController controller,
    SessionSummaryModel session,
  ) {
    final isDark = AppColors.isDark(context);
    final textController = TextEditingController(text: session.title);

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.getBorder(context)),
        ),
        title: Text(
          'Rename Session',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a new name for this practice session:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              autofocus: true,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(context),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.getCard(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                hintText: 'Session Title',
                hintStyle: TextStyle(
                  color: AppColors.getTextMuted(context),
                  fontSize: 13,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.getBorder(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.getTextPrimary(context),
                    width: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.getTextSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                Get.back();
                controller.renameSession(session.sessionId, newName);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF222736) : const Color(0xFF242936),
              foregroundColor: isDark ? const Color(0xFFE2E8F0) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: isDark ? const BorderSide(color: Color(0xFF333B50)) : const BorderSide(color: Color(0xFF384054)),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }


  // Empty State
  Widget _buildEmptyState(
    BuildContext context,
    SessionSelectionController controller,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.getCard(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Icon(
                Icons.history_toggle_off_rounded,
                size: 28,
                color: AppColors.getTextMuted(context),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No Recent Sessions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start your first simulation to build your history',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
