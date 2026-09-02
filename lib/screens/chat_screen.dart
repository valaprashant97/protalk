import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../controllers/chat_controller.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../routes/app_routes.dart';

class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  ChatController get _controller => controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const appBarContentHeight = 62.0;
    final totalAppBarHeight = topPadding + appBarContentHeight;
    const bottomControlsHeight = 146.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          // 1. Full-Height Scrollable Chat Messages List (Layer 1 - Scrolls behind glass bars)
          Positioned.fill(
            child: Obx(
              () {
                final isListening = _controller.currentState.value == VoiceState.listening;
                final hasLiveSpeech = _controller.liveSpeech.value.isNotEmpty;
                final showLiveBubble = isListening || hasLiveSpeech;
                final itemCount = _controller.messages.length + (showLiveBubble ? 1 : 0);

                return ListView.builder(
                  controller: _controller.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.only(
                    top: totalAppBarHeight + 12,
                    bottom: bottomControlsHeight + bottomPadding + 16,
                    left: 16,
                    right: 16,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index < _controller.messages.length) {
                      final message = _controller.messages[index];
                      return _buildChatBubble(context, message);
                    } else {
                      final text = _controller.liveSpeech.value;
                      return _buildLiveSpeechBubble(context, text.isEmpty ? "..." : text);
                    }
                  },
                );
              },
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
                      // Drawer Menu Button
                      Builder(
                        builder: (context) => IconButton(
                          icon: Icon(Icons.menu_rounded, color: AppColors.getTextPrimary(context), size: 26),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      // Center Title & Subtitle
                      Expanded(
                        child: Obx(
                          () => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _controller.appBarTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: AppColors.getTextPrimary(context),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (_controller.appBarSubtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                _LoopingMarqueeSubtitle(
                                  text: _controller.appBarSubtitle,
                                  isDark: isDark,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // End Session Button
                      IconButton(
                        icon: Icon(Icons.exit_to_app_rounded, color: AppColors.getTextPrimary(context), size: 24),
                        tooltip: 'End Session',
                        onPressed: () => _showEndSessionConfirmationDialog(context),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Bottom Pinned Glassmorphic Mic Section (Layer 3)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(context),
          ),
        ],
      ),
    );
  }

  // region Navigation Drawer (60% Glassmorphism)
  Widget _buildDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF0D0F15) : Colors.white).withValues(alpha: 0.60),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(
                right: BorderSide(
                  color: AppColors.getBorder(context).withValues(alpha: 0.60),
                  width: 1.0,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Get.back();
                        _controller.startNewChat();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.transparent
                              : Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                          border: isDark
                              ? Border.all(
                                  color: const Color(0xFF333B50).withValues(alpha: 0.60),
                                  width: 1.2,
                                )
                              : null,
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 20,
                              color: isDark ? const Color(0xFFE2E8F0) : AppColors.getTextPrimary(context),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "New Session",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDark ? const Color(0xFFE2E8F0) : AppColors.getTextPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "RECENTS",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextMuted(context),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Obx(
                        () => _controller.recentSessions.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                                child: Text(
                                  "No recent sessions",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.getTextMuted(context),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _controller.recentSessions.length,
                                itemBuilder: (context, index) {
                                  final session = _controller.recentSessions[index];
                                  final isSelected = session.id == _controller.selectedSessionId.value;
                                  final isEnglish = session.module.toLowerCase() == 'english' ||
                                      session.title.toLowerCase().contains('english');
                                  final svgAsset = isEnglish
                                      ? 'assets/svg/english-communication.svg'
                                      : 'assets/svg/interview.svg';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Get.back();
                                          _controller.loadSession(session.id, session.title);
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.only(left: 12, right: 4, top: 6, bottom: 6),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? (isDark
                                                    ? Colors.transparent
                                                    : Colors.white.withValues(alpha: 0.60))
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                            border: (isSelected && isDark)
                                                ? Border.all(
                                                    color: const Color(0xFF2E3547).withValues(alpha: 0.60),
                                                  )
                                                : null,
                                            boxShadow: (isSelected && !isDark)
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.03),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            children: [
                                              Opacity(
                                                opacity: isSelected ? 1.0 : 0.75,
                                                child: SvgPicture.asset(
                                                  svgAsset,
                                                  width: 20,
                                                  height: 20,
                                                  fit: BoxFit.contain,
                                                  colorFilter: ColorFilter.mode(
                                                    isSelected
                                                        ? (isDark ? const Color(0xFFE2E8F0) : AppColors.getTextPrimary(context))
                                                        : (isDark ? const Color(0xFF94A3B8) : AppColors.getTextSecondary(context)),
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  session.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                    color: isSelected
                                                        ? AppColors.getTextPrimary(context)
                                                        : AppColors.getTextSecondary(context),
                                                  ),
                                                ),
                                              ),
                                              Theme(
                                                data: Theme.of(context).copyWith(
                                                  highlightColor: Colors.transparent,
                                                  splashColor: Colors.transparent,
                                                ),
                                                child: PopupMenuButton<String>(
                                                  icon: Icon(
                                                    Icons.more_vert_rounded,
                                                    size: 18,
                                                    color: isSelected
                                                        ? AppColors.getTextPrimary(context)
                                                        : AppColors.getTextSecondary(context),
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    side: BorderSide(
                                                      color: AppColors.getBorder(context).withValues(alpha: 0.60),
                                                    ),
                                                  ),
                                                  color: isDark ? const Color(0xFF1E2330) : AppColors.getSurface(context),
                                                  elevation: 4,
                                                  onSelected: (val) {
                                                    if (val == 'rename') {
                                                      _showRenameSessionDialog(context, session);
                                                    } else if (val == 'delete') {
                                                      _controller.deleteSession(session.id);
                                                    }
                                                  },
                                                  itemBuilder: (context) => [
                                                    PopupMenuItem<String>(
                                                      value: 'rename',
                                                      height: 40,
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
                                                    const PopupMenuDivider(height: 1),
                                                    PopupMenuItem<String>(
                                                      value: 'delete',
                                                      height: 40,
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
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    Divider(color: AppColors.getBorder(context).withValues(alpha: 0.60), height: 32),
                    _buildDrawerItem(
                      context,
                      Icons.settings_outlined,
                      "Settings",
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.settings);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Rename Session Dialog for Chat Screen drawer
  void _showRenameSessionDialog(BuildContext context, RecentHistory session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController(text: session.title);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      builder: (BuildContext dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0D0F15) : Colors.white).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.getBorder(context).withValues(alpha: 0.60),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rename Session',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.getTextPrimary(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter a new name for this practice session:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                      fillColor: isDark
                          ? const Color(0xFF1C202C).withValues(alpha: 0.60)
                          : const Color(0xFFF1F5F9).withValues(alpha: 0.60),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      hintText: 'Session Title',
                      hintStyle: TextStyle(
                        color: AppColors.getTextMuted(context),
                        fontSize: 13,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.getBorder(context).withValues(alpha: 0.60),
                        ),
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
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.getTextSecondary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final newName = textController.text.trim();
                          if (newName.isNotEmpty) {
                            Navigator.of(dialogContext).pop();
                            _controller.renameSession(session.id, newName);
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
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.getTextPrimary(context)),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // endregion

  // region Chat Widget
  Widget _buildChatBubble(BuildContext context, ChatMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isUser;
    final isGenerating = message.isGenerating;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth > 600 ? 540.0 : screenWidth * 0.84;

    // Softened comfortable low-glare bubbles
    final userBubbleBg = isDark ? const Color(0xFF242938) : const Color(0xFF1E293B);
    final userBubbleBorder = isDark ? const Color(0xFF333B4F) : const Color(0xFF334155);
    final userBubbleFg = isDark ? const Color(0xFFE2E8F0) : Colors.white;

    final aiBubbleBg = isDark ? const Color(0xFF151821) : Colors.white;
    final aiBubbleBorder = isDark ? const Color(0xFF262B38) : const Color(0xFFE2E8F0);
    final aiBubbleFg = AppColors.getTextPrimary(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: Container(
              padding: isGenerating
                  ? const EdgeInsets.symmetric(horizontal: 18, vertical: 14)
                  : const EdgeInsets.fromLTRB(16, 12, 14, 10),
              decoration: BoxDecoration(
                color: isUser ? userBubbleBg : aiBubbleBg,
                borderRadius: isUser
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(6),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(6),
                        bottomRight: Radius.circular(20),
                      ),
                border: Border.all(
                  color: isUser ? userBubbleBorder : aiBubbleBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isGenerating
                  ? _ThreeDotLoadingIndicator(isDark: isDark)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Message Text Body
                        Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.48,
                            letterSpacing: -0.1,
                            fontWeight: FontWeight.w400,
                            color: isUser ? userBubbleFg : aiBubbleFg,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Footer: Timestamp & Action Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.timeFormatted,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isUser
                                    ? userBubbleFg.withValues(alpha: 0.6)
                                    : AppColors.getTextMuted(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (isUser) {
                                    _controller.deleteMessageAndSubsequent(message);
                                  } else {
                                    _controller.replayAiMessage(message);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: isUser
                                      ? SvgPicture.asset(
                                          'assets/svg/refresh.svg',
                                          width: 16,
                                          height: 16,
                                          fit: BoxFit.contain,
                                          colorFilter: ColorFilter.mode(
                                            userBubbleFg.withValues(alpha: 0.8),
                                            BlendMode.srcIn,
                                          ),
                                        )
                                      : Obx(
                                          () {
                                            final isSpeaking = _controller.isMessageSpeaking(message);
                                            return SvgPicture.asset(
                                              isSpeaking
                                                  ? 'assets/svg/volume-up.svg'
                                                  : 'assets/svg/volume-mute.svg',
                                              width: 16,
                                              height: 16,
                                              fit: BoxFit.contain,
                                              colorFilter: ColorFilter.mode(
                                                AppColors.getTextSecondary(context),
                                                BlendMode.srcIn,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
  // endregion

  // region Voice Controls Section (60% Glassmorphism)
  Widget _buildBottomControls(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0D0F15) : Colors.white).withValues(alpha: 0.60),
            border: Border(
              top: BorderSide(
                color: AppColors.getBorder(context).withValues(alpha: 0.60),
                width: 1.0,
              ),
            ),
          ),
          child: Obx(() {
            final isAuto = _controller.isAutoMode.value;
            final state = _controller.currentState.value;

            String statusText;
            if (isAuto) {
              if (state == VoiceState.listening) {
                statusText = "Listening...";
              } else if (state == VoiceState.aiSpeaking) {
                statusText = "AI is speaking...";
              } else if (state == VoiceState.processing) {
                statusText = "AI is thinking...";
              } else {
                statusText = "Hold mic 3s for Manual";
              }
            } else {
              if (state == VoiceState.listening) {
                statusText = "Listening...";
              } else if (state == VoiceState.aiSpeaking) {
                statusText = "AI is speaking...";
              } else if (state == VoiceState.processing) {
                statusText = "AI is thinking...";
              } else {
                statusText = "Tap to Speak (Hold for Auto)";
              }
            }

            return Container(
              padding: EdgeInsets.only(top: 14, bottom: 16 + bottomPadding, left: 24, right: 24),
              child: Column(
                children: [
                  // Active Mode Pill & Status Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C202C).withValues(alpha: 0.60)
                              : const Color(0xFFF1F5F9).withValues(alpha: 0.60),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF262B38).withValues(alpha: 0.60)
                                : const Color(0xFFE2E8F0).withValues(alpha: 0.60),
                          ),
                        ),
                        child: Text(
                          isAuto ? "Auto Live" : "Manual",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Mic Action Button with 3s hold progress
                  _HoldToSwitchMicButton(controller: _controller),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
  // endregion

  // region Live Speech Widget
  Widget _buildLiveSpeechBubble(BuildContext context, String text) {
    final isEmpty = text == "...";
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth > 600 ? 540.0 : screenWidth * 0.84;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleBg = isDark ? const Color(0xFF242938) : const Color(0xFF1E293B);
    final bubbleFg = isDark ? const Color(0xFFE2E8F0) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleBg.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
                border: Border.all(
                  color: isDark ? const Color(0xFF333B4F) : const Color(0xFF334155),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _PulsingMicIndicator(),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isEmpty ? "Listening..." : text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        letterSpacing: -0.1,
                        color: isEmpty
                            ? bubbleFg.withValues(alpha: 0.6)
                            : bubbleFg,
                        fontStyle: FontStyle.italic,
                        fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // region End Session Confirmation Dialog (60% Glassmorphism)
  void _showEndSessionConfirmationDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      builder: (BuildContext dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Obx(() {
            final isAvailable = _controller.isReviewAvailable;
            final count = _controller.messageCount;

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 310),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0D0F15) : Colors.white).withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.getBorder(context).withValues(alpha: 0.60),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Icon Badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6))
                            : (isDark ? const Color(0xFF2A1C1C) : const Color(0xFFFDF2F2)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isAvailable
                              ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                              : (isDark ? const Color(0xFF4C2828) : const Color(0xFFFCA5A5)),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        isAvailable ? Icons.check_outlined : Icons.warning,
                        size: 20,
                        color: isAvailable
                            ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB))
                            : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dialog Title
                    Text(
                      isAvailable ? 'Request Session Review' : 'End Practice Session?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.getTextPrimary(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Concise Message
                    Text(
                      isAvailable
                          ? 'Generate your AI performance evaluation report for this session.'
                          : 'You need at least 5 messages for AI review ($count/5 completed).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.getTextSecondary(context),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Message Count Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1E2330) : const Color(0xFFF1F5F9)).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.getBorder(context).withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAvailable ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                            size: 13,
                            color: isAvailable
                                ? const Color(0xFF10B981)
                                : (isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAvailable
                                ? '$count messages completed'
                                : '${5 - count} more needed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        // Left Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (!isAvailable) {
                                Navigator.of(dialogContext).pop();
                                Get.offAllNamed(AppRoutes.sessionSelection);
                              } else {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: !isAvailable
                                    ? (isDark ? const Color(0xFF4C2828) : const Color(0xFFFCA5A5))
                                    : AppColors.getBorder(context),
                                width: 1.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              isAvailable ? 'Keep Chatting' : 'Exit Session',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: !isAvailable
                                    ? (isDark ? Colors.redAccent : const Color(0xFFDC2626))
                                    : AppColors.getTextSecondary(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Right / Primary Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (isAvailable) {
                                Navigator.of(dialogContext).pop();
                                _controller.endSession();
                              } else {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF222736)
                                  : const Color(0xFF242936),
                              foregroundColor: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                                side: isDark
                                    ? const BorderSide(color: Color(0xFF333B50))
                                    : const BorderSide(color: Color(0xFF384054)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isAvailable ? 'Generate Review' : 'Continue Chat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
  // endregion
}

// region Pulsing Mic Indicator
class _PulsingMicIndicator extends StatefulWidget {
  const _PulsingMicIndicator();

  @override
  State<_PulsingMicIndicator> createState() => _PulsingMicIndicatorState();
}

class _PulsingMicIndicatorState extends State<_PulsingMicIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
// endregion

// region Three-Dot Loading Indicator
class _ThreeDotLoadingIndicator extends StatefulWidget {
  final bool isDark;
  const _ThreeDotLoadingIndicator({required this.isDark});

  @override
  State<_ThreeDotLoadingIndicator> createState() => _ThreeDotLoadingIndicatorState();
}

class _ThreeDotLoadingIndicatorState extends State<_ThreeDotLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final double rawVal = (_controller.value - delay) % 1.0;
            final double opacity = (rawVal < 0.5 ? (rawVal * 2) : (2 - rawVal * 2)).clamp(0.25, 1.0);
            final double translateY = (rawVal < 0.5 ? -rawVal * 6 : -(1 - rawVal) * 6).clamp(-3.0, 0.0);

            return Transform.translate(
              offset: Offset(0, translateY),
              child: Container(
                margin: EdgeInsets.only(right: index < 2 ? 5.0 : 0.0),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
// endregion

// region Hold-to-Switch Mic Button
class _HoldToSwitchMicButton extends StatefulWidget {
  final ChatController controller;

  const _HoldToSwitchMicButton({required this.controller});

  @override
  State<_HoldToSwitchMicButton> createState() => _HoldToSwitchMicButtonState();
}

class _HoldToSwitchMicButtonState extends State<_HoldToSwitchMicButton>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  final RxDouble _progress = 0.0.obs;
  bool _didTriggerHold = false;
  late AnimationController _rippleController;
  Worker? _stateWorker;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    if (widget.controller.currentState.value == VoiceState.listening) {
      _rippleController.repeat();
    }

    _stateWorker = ever(widget.controller.currentState, (VoiceState state) {
      if (state == VoiceState.listening) {
        if (!_rippleController.isAnimating) {
          _rippleController.repeat();
        }
      } else {
        if (_rippleController.isAnimating) {
          _rippleController.stop();
          _rippleController.reset();
        }
      }
    });
  }

  void _startHoldTimer() {
    _timer?.cancel();
    _didTriggerHold = false;
    _progress.value = 0.0;

    const totalMs = 3000;
    const intervalMs = 30;
    int elapsedMs = 0;

    _timer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      elapsedMs += intervalMs;
      _progress.value = (elapsedMs / totalMs).clamp(0.0, 1.0);

      if (elapsedMs >= totalMs) {
        timer.cancel();
        _didTriggerHold = true;
        _progress.value = 0.0;
        widget.controller.toggleModeHold3s();
      }
    });
  }

  void _cancelHoldTimer({bool isTap = true}) {
    _timer?.cancel();
    _timer = null;

    if (!_didTriggerHold && isTap) {
      _progress.value = 0.0;
      widget.controller.onMicTap();
    } else {
      _progress.value = 0.0;
    }
    _didTriggerHold = false;
  }

  @override
  void dispose() {
    _stateWorker?.dispose();
    _timer?.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  Widget _buildRippleRing(double offset, Color ringColor) {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        final double progress = (_rippleController.value + offset) % 1.0;
        final double curvedProgress = Curves.easeOutQuad.transform(progress);
        final double scale = 68.0 + (curvedProgress * 26.0);
        final double opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.4;
        final double radius = 22.0 + (curvedProgress * 6.0);

        return Container(
          width: scale,
          height: scale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: ringColor.withValues(alpha: opacity * 0.12),
            border: Border.all(
              color: ringColor.withValues(alpha: opacity),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = widget.controller.currentState.value;
      final isListening = state == VoiceState.listening;
      final isProcessing = state == VoiceState.processing;
      final currentProgress = _progress.value;

      final btnBg = const Color(0xFFDC2626);
      const iconColor = Colors.white;
      const rippleColor = Color(0xFFEF4444);

      return GestureDetector(
        onTapDown: (_) {
          if (!isProcessing) {
            _startHoldTimer();
          }
        },
        onTapUp: (_) {
          _cancelHoldTimer(isTap: true);
        },
        onTapCancel: () {
          _cancelHoldTimer(isTap: false);
        },
        child: SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle pulsing expanding ripple rings when user is speaking
              if (isListening) ...[
                _buildRippleRing(0.0, rippleColor),
                _buildRippleRing(0.5, rippleColor),
              ],

              // Rounded Square Progress Ring while holding for 3 seconds
              if (currentProgress > 0.0)
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _RoundedSquareProgressPainter(
                    progress: currentProgress,
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                    strokeWidth: 3.5,
                    radius: 26.0,
                  ),
                ),

              // Fixed Mic Rounded Square Button
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: btnBg,
                  boxShadow: [
                    if (isListening)
                      BoxShadow(
                        color: rippleColor.withValues(alpha: 0.45),
                        blurRadius: 18,
                        spreadRadius: 3,
                      )
                    else
                      BoxShadow(
                        color: btnBg.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    isListening ? 'assets/svg/stop.svg' : 'assets/svg/mic.svg',
                    colorFilter: const ColorFilter.mode(iconColor, BlendMode.srcIn),
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// region Rounded Square Progress Painter
class _RoundedSquareProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final double radius;

  _RoundedSquareProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 3.5,
    this.radius = 26.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, bgPaint);

    if (progress > 0.0) {
      final pathMetrics = path.computeMetrics().toList();
      if (pathMetrics.isNotEmpty) {
        final metric = pathMetrics.first;
        final totalLength = metric.length;
        final extractPath = metric.extractPath(0.0, totalLength * progress);

        final progressPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth;

        canvas.drawPath(extractPath, progressPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_RoundedSquareProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor;
}

// region Looping Marquee Subtitle
class _LoopingMarqueeSubtitle extends StatefulWidget {
  final String text;
  final bool isDark;

  const _LoopingMarqueeSubtitle({
    required this.text,
    required this.isDark,
  });

  @override
  State<_LoopingMarqueeSubtitle> createState() => _LoopingMarqueeSubtitleState();
}

class _LoopingMarqueeSubtitleState extends State<_LoopingMarqueeSubtitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _LoopingMarqueeSubtitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.reset();
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A),
    );

    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final textWidth = textPainter.width;
    const gap = 36.0;
    final totalSpan = textWidth + gap;

    final screenWidth = MediaQuery.of(context).size.width;
    final maxPillWidth = (screenWidth * 0.72).clamp(220.0, 320.0);
    final contentWidth = textWidth > (maxPillWidth - 20) ? (maxPillWidth - 20) : textWidth;

    return Container(
      constraints: BoxConstraints(maxWidth: maxPillWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C202C).withValues(alpha: 0.60)
            : const Color(0xFFF1F5F9).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? const Color(0xFF262B38).withValues(alpha: 0.60)
              : const Color(0xFFE2E8F0).withValues(alpha: 0.60),
          width: 1,
        ),
      ),
      child: Center(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: ClipRect(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.09, 0.91, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              width: contentWidth,
              height: textPainter.height,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  // Smooth Right-to-Left circular looping offset
                  final currentOffset = _controller.value * totalSpan;

                  return Stack(
                    alignment: Alignment.centerLeft,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -currentOffset - totalSpan,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            widget.text,
                            style: textStyle,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -currentOffset,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            widget.text,
                            style: textStyle,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -currentOffset + totalSpan,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            widget.text,
                            style: textStyle,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -currentOffset + (2 * totalSpan),
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            widget.text,
                            style: textStyle,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// endregion

