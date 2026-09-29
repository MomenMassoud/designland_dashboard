import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/get_permision.dart';
import '../../../Core/server/order_service.dart';
import '../../../Core/server/user_service.dart';
import '../../Access Defind/view/access_defind_view.dart';
import 'create_manual_order_view.dart';
import 'order_card.dart';

class OrdersWidget extends StatefulWidget {
  const OrdersWidget({super.key});

  @override
  State<OrdersWidget> createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends State<OrdersWidget> with SingleTickerProviderStateMixin {
  final List<String> _statuses = const ['pending', 'shipping', 'completed', 'cancelled'];
  final List<String> _tabs = const ['All', 'Pending', 'Shipping', 'Completed', 'Cancelled'];

  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final OrderService _orderService = OrderService();
  final UserService _userService = UserService();

  List<String> _permision = [];
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _start();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _start() async {
    _permision = await GetPermisionUser();
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_permision.contains("orders")) return AccessDefindView();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : AppColors.bgLight;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedTextColor = isDark ? Colors.grey[400] : AppColors.textMuted;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text("Orders & Financial Management", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text("Create Manual Order", style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateManualOrderPage(),
                  ),
                );
              },
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: mutedTextColor,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: surfaceColor,
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Search by Order # or Customer Name...",
                hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryPurple),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: mutedTextColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5)),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tabFilter) => _buildOrdersList(tabFilter, isDark)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String filterStatus, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedTextColor = isDark ? Colors.grey[400] : AppColors.textMuted;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collectionGroup('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: textColor)));
        }

        var docs = snapshot.data?.docs ?? [];

        // 1. تصفية التبويب
        if (filterStatus != 'All') {
          docs = docs.where((doc) {
            final status = (doc.data()['status'] ?? 'pending').toString().toLowerCase();
            return status == filterStatus.toLowerCase();
          }).toList();
        }

        // 2. تصفية البحث السريع
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data();
            final orderNumber = (data['orderNumber'] ?? '').toString().toLowerCase();
            final orderId = doc.id.toLowerCase();
            final userId = data['userId'] ?? doc.reference.parent.parent?.id ?? '';

            String customerName = (data['customerName'] ?? '').toString().toLowerCase();

            final selectedAddress = data['selectedAddress'];
            if (selectedAddress is Map) {
              final fullName = (selectedAddress['fullName'] ?? selectedAddress['name'] ?? '').toString().toLowerCase();
              if (fullName.isNotEmpty) customerName = fullName;
            }

            final cachedName = _userService.getCachedName(userId);
            if (cachedName != null) {
              customerName = cachedName.toLowerCase();
            }

            return orderNumber.contains(_searchQuery) ||
                orderId.contains(_searchQuery) ||
                customerName.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                _searchQuery.isNotEmpty
                    ? "No orders found matching '$_searchQuery'"
                    : "No $filterStatus orders found.",
                style: TextStyle(color: mutedTextColor, fontSize: 15),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return OrderCard(
              key: ValueKey(docs[index].id),
              orderDoc: docs[index],
              isDark: isDark,
              orderService: _orderService,
              userService: _userService,
              statuses: _statuses,
            );
          },
        );
      },
    );
  }
}