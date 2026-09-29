import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../Main Screen/view/main_screen_view.dart';
import '../function/auth_function.dart';
import 'login_desktop_branding.dart';
import 'login_form.dart';
import 'login_mobile_header.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final success = await LoginFunction(
          context,
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (success && mounted) {
          TextInput.finishAutofillContext();
          Navigator.pushReplacementNamed(context, MainScreenView.id);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Get.isDarkMode;
    // نفس ألوان وتنسيقات MainScreenWidget تماماً
    final scaffoldBg = isDark ? const Color(0xFF121218) : const Color(0xFFF4F5F9);
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isDesktop = constraints.maxWidth > 850;

                  return Container(
                    constraints: const BoxConstraints(maxWidth: 980),
                    height: isDesktop ? 580 : null,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: isDesktop
                        ? Row(
                      children: [
                        Expanded(child: LoginDesktopBranding(isDark: isDark)),
                        Expanded(
                          child: LoginForm(
                            isDesktop: true,
                            isDark: isDark,
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            isLoading: _isLoading,
                            onLoginPressed: _handleLogin,
                          ),
                        ),
                      ],
                    )
                        : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LoginMobileHeader(isDark: isDark),
                        LoginForm(
                          isDesktop: false,
                          isDark: isDark,
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          isLoading: _isLoading,
                          onLoginPressed: _handleLogin,
                        ),
                      ],
                    ),
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