import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../controllers/review_controller.dart';
import '../core/constants/app_colors.dart';

class ReviewScreen extends GetView<ReviewController> {
  const ReviewScreen({super.key});

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
          // 1. Main Review Body (Layer 1 - Scrolls behind glass AppBar & blurred when loading)
          Positioned.fill(
            child: Obx(() {
              // State 1: Error Message
              if (controller.errorMessage.value.isNotEmpty) {
                return _buildErrorView(context, isDark, totalAppBarHeight, bottomPadding);
              }

              final reportData = controller.report.value;
              // State 2: Report Loaded
              if (reportData != null) {
                return _buildReportView(context, isDark, totalAppBarHeight, bottomPadding, reportData);
              }

              // State 3: Background placeholder while loading
              return _buildPlaceholderReport(context, isDark, totalAppBarHeight, bottomPadding);
            }),
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
                    color: (isDark ? const Color(0xFF0D0F15) : Colors.white).withValues(alpha: 0.80),
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
                        tooltip: 'Remaining Chat',
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Get.back();
                          } else {
                            controller.resumeChat();
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Performance Review',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.getTextPrimary(context),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.share_outlined,
                          color: AppColors.getTextPrimary(context),
                          size: 22,
                        ),
                        tooltip: 'Share Review',
                        onPressed: controller.shareReport,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Full-Screen Modal Blur Dialog Overlay (Layer 3 - Styled like "Request Session Review" dialog)
          Positioned.fill(
            child: Obx(() {
              final showOverlay = controller.isLoading.value && controller.report.value == null && controller.errorMessage.value.isEmpty;
              if (!showOverlay) {
                return const SizedBox.shrink();
              }

              return ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: _buildAnalyzingDialogCard(context, isDark),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // region Glassmorphic Loading Dialog Card (Styled like "Request Session Review" dialog)
  Widget _buildAnalyzingDialogCard(BuildContext context, bool isDark) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: Lottie.asset(
                'assets/animations/loading.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Analyzing Complete Session',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.getTextPrimary(context),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Generating AI evaluation report...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // endregion

  // region Error View
  Widget _buildErrorView(
    BuildContext context,
    bool isDark,
    double totalAppBarHeight,
    double bottomPadding,
  ) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: totalAppBarHeight + 20,
          bottom: 24 + bottomPadding,
          left: 24,
          right: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 44,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(context),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: controller.newChat,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.getBorder(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'New Chat',
                      style: TextStyle(color: AppColors.getTextPrimary(context)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: controller.resumeChat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF222736) : const Color(0xFF242936),
                      foregroundColor: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isDark ? const BorderSide(color: Color(0xFF333B50)) : const BorderSide(color: Color(0xFF384054)),
                      ),
                    ),
                    child: const Text('Remaining Chat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  // endregion

  // region Report View
  Widget _buildReportView(
    BuildContext context,
    bool isDark,
    double totalAppBarHeight,
    double bottomPadding,
    SessionReport reportData,
  ) {
    final isInterview = reportData.module == 'interview';

    return SingleChildScrollView(
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
              // Overall Score Card
              _buildOverallScoreCard(context, reportData.overallScore),
              const SizedBox(height: 24),

              // Section Title
              Text(
                isInterview ? 'INTERVIEW ASSESSMENT METRICS' : 'ENGLISH CONVERSATION METRICS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.getTextMuted(context),
                ),
              ),
              const SizedBox(height: 12),

              // Render dynamic metrics
              ...reportData.metrics.map(
                (metric) => Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: _buildMetricBar(context, metric.name, metric.score),
                ),
              ),
              const SizedBox(height: 24),

              // Key Strengths Section (dynamically displayed when strengths exist)
              if (reportData.strengths.isNotEmpty) ...[
                Text(
                  'KEY STRENGTHS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.getTextMuted(context),
                  ),
                ),
                const SizedBox(height: 12),
                ...reportData.strengths.map((strength) => _buildStrengthTile(context, strength)),
                const SizedBox(height: 24),
              ],

              // Areas to Improve Section (dynamically displayed when areas exist)
              if (reportData.areasToImprove.isNotEmpty) ...[
                Text(
                  'AREAS TO IMPROVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.getTextMuted(context),
                  ),
                ),
                const SizedBox(height: 12),
                ...reportData.areasToImprove.map((item) => _buildAreaToImproveCard(context, item)),
                const SizedBox(height: 24),
              ],

              // Improvement Tips Section (dynamically displayed when tips exist)
              if (reportData.improvementTips.isNotEmpty) ...[
                Text(
                  'ACTIONABLE IMPROVEMENT TIPS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.getTextMuted(context),
                  ),
                ),
                const SizedBox(height: 12),
                ...reportData.improvementTips.map((tipItem) => _buildImprovementTipCard(context, tipItem)),
                const SizedBox(height: 32),
              ],

              // Action Buttons: New Chat & Remaining Chat
              Row(
                children: [
                  // New Chat -> Session Selection Screen
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: controller.newChat,
                        label: Text(
                          'New Chat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.getBorder(context),
                            width: 1.2,
                          ),
                          backgroundColor: AppColors.getSurface(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Remaining Chat -> Chat Screen (Resume Conversation)
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: controller.resumeChat,
                        label: Text(
                          'Remaining',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF222736) : const Color(0xFF242936),
                          foregroundColor: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isDark ? const BorderSide(color: Color(0xFF333B50)) : const BorderSide(color: Color(0xFF384054)),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  // endregion

  // region Placeholder Report View (Shown blurred behind analyzing dialog)
  Widget _buildPlaceholderReport(
    BuildContext context,
    bool isDark,
    double totalAppBarHeight,
    double bottomPadding,
  ) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
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
              _buildOverallScoreCard(context, 8.5),
              const SizedBox(height: 24),
              Text(
                'PERFORMANCE ASSESSMENT METRICS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.getTextMuted(context),
                ),
              ),
              const SizedBox(height: 12),
              _buildMetricBar(context, 'Grammar Accuracy', 85),
              const SizedBox(height: 10),
              _buildMetricBar(context, 'Fluency & Pacing', 90),
              const SizedBox(height: 10),
              _buildMetricBar(context, 'Vocabulary Range', 80),
              const SizedBox(height: 10),
              _buildMetricBar(context, 'Pronunciation Clarity', 88),
              const SizedBox(height: 24),
              Text(
                'KEY STRENGTHS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.getTextMuted(context),
                ),
              ),
              const SizedBox(height: 12),
              _buildStrengthTile(context, 'Clear speech modulation and natural response pacing.'),
            ],
          ),
        ),
      ),
    );
  }
  // endregion

  Widget _buildOverallScoreCard(BuildContext context, double overallScore) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String performanceTier = 'Good Effort';
    if (overallScore >= 9.0) {
      performanceTier = 'Outstanding';
    } else if (overallScore >= 8.0) {
      performanceTier = 'Very Good';
    } else if (overallScore >= 7.0) {
      performanceTier = 'Proficient';
    }

    final cardBg = isDark ? const Color(0xFF1B1F2C) : AppColors.getSurface(context);
    final cardBorder = isDark ? const Color(0xFF2E3547) : AppColors.getBorder(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242A3B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF38425C) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              performanceTier,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Overall Score',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.getTextSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${overallScore.toStringAsFixed(1)} / 10',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: isDark ? const Color(0xFFE2E8F0) : AppColors.getTextPrimary(context),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Grounded in your actual conversation turns and speech patterns.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF64748B) : AppColors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBar(BuildContext context, String label, int value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF262B38) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  '$value%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF222736) : AppColors.getBorder(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthTile(BuildContext context, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_outlined,
            color: AppColors.getTextPrimary(context),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.getTextPrimary(context),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaToImproveCard(BuildContext context, FeedbackItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.insights_sharp,
            size: 20,
            color: AppColors.getTextPrimary(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getTextSecondary(context),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementTipCard(BuildContext context, ImprovementTipItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191D28) : AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF282F40) : AppColors.getBorder(context),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 20,
            color: AppColors.getTextPrimary(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.tip,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getTextPrimary(context),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
