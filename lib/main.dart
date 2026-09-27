import 'package:dashboard_desginland/Core/Utils/app.colors.dart';
import 'package:dashboard_desginland/Core/Utils/app_themes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'Core/Utils/app_routes.dart';
import 'Core/server/Firebase Messaging Service.dart';
import 'Core/widgets/app_transilate.dart';
import 'feature/Splash/View/splash_view.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessagingService.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceLocale = Get.deviceLocale ?? const Locale('en');

    return GetMaterialApp(
      onGenerateRoute: (setting) {
        return GetPageRoute(routeName: SplashView.id);
      },

      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return child ?? const SizedBox();
      },
      title: 'DesignLand',
      translations: AppTranslations(),
      locale: deviceLocale,
      initialRoute: SplashView.id,
      routes: appRoutes,
      fallbackLocale: const Locale('en', 'US'),

      // --- إعدادات الثيم ---
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system, // يعتمد افتراضيًا على وضع الجهاز (Light/Dark)
    );
  }
}