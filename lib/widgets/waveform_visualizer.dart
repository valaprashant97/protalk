import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';

/// GetX controller managing dynamic bar heights for the visualizer.
class WaveformVisualizerController extends GetxController {
  final RxList<double> heights = List.filled(7, 4.0).obs;
  Timer? _timer;
  final Random _random = Random();
  bool _isAnimating = false;

  void syncAnimation(bool isAnimating) {
    if (_isAnimating == isAnimating && (_timer != null) == isAnimating) return;
    _isAnimating = isAnimating;
    _timer?.cancel();

    if (isAnimating) {
      _timer = Timer.periodic(const Duration(milliseconds: 140), (_) {
        for (int i = 0; i < heights.length; i++) {
          heights[i] = _random.nextDouble() * 26 + 6;
        }
      });
    } else {
      heights.value = List.filled(7, 4.0);
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

/// [WaveformVisualizer] renders an animated audio visualizer bar sequence.
/// It animates 7 vertical bars randomly when [isAnimating] is true using GetX state management.
class WaveformVisualizer extends StatelessWidget {
  /// Controls whether the bar heights animate dynamically or remain idle (dots/small bars).
  final bool isAnimating;

  /// Optional height for the visualizer container (default: 36.0)
  final double height;

  /// Optional active color for animated bars (defaults to secondary/accent)
  final Color? activeColor;

  /// Optional idle color for static dots/bars (defaults to border/muted)
  final Color? idleColor;

  const WaveformVisualizer({
    super.key,
    required this.isAnimating,
    this.height = 36.0,
    this.activeColor,
    this.idleColor,
  });

  @override
  Widget build(BuildContext context) {
    final WaveformVisualizerController controller = Get.put(WaveformVisualizerController());
    controller.syncAnimation(isAnimating);

    final theme = Theme.of(context);
    final active = activeColor ?? theme.colorScheme.secondary;
    final idle = idleColor ?? AppColors.getBorder(context);

    return SizedBox(
      height: height,
      child: Obx(() {
        controller.syncAnimation(isAnimating);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 4.5,
              height: controller.heights[index],
              decoration: BoxDecoration(
                color: isAnimating ? active : idle,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      }),
    );
  }
}
