import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Users/widget/user_favourite_product.dart';
import 'package:dashboard_desginland/feature/Users/widget/user_orders_deatils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/Utils/app.colors.dart';
import 'user_product_details_widget.dart';

class UserDetailView extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserDetailView({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final scaffoldBg = isDarkMode ? theme.scaffoldBackgroundColor : AppColors.bgLight;
    final appBarBg = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          userData['name'] ?? 'User Details',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: appBarBg,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. البيانات الأساسية للمستخدم
            _buildBasicInfoCard(context),
            const SizedBox(height: 20),

            // 2. بيانات العناوين ورقم الهاتف من كوليكشن 'users'
            _buildAddressesSection(context),
            const SizedBox(height: 20),

            // 3. سجل الجلسات والزيارات من 'analytics_sessions'
            _buildSessionsSection(context),
          ],
        ),
      ),
    );
  }

  // كارت البيانات الأساسية
  Widget _buildBasicInfoCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final String name = userData['name'] ?? 'N/A';
    final String email = userData['email'] ?? 'N/A';
    final String imageUrl = userData['image'] ?? userData['profilePic'] ?? '';

    final cardBg = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : AppColors.textMuted;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;

    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryPurple.withOpacity(0.15),
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty
                  ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(email, style: TextStyle(color: subtitleColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // قسم العناوين ورقم التواصل
  Widget _buildAddressesSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final cardBg = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : AppColors.textMuted;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final itemBg = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildSectionContainer(
            context: context,
            title: "Addresses & Contact",
            child: Text(
              "No additional details found in 'users' collection.",
              style: TextStyle(color: subtitleColor),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String phone = data['phone'] ?? 'N/A';
        final List addresses = data['addresses'] as List? ?? [];

        return _buildSectionContainer(
          context: context,
          title: "Addresses & Contact",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // كارت المنتجات المفضلة
              Card(
                color: cardBg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: borderColor),
                ),
                child: ListTile(
                  title: Text("Favourite Products", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text("Click to show user favourite products", style: TextStyle(color: subtitleColor)),
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                  onTap: () {
                    Get.to(() => UserFavouriteProduct(UserId: userId));
                  },
                ),
              ),
              const SizedBox(height: 8),

              // كارت طلبات المستخدم الجديد
              Card(
                color: cardBg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: borderColor),
                ),
                child: ListTile(
                  title: Text("User Orders", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text("Click to view all orders for this user", style: TextStyle(color: subtitleColor)),
                  leading: const Icon(Icons.shopping_cart, color: AppColors.primaryPurple),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                  onTap: () {
                    Get.to(() => UserOrdersDeatils(UserID: userId));
                  },
                ),
              ),

              Divider(height: 24, color: borderColor),
              Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: AppColors.primaryPurple),
                  const SizedBox(width: 8),
                  Text("Phone: $phone", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                ],
              ),
              Divider(height: 24, color: borderColor),
              Text(
                "Saved Addresses:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
              ),
              const SizedBox(height: 10),
              if (addresses.isEmpty)
                Text("No saved addresses.", style: TextStyle(color: subtitleColor))
              else
                Column(
                  children: addresses.map((addr) {
                    final map = addr as Map<String, dynamic>? ?? {};

                    final String fullName = map['fullName'] ?? map['name'] ?? '';
                    final String street = map['street'] ?? '';
                    final String building = map['building'] ?? '';
                    final String floor = map['floor'] ?? '';
                    final String apartment = map['apartment'] ?? '';
                    final String city = map['city'] ?? '';
                    final String governorate = map['governorate'] ?? '';
                    final String landmark = map['landmark'] ?? '';
                    final String addressPhone = map['phone'] ?? '';

                    List<String> detailsParts = [];
                    if (building.isNotEmpty) detailsParts.add("Building $building");
                    if (street.isNotEmpty) detailsParts.add("Street $street");
                    if (floor.isNotEmpty) detailsParts.add("Floor $floor");
                    if (apartment.isNotEmpty) detailsParts.add("Apt $apartment");
                    if (landmark.isNotEmpty) detailsParts.add("Near $landmark");
                    if (city.isNotEmpty) detailsParts.add(city);
                    if (governorate.isNotEmpty) detailsParts.add(governorate);

                    String addressDetailsStr = detailsParts.join(', ');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: itemBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.redAccent, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (fullName.isNotEmpty)
                                  Text(
                                    fullName,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                                  ),
                                if (addressDetailsStr.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    addressDetailsStr,
                                    style: TextStyle(color: textColor, fontSize: 13),
                                  ),
                                ],
                                if (addressPhone.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Phone: $addressPhone",
                                    style: TextStyle(color: subtitleColor, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  // قسم عرض الجلسات والزيارات من 'analytics_sessions'
  Widget _buildSessionsSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : AppColors.textMuted;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final itemBg = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;

    return _buildSectionContainer(
      context: context,
      title: "Visit History (Analytics)",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('analytics_sessions')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Text("No activity sessions logged for this user.", style: TextStyle(color: subtitleColor));
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final session = docs[index].data() as Map<String, dynamic>;
              final String sessionId = docs[index].id;
              final String platform = session['platform'] ?? 'Web';
              final List visitedTabs = session['visitedTabs'] as List? ?? [];
              final List viewedProducts = session['viewedProducts'] as List? ?? [];

              String startTimeStr = 'N/A';
              if (session['startTime'] is Timestamp) {
                DateTime dt = (session['startTime'] as Timestamp).toDate();
                startTimeStr =
                "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
              }

              return InkWell(
                onTap: () => _showSessionDetailsDialog(context, sessionId, session),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: itemBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          platform.toLowerCase() == 'web' ? Icons.language : Icons.phone_android,
                          color: AppColors.primaryPurple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Session: ${session['sessionId'] ?? sessionId}",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Started: $startTimeStr | Platform: ${platform.toUpperCase()}",
                              style: TextStyle(fontSize: 12, color: subtitleColor),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  labelPadding: EdgeInsets.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  label: Text(
                                    "${visitedTabs.length} Tabs Visited",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDarkMode ? Colors.lightBlue : Colors.blue.shade700,
                                    ),
                                  ),
                                  backgroundColor: isDarkMode ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50,
                                  side: BorderSide.none,
                                ),
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  labelPadding: EdgeInsets.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  label: Text(
                                    "${viewedProducts.length} Products Viewed",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange,
                                    ),
                                  ),
                                  backgroundColor: isDarkMode ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50,
                                  side: BorderSide.none,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // النافذة المنبثقة للـ Session
  void _showSessionDetailsDialog(BuildContext context, String docId, Map<String, dynamic> session) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final cardBg = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : AppColors.textMuted;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final itemBg = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;

    final List visitedTabs = session['visitedTabs'] as List? ?? [];
    final List viewedProducts = session['viewedProducts'] as List? ?? [];

    String startTimeStr = 'N/A';
    if (session['startTime'] is Timestamp) {
      DateTime dt = (session['startTime'] as Timestamp).toDate();
      startTimeStr =
      "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
    }

    String lastActiveStr = 'N/A';
    if (session['lastActiveTime'] is Timestamp) {
      DateTime dt = (session['lastActiveTime'] as Timestamp).toDate();
      lastActiveStr =
      "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.analytics_outlined, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            Text("Session Overview", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(context, "Session ID", session['sessionId'] ?? docId),
                _buildDetailRow(context, "Platform", (session['platform'] ?? 'N/A').toString().toUpperCase()),
                _buildDetailRow(context, "Is Guest", (session['isGuest'] ?? false).toString()),
                _buildDetailRow(context, "Start Time", startTimeStr),
                _buildDetailRow(context, "Last Active", lastActiveStr),
                Divider(height: 24, color: borderColor),

                // Visited Tabs Section
                Text(
                  "Visited Tabs",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                ),
                const SizedBox(height: 8),
                visitedTabs.isEmpty
                    ? Text("No tabs recorded.", style: TextStyle(color: subtitleColor))
                    : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: visitedTabs
                      .map((tab) => Chip(
                    label: Text(tab.toString(), style: TextStyle(color: isDarkMode ? Colors.purpleAccent : AppColors.primaryPurple)),
                    backgroundColor: isDarkMode ? Colors.purple.withOpacity(0.2) : Colors.purple.shade50,
                    side: BorderSide(color: isDarkMode ? Colors.purple.shade900 : Colors.purple.shade100),
                  ))
                      .toList(),
                ),

                Divider(height: 24, color: borderColor),

                // Viewed Products Section
                Text(
                  "Viewed Products (Click to inspect)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                ),
                const SizedBox(height: 8),
                viewedProducts.isEmpty
                    ? Text("No products viewed in this session.", style: TextStyle(color: subtitleColor))
                    : Column(
                  children: viewedProducts.map((pItem) {
                    String productIdStr = '';
                    String productTitle = '';

                    if (pItem is Map) {
                      productIdStr = pItem['productId']?.toString() ?? '';
                      productTitle = pItem['title']?.toString() ?? '';
                    } else {
                      productIdStr = pItem.toString();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: itemBg,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProductDetailsWidget(productId: productIdStr),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_bag_outlined, color: Colors.orangeAccent, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    productTitle.isNotEmpty ? productTitle : "Product ID: $productIdStr",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 12, color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: AppColors.primaryPurple)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String title, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: subtitleColor, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required BuildContext context, required String title, required Widget child}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final cardBg = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
          ),
          Divider(height: 20, color: borderColor),
          child,
        ],
      ),
    );
  }
}