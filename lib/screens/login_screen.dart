import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../core/constants/app_colors.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Tagline (Text only - No logo icon)
                  Text(
                    'PROTALK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Main Heading Title
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Sign in with your email or phone number to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getTextSecondary(context),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Dynamic Error Banner (Shown on invalid credentials / empty inputs)
                  Obx(() {
                    final error = controller.errorMessage.value;
                    if (error.isEmpty) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              error,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Email or Phone Number Input Field
                  TextField(
                    controller: controller.identifierController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => controller.clearError(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getTextPrimary(context),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email or Phone Number *',
                      hintText: 'Enter your email or phone number',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.getTextSecondary(context),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Password Input Field with Show/Hide Toggle
                  Obx(() {
                    final isVisible = controller.isPasswordVisible.value;
                    return TextField(
                      controller: controller.passwordController,
                      obscureText: !isVisible,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => controller.clearError(),
                      onSubmitted: (_) => controller.login(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextPrimary(context),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        hintText: 'Enter your password',
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.getTextSecondary(context),
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.getTextSecondary(context),
                            size: 20,
                          ),
                          tooltip: isVisible ? 'Hide password' : 'Show password',
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),

                  // Forgot Password Link (UI only)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: controller.forgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextPrimary(context),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign In Button
                  Obx(() {
                    final isLoading = controller.isLoading.value;
                    return ElevatedButton(
                      onPressed: isLoading ? null : controller.login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF222736) : Colors.black,
                        foregroundColor: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                        disabledBackgroundColor: isDark
                            ? const Color(0xFF1B1E29)
                            : const Color(0xFFE2E8F0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isDark
                              ? const BorderSide(color: Color(0xFF333B50))
                              : BorderSide.none,
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? const Color(0xFFE2E8F0) : Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                              ),
                            ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.getBorder(context),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.getTextMuted(context),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.getBorder(context),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Continue with Google Button (UI only)
                  OutlinedButton(
                    onPressed: controller.continueWithGoogle,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.getBorder(context),
                        width: 1.2,
                      ),
                      backgroundColor: AppColors.getSurface(context),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          child: Text(
                            'G',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.getTextPrimary(context),
                              fontFamily: 'sans-serif',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sign Up Link (UI only)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.signUp,
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(context),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
