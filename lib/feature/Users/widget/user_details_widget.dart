import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(userData['name'] ?? 'User Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. البيانات الأساسية للمستخدم
            _buildBasicInfoCard(),
            const SizedBox(height: 20),

            // 2. بيانات العناوين ورقم الهاتف من كوليكشن 'users'
            _buildAddressesSection(),
            const SizedBox(height: 20),

            // 3. سجل الجلسات والزيارات من 'analytics_sessions'
            _buildSessionsSection(context),
          ],
        ),
      ),
    );
  }

  // كارت البيانات الأساسية
  Widget _buildBasicInfoCard() {
    final String name = userData['name'] ?? 'N/A';
    final String email = userData['email'] ?? 'N/A';
    final String imageUrl = userData['image'] ?? userData['profilePic'] ?? '';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // قسم العناوين ورقم التواصل
  Widget _buildAddressesSection() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildSectionContainer(
            title: "Addresses & Contact",
            child: const Text("No additional details found in 'users' collection."),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String phone = data['phone'] ?? 'N/A';
        final List addresses = data['addresses'] as List? ?? [];

        return _buildSectionContainer(
          title: "Addresses & Contact",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: AppColors.primaryPurple),
                  const SizedBox(width: 8),
                  Text("Phone: $phone", style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const Divider(height: 24),
              const Text(
                "Saved Addresses:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              if (addresses.isEmpty)
                const Text("No saved addresses.", style: TextStyle(color: AppColors.textMuted))
              else
                Column(
                  children: addresses.map((addr) {
                    final map = addr as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.redAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  map['title'] ?? 'Address',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  map['details'] ?? '',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                ),
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
    return _buildSectionContainer(
      title: "Visit History (Analytics)",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('analytics_sessions')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Text("No activity sessions logged for this user.");
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
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.1),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Started: $startTimeStr | Platform: ${platform.toUpperCase()}",
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                                    style: const TextStyle(fontSize: 11, color: Colors.blue),
                                  ),
                                  backgroundColor: Colors.blue.shade50,
                                ),
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  labelPadding: EdgeInsets.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  label: Text(
                                    "${viewedProducts.length} Products Viewed",
                                    style: const TextStyle(fontSize: 11, color: Colors.deepOrange),
                                  ),
                                  backgroundColor: Colors.orange.shade50,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
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

  // النافذة المنبثقة مع استخراج productId الصافي من الـ Map
  void _showSessionDetailsDialog(BuildContext context, String docId, Map<String, dynamic> session) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.analytics_outlined, color: AppColors.primaryPurple),
            SizedBox(width: 8),
            Text("Session Overview"),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow("Session ID", session['sessionId'] ?? docId),
                _buildDetailRow("Platform", (session['platform'] ?? 'N/A').toString().toUpperCase()),
                _buildDetailRow("Is Guest", (session['isGuest'] ?? false).toString()),
                _buildDetailRow("Start Time", startTimeStr),
                _buildDetailRow("Last Active", lastActiveStr),
                const Divider(height: 24),

                // Visited Tabs Section
                const Text(
                  "Visited Tabs",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                visitedTabs.isEmpty
                    ? const Text("No tabs recorded.", style: TextStyle(color: AppColors.textMuted))
                    : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: visitedTabs
                      .map((tab) => Chip(
                    label: Text(tab.toString()),
                    backgroundColor: Colors.purple.shade50,
                    side: BorderSide(color: Colors.purple.shade100),
                  ))
                      .toList(),
                ),

                const Divider(height: 24),

                // Viewed Products Section (استخراج productId و title بأمان)
                const Text(
                  "Viewed Products (Click to inspect)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                viewedProducts.isEmpty
                    ? const Text("No products viewed in this session.", style: TextStyle(color: AppColors.textMuted))
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
                        color: Colors.grey.shade50,
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
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_bag_outlined, color: Colors.orangeAccent, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    productTitle.isNotEmpty ? productTitle : "Product ID: $productIdStr",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
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
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }
}