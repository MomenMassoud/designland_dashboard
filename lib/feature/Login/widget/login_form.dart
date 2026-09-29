import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../ForgetPassword/view/forget_password_view.dart';

class LoginForm extends StatefulWidget {
  final bool isDesktop;
  final bool isDark;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onLoginPressed;

  const LoginForm({
    super.key,
    required this.isDesktop,
    required this.isDark,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onLoginPressed,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _isPasswordObscure = true;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF111827);
    final mutedTextColor = widget.isDark ? Colors.white54 : const Color(0xFF6B7280);
    final inputFillColor = widget.isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFFF3F4F6);
    final inputBorderColor = widget.isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isDesktop ? 40 : 20,
        vertical: widget.isDesktop ? 36 : 24,
      ),
      child: AutofillGroup(
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sign In".tr,
                style: TextStyle(
                  fontSize: widget.isDesktop ? 26 : 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Enter your credentials to access the admin panel".tr,
                style: TextStyle(
                  fontSize: 13,
                  color: mutedTextColor,
                ),
              ),
              SizedBox(height: widget.isDesktop ? 28 : 20),

              // Email Field
              TextFormField(
                controller: widget.emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email, AutofillHints.username],
                style: TextStyle(color: textColor, fontSize: 13.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputFillColor,
                  labelText: "Email Address".tr,
                  labelStyle: TextStyle(color: mutedTextColor, fontSize: 13),
                  hintText: "admin@designland.eg",
                  hintStyle: TextStyle(
                    color: widget.isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inputBorderColor),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 1.8,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter your email".tr;
                  }
                  if (!GetUtils.isEmail(value.trim())) {
                    return "Please enter a valid email".tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: widget.passwordController,
                obscureText: _isPasswordObscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => widget.onLoginPressed(),
                style: TextStyle(color: textColor, fontSize: 13.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputFillColor,
                  labelText: "Password".tr,
                  labelStyle: TextStyle(color: mutedTextColor, fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: const Color(0xFF9CA3AF),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordObscure = !_isPasswordObscure;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inputBorderColor),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 1.8,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your password".tr;
                  }
                  if (value.length < 6) {
                    return "Password must be at least 6 characters".tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.to(() => ForgetPasswordView()),
                  child: Text(
                    "Forgot Password?".tr,
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Login Button بنفس التدرج والإنيميشن الخفيف
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: widget.isLoading ? null : widget.onLoginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: widget.isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    "Login to Dashboard".tr,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }
}