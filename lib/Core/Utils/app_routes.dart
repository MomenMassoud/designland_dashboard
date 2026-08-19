import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:dashboard_desginland/feature/Login/view/login_view.dart';
import 'package:dashboard_desginland/feature/Main%20Screen/view/main_screen_view.dart';
import 'package:flutter/material.dart';
import '../../feature/Splash/View/splash_view.dart';

Map<String, Widget Function(BuildContext)> appRoutes = {
  SplashView.id: (context) => const SplashView(),
  LoginView.id: (context) =>  LoginView(),
  MainScreenView.id: (context) =>  MainScreenView(),
  AccessDefindView.id: (context) =>  AccessDefindView(),
};
