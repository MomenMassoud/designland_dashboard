import 'package:dashboard_desginland/feature/Splash/Wedgit/splash_footer.dart';
import 'package:dashboard_desginland/feature/Splash/Wedgit/splash_logo_section.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../Core/Utils/app.images.dart';
import '../../Login/view/login_view.dart';
import '../../Main Screen/view/main_screen_view.dart';

class SplashViewBody extends StatefulWidget {
  const SplashViewBody({super.key});

  @override
  State<SplashViewBody> createState() => _SplashViewBodyState();
}

class _SplashViewBodyState extends State<SplashViewBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSplashSequence();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحميل الشعار مسبقاً في ذاكرة التخزين المؤقت لتجنب أي تأخير في العرض
    precacheImage(const AssetImage(AppImages.logo), context);
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.70, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  Future<void> _startSplashSequence() async {
    // التنفيذ الفوري بالتوازي مع مدة الأنيميشن السريعة (1.2 ثانية)
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1200)),
      // أي إعدادات سريعة أخرى يمكن تنفيذها هنا
    ]);

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final targetRoute = user != null ? MainScreenView.id : LoginView.id;

    Navigator.pushReplacementNamed(context, targetRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          alignment: Alignment.center,
          children: [
            // استخدام child ثابت لمنع Rebuilding المكونات أثناء الأنيميشن
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                child: const SplashLogoSection(),
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: child,
                      ),
                    ),
                  );
                },
              ),
            ),

            // النص السفلي بانيميشن الظهور الخفيف
            Positioned(
              bottom: 36,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const SplashFooter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}