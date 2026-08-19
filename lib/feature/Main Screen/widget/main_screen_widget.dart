import 'package:dashboard_desginland/Core/Utils/app.images.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:dashboard_desginland/feature/Home/view/home_view.dart';
import 'package:dashboard_desginland/feature/Login/function/auth_function.dart';
import 'package:dashboard_desginland/feature/Orders/view/orders_view.dart';
import 'package:dashboard_desginland/feature/Profile/view/profile_view.dart';
import 'package:dashboard_desginland/feature/Staff/view/staff_view.dart';
import 'package:dashboard_desginland/feature/Users/view/users_view.dart';
import 'package:dashboard_desginland/feature/products/view/products_view.dart';
import 'package:dashboard_desginland/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:dashboard_desginland/feature/Category/view/category_view.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../Reports/view/report_view.dart';

class MainScreenWidget extends StatefulWidget {
  const MainScreenWidget({super.key});

  @override
  State<MainScreenWidget> createState() => _MainScreenWidgetState();
}

class _MainScreenWidgetState extends State<MainScreenWidget> {
  UserModel? _userModel;
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    HomeView(),
    CategoryView(), // الشاشة الخاصة بك
    OrdersView(),
    ReportView(),
    ProductsView(),
    StaffView(),
    UsersView(),
  ];
  @override
  void initState() {
    super.initState();
    _StartProgram();
  }

  void _StartProgram()async{
    _userModel=await GetCurrentUserData(context);
    setState(() {
      _userModel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _userModel==null?Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    ): Scaffold(
      backgroundColor: AppColors.bgLight,
      body:_userModel!.role =="admin" || _userModel!.role=="staff" ?Row(
        children: [
          _buildSidebar(context),

          // 2. Main Content Area (منطقة المحتوى + الهيدر العلوي)
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(),

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
      ):AccessDefindView(),
    );
  }

  // ==================== SIDEBAR WIDGET ====================
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage(AppImages.appPLogo),
          ),

          const Divider(height: 1, thickness: 0.5, color: Colors.black12),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNavItem(0, Icons.grid_view_rounded, "Home"),
                _buildNavItem(1, Icons.category_outlined, "Categories"),
                _buildNavItem(2, Icons.shopping_bag_outlined, "Orders"),
                _buildNavItem(3, Icons.bar_chart_rounded, "Reports"),
                _buildNavItem(4, Icons.inventory_2_outlined, "Products"),
                _buildNavItem(5, Icons.badge_outlined, "Staff"),
                _buildNavItem(6, Icons.people_alt_outlined, "Users"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;

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
        color: Colors.transparent, // يمنع حجب تأثير الـ Splash
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
              color: isSelected ? Colors.white : AppColors.textDark,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
            ),
          ),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }


  // ==================== TOP HEADER WIDGET ====================
  Widget _buildTopHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Global Search Field
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Search anything...",
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          InkWell(
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  ProfileView()),
              );
            },
            child: Row(
              children: [
                 CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryPurple,
                  child: Text(
                    "${_userModel!.Name.characters.first}",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children:  [
                    Text(
                      "${_userModel!.Name}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      "${_userModel!.role}",
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                IconButton(onPressed: ()async{
                  LogoutMethod(context);
                },
                    icon: Icon(Icons.logout,color: AppColors.lightPurpleGlow,))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
