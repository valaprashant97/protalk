import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';

class SplashController extends GetxController with GetSingleTickerProviderStateMixin {
  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  @override
  void onInit() {
    super.onInit();
    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: fadeController,
        curve: Curves.easeOut,
      ),
    );
    _startSplash();
  }

  Future<void> _startSplash() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (isClosed) return;

    await fadeController.forward();
    if (isClosed) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (isLoggedIn) {
        Get.offAllNamed(AppRoutes.sessionSelection);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (_) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    fadeController.dispose();
    super.onClose();
  }
}
