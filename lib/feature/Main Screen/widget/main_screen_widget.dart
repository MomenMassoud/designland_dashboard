import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/saveDeviceTokenToFirestore.dart';
import '../../../Core/server/setup_notification.dart';
import 'package:dashboard_desginland/Core/Utils/app.images.dart';
import 'package:dashboard_desginland/Core/server/check_promo_code.dart';
import 'package:dashboard_desginland/feature/About/view/about_view.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:dashboard_desginland/feature/Banners/view/banners_view.dart';
import 'package:dashboard_desginland/feature/Category/view/category_view.dart';
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
import 'package:dashboard_desginland/feature/Top Fans/view/top_fans_view.dart';
import 'package:dashboard_desginland/model/user_model.dart';
import '../../Reports/view/report_view.dart';

class MainScreenWidget extends StatefulWidget {
  const MainScreenWidget({super.key});

  @override
  State<MainScreenWidget> createState() => _MainScreenWidgetState();
}

class _MainScreenWidgetState extends State<MainScreenWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  UserModel? _userModel;
  bool _isLoading = true;
  int _selectedIndex = 0;

  final Map<int, Widget> _loadedScreens = {};

  @override
  void initState() {
    super.initState();
    _startProgram();
  }

  Future<void> _startProgram() async {
    try {
      final user = await GetCurrentUserData(context);

      if (!mounted) return;

      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      _userModel = user;

      await Future.wait([
        kIsWeb ? setupWeb() : setupAndroidNotifications(),
        saveDeviceTokenToFirestore(),
        cleanAndFetchValidPromoCodes(),
      ]);
    } catch (e) {
      debugPrint('Error starting program: $e');
      if (mounted) LogoutMethod(context);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _getScreen(int index) {
    if (!_loadedScreens.containsKey(index)) {
      _loadedScreens[index] = _buildScreenByIndex(index);
    }
    return _loadedScreens[index]!;
  }

  Widget _buildScreenByIndex(int index) {
    switch (index) {
      case 0: return HomeView();
      case 1: return CategoryView();
      case 2: return OrdersView();
      case 3: return ReportView();
      case 4: return ProductsView();
      case 5: return StaffView();
      case 6: return UsersView();
      case 7: return TopFansView(); // إضافة شاشة كبار العملاء المربوطة بالسيكشن الجديد
      case 8: return AnalyticsView();
      case 9: return AboutView();
      case 10: return BannersView();
      case 11: return PromoCodeView();
      case 12: return CountryView();
      default: return HomeView();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPurple),
        ),
      );
    }

    if (_userModel == null || (_userModel!.role != "admin" && _userModel!.role != "staff")) {
      return AccessDefindView();
    }

    final bool isDark = Get.isDarkMode;
    final scaffoldBg = isDark ? const Color(0xFF121218) : const Color(0xFFF4F5F9);
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 800;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: scaffoldBg,
          drawer: isMobile
              ? Drawer(
            backgroundColor: cardBg,
            child: SidebarContent(
              selectedIndex: _selectedIndex,
              isDark: isDark,
              onItemSelected: _onNavItemTapped,
            ),
          )
              : null,
          body: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              children: [
                if (!isMobile)
                  Container(
                    width: 250,
                    margin: const EdgeInsets.all(12),
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
                    child: SidebarContent(
                      selectedIndex: _selectedIndex,
                      isDark: isDark,
                      onItemSelected: _onNavItemTapped,
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      TopHeader(
                        isMobile: isMobile,
                        isDark: isDark,
                        userModel: _userModel!,
                        scaffoldKey: _scaffoldKey,
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: List.generate(
                            13, // تحديث العدد الإجمالي للشاشات ليصبح 13
                                (index) => _getScreen(index),
                          ),
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

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }
}

// ==================== SIDEBAR COMPONENT WITH ANIMATION ====================
class SidebarContent extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onItemSelected;

  const SidebarContent({
    super.key,
    required this.selectedIndex,
    required this.isDark,
    required this.onItemSelected,
  });

  static final List<NavItemData> _navItems = [
    NavItemData(
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.space_dashboard_rounded,
      title: "Home",
    ),
    NavItemData(
      icon: Icons.category_outlined,
      activeIcon: Icons.category_rounded,
      title: "Categories",
    ),
    NavItemData(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
      title: "Orders",
    ),
    NavItemData(
      icon: Icons.bar_chart_rounded,
      activeIcon: Icons.insert_chart_rounded,
      title: "Reports",
    ),
    NavItemData(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      title: "Products",
    ),
    NavItemData(
      icon: Icons.badge_outlined,
      activeIcon: Icons.badge_rounded,
      title: "Staff",
    ),
    NavItemData(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_alt_rounded,
      title: "Users",
    ),
    NavItemData(
      icon: Icons.stars_outlined,
      activeIcon: Icons.stars_rounded,
      title: "Top Fans", // إضافة سيكشن Top Fans للقائمة الجانبية
    ),
    NavItemData(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
      title: "Analytics",
    ),
    NavItemData(
      icon: Icons.info_outline_rounded,
      activeIcon: Icons.info_rounded,
      title: "About",
    ),
    NavItemData(
      icon: Icons.view_carousel_outlined,
      activeIcon: Icons.view_carousel_rounded,
      title: "Banners",
    ),
    NavItemData(
      icon: Icons.confirmation_number_outlined,
      activeIcon: Icons.confirmation_number_rounded,
      title: "PromoCode",
    ),
    NavItemData(
      icon: Icons.public_outlined,
      activeIcon: Icons.public_rounded,
      title: "Country",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryPurple.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: const CircleAvatar(
            radius: 36,
            backgroundImage: AssetImage(AppImages.appPLogo),
          ),
        ),
        const SizedBox(height: 14),
        Divider(
          height: 1,
          thickness: 0.5,
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _navItems.length,
            itemBuilder: (context, index) {
              final item = _navItems[index];
              return NavItemTile(
                index: index,
                item: item,
                isSelected: selectedIndex == index,
                isDark: isDark,
                onTap: () => onItemSelected(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String title;

  const NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.title,
  });
}

class NavItemTile extends StatelessWidget {
  final int index;
  final NavItemData item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const NavItemTile({
    super.key,
    required this.index,
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedTextColor = isDark ? Colors.white70 : const Color(0xFF4B5563);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
              : null,
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Animate(
                    target: isSelected ? 1 : 0,
                    effects: [
                      ScaleEffect(
                        duration: 200.ms,
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1.1, 1.1),
                        curve: Curves.easeOutBack,
                      ),
                    ],
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF6B7280)),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title.tr,
                      style: TextStyle(
                        color: isSelected ? Colors.white : unselectedTextColor,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate()
                        .scale(duration: 200.ms, curve: Curves.easeOutBack),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== TOP HEADER COMPONENT ====================
class TopHeader extends StatelessWidget {
  final bool isMobile;
  final bool isDark;
  final UserModel userModel;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const TopHeader({
    super.key,
    required this.isMobile,
    required this.isDark,
    required this.userModel,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    return Container(
      margin: EdgeInsets.only(
        top: 12,
        right: 16,
        left: isMobile ? 16 : 0,
        bottom: 8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: textPrimary,
              ),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            ),
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: "Search...".tr,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileView()),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF6366F1),
                  child: Text(
                    userModel.Name.isNotEmpty
                        ? userModel.Name.characters.first.toUpperCase()
                        : "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userModel.Name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        userModel.role,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: isDark ? Colors.amber : const Color(0xFF6366F1),
                    size: 20,
                  ),
                  onPressed: () {
                    Get.changeThemeMode(
                      isDark ? ThemeMode.light : ThemeMode.dark,
                    );
                  },
                ),
                IconButton(
                  onPressed: () async => LogoutMethod(context),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}