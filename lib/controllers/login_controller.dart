import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';

class LoginController extends GetxController {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isPasswordVisible = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // SharedPreferences Keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserIdentifier = 'user_identifier';

  // Credentials retrieved from .env
  String get _authEmail => dotenv.env['AUTH_EMAIL']?.trim() ?? '';
  String get _authPhone => dotenv.env['AUTH_PHONE']?.trim() ?? '';
  String get _authPassword => dotenv.env['AUTH_PASSWORD']?.trim() ?? '';

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void clearError() {
    if (errorMessage.value.isNotEmpty) {
      errorMessage.value = '';
    }
  }

  Future<void> login() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text.trim();

    clearError();

    // 1. Validation for empty inputs
    if (identifier.isEmpty) {
      errorMessage.value = 'Please enter your email or phone number.';
      return;
    }

    if (password.isEmpty) {
      errorMessage.value = 'Please enter your password.';
      return;
    }

    isLoading.value = true;

    // Simulate minor network auth delay for smooth UX
    await Future.delayed(const Duration(milliseconds: 300));

    // 2. Validate credentials against .env records
    final expectedEmail = _authEmail;
    final expectedPhone = _authPhone;
    final expectedPassword = _authPassword;

    final isEmailMatch = expectedEmail.isNotEmpty && identifier.toLowerCase() == expectedEmail.toLowerCase();
    final isPhoneMatch = expectedPhone.isNotEmpty && identifier == expectedPhone;
    final isPasswordMatch = expectedPassword.isNotEmpty && password == expectedPassword;

    if ((isEmailMatch || isPhoneMatch) && isPasswordMatch) {
      try {
        // Save session state into SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(keyIsLoggedIn, true);
        await prefs.setString(keyUserIdentifier, identifier);

        isLoading.value = false;
        errorMessage.value = '';
      } catch (e) {
        isLoading.value = false;
        errorMessage.value = 'Failed to save session. Please try again.';
        return;
      }

      try {
        // Navigate to session selection screen
        Get.offAllNamed(AppRoutes.sessionSelection);
      } catch (_) {
        // Handle navigation in test environment where Get router is not mounted
      }
    } else {
      isLoading.value = false;
      errorMessage.value = 'Invalid email/phone or password. Please try again.';
    }
  }

  void forgotPassword() {
  }

  void continueWithGoogle() {
  }

  void signUp() {
  }

  @override
  void onClose() {
    identifierController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
