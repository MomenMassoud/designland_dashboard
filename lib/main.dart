import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'Core/Utils/app_routes.dart';
import 'Core/Utils/app_themes.dart';
import 'Core/server/Firebase Messaging Service.dart';
import 'Core/widgets/app_transilate.dart';
import 'feature/Splash/View/splash_view.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة الواجهات والأنظمة الأساسية بالتوازي وبأسرع أداء
  await AppInitializer.initCoreServices();

  runApp(const MyApp());
}

/// طبقة تهيئة الخدمات لضمان Clean Code وسرعة التشغيل
abstract class AppInitializer {
  static Future<void> initCoreServices() async {
    // 1. إعداد واجهة النظام والـ Firebase بالتوازي
    await Future.wait([
      _setupSystemUI(),
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
    ]);

    // 2. تهيئة خدمات الإشعارات خلف الكواليس دون حجب إقلاع التطبيق
    _initDeferredServices();
  }

  static Future<void> _setupSystemUI() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  static void _initDeferredServices() {
    // تشغيل خدمة الإشعارات فوراً دون الانتظار (Non-blocking)
    FirebaseMessagingService.initialize().catchError((error) {
      debugPrint('FirebaseMessagingService Initialization Error: $error');
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceLocale = Get.deviceLocale ?? const Locale('en');

    return GetMaterialApp(
      title: 'DesignLand',
      debugShowCheckedModeBanner: false,

      // التدويل واللغات
      translations: AppTranslations(),
      locale: deviceLocale,
      fallbackLocale: const Locale('en', 'US'),

      // التوجيهات والمقارات
      initialRoute: SplashView.id,
      routes: appRoutes,

      // إعدادات الثيم
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,

      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}