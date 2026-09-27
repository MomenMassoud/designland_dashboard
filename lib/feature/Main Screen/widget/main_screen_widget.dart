import 'package:dashboard_desginland/Core/Utils/app.images.dart';
import 'package:dashboard_desginland/Core/server/check_promo_code.dart';
import 'package:dashboard_desginland/feature/About/view/about_view.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:dashboard_desginland/feature/Banners/view/banners_view.dart';
import 'package:dashboard_desginland/feature/Country/view/country_view.dart';
import 'package:dashboard_desginland/feature/Home/view/home_view.dart';
import 'package:dashboard_desginland/feature/Login/function/auth_function.dart';
import 'package:dashboard_desginland/feature/Orders/view/orders_view.dart';
import 'package:dashboard_desginland/feature/Profile/view/profile_view.dart';
import 'package:dashboard_desginland/feature/PromoCode/view/promo_code_view.dart';
import 'package:dashboard_desginland/feature/Staff/view/staff_view.dart';
import 'package:dashboard_desginland/feature/Users/view/users_view.dart';
import 'package:dashboard_desginland/feature/analytics/view/analytics_view.dart';
import 'package:dashboard_desginland/feature/products/view/products_view.dart';
import 'package:dashboard_desginland/model/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dashboard_desginland/feature/Category/view/category_view.dart';
import 'package:get/get.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/saveDeviceTokenToFirestore.dart';
import '../../../Core/server/setup_notification.dart';
import '../../Reports/view/report_view.dart';

class MainScreenWidget extends StatefulWidget {
  const MainScreenWidget({super.key});

  @override
  State<MainScreenWidget> createState() => _MainScreenWidgetState();
}

class _MainScreenWidgetState extends State<MainScreenWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserModel? _userModel;
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeView(),
    CategoryView(),
    OrdersView(),
    ReportView(),
    ProductsView(),
    StaffView(),
    UsersView(),
    AnalyticsView(),
    AboutView(),
    BannersView(),
    PromoCodeView(),
    CountryView(),
  ];

  @override
  void initState() {
    super.initState();
    _startProgram();
  }

  void _startProgram() async {
    _userModel = await GetCurrentUserData(context);
    if (!kIsWeb) {
      await setupAndroidNotifications();
    } else {
      await setupWeb();
    }
    await saveDeviceTokenToFirestore();
    await cleanAndFetchValidPromoCodes();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Get.isDarkMode;

    try {
      if (_userModel == null) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryPurple),
          ),
        );
      }

      if (_userModel!.role != "admin" && _userModel!.role != "staff") {
        return AccessDefindView();
      }
    } catch (e) {
      print(e);
      LogoutMethod(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 800;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: isDark
              ? Theme.of(context).scaffoldBackgroundColor
              : AppColors.bgLight,
          drawer: isMobile
              ? Drawer(
            backgroundColor: Theme.of(context).cardColor,
            child: _buildSidebarContent(isDark),
          )
              : null,
          body: Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Row(
              children: [
                // إظهار الـ Sidebar الدائم فقط في الشاشات الكبيرة
                if (!isMobile) _buildSidebar(context, isDark),

                // منطقة المحتوى الرئيسي والهيدر العلوي
                Expanded(
                  child: Column(
                    children: [
                      _buildTopHeader(isMobile, isDark),

                      // Dynamic Body View
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _screens[_selectedIndex],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== SIDEBAR CONTAINER ====================
  Widget _buildSidebar(BuildContext context, bool isDark) {
    return Container(
      width: 260,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _buildSidebarContent(isDark),
    );
  }

  // ==================== SIDEBAR CONTENT ====================
  Widget _buildSidebarContent(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 45,
          backgroundImage: AssetImage(AppImages.appPLogo),
        ),
        const SizedBox(height: 16),
        Divider(
          height: 1,
          thickness: 0.5,
          color: isDark ? Colors.white24 : Colors.black12,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildNavItem(0, Icons.grid_view_rounded, "Home".tr, isDark),
              _buildNavItem(1, Icons.category_outlined, "Categories".tr, isDark),
              _buildNavItem(2, Icons.shopping_bag_outlined, "Orders".tr, isDark),
              _buildNavItem(3, Icons.bar_chart_rounded, "Reports".tr, isDark),
              _buildNavItem(4, Icons.inventory_2_outlined, "Products".tr, isDark),
              _buildNavItem(5, Icons.badge_outlined, "Staff".tr, isDark),
              _buildNavItem(6, Icons.people_alt_outlined, "Users".tr, isDark),
              _buildNavItem(7, Icons.analytics, "Analytics".tr, isDark),
              _buildNavItem(8, Icons.info_outline, "About".tr, isDark),
              _buildNavItem(9, Icons.imagesearch_roller, "Banners".tr, isDark),
              _buildNavItem(10, Icons.discount, "PromoCode".tr, isDark),
              _buildNavItem(11, Icons.language, "Country".tr, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title, bool isDark) {
    final isSelected = _selectedIndex == index;
    final unselectedTextColor = isDark ? Colors.white70 : AppColors.textDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isSelected
            ? const LinearGradient(
          colors: [AppColors.primaryPurple, Color(0xFF7C3AED)],
        )
            : null,
        color: isSelected ? null : Colors.transparent,
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: Icon(
            icon,
            color: isSelected ? Colors.white : AppColors.textMuted,
            size: 22,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : unselectedTextColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
            ),
          ),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
            // إغلاق الـ Drawer تلقائياً في الموبايل عند إختيار عنصر
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  // ==================== TOP HEADER WIDGET ====================
  Widget _buildTopHeader(bool isMobile, bool isDark) {
    return Container(
      margin: EdgeInsets.only(
        top: 16,
        right: 16,
        left: isMobile ? 16 : 0,
        bottom: 8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر فتح القائمة الجانبية في شاشات الموبايل
          if (isMobile)
            IconButton(
              icon: Icon(
                Icons.menu,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),

          // حقل البحث
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: "Search...".tr,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white : AppColors.textMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // بروفايل المستخدم وزر الخروج
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileView()),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryPurple,
                  child: Text(
                    _userModel!.Name.isNotEmpty
                        ? _userModel!.Name.characters.first
                        : "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isMobile) const SizedBox(width: 10),

                // إخفاء تفاصيل اسم المستخدم في الموبايل لتوفير المساحة
                if (!isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _userModel!.Name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      Text(
                        _userModel!.role,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(width: 8),

                // ==================== زر تغيير الثيم (Dark/Light Mode) ====================
                IconButton(
                  tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: isDark ? Colors.amber : AppColors.primaryPurple,
                  ),
                  onPressed: () {
                    Get.changeThemeMode(
                      isDark ? ThemeMode.light : ThemeMode.dark,
                    );
                    setState(() {});
                  },
                ),

                const SizedBox(width: 4),

                // زر التسجيل خروج
                IconButton(
                  onPressed: () async {
                    LogoutMethod(context);
                  },
                  icon: const Icon(
                    Icons.logout,
                    color: AppColors.lightPurpleGlow,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}