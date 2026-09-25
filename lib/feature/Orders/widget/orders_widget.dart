import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/server/get_client_data.dart';
import 'package:dashboard_desginland/Core/server/sendCancelInvoiceEmail.dart';
import 'package:dashboard_desginland/Core/server/sendOrderConfirmationEmail.dart';
import 'package:dashboard_desginland/Core/server/sendOrderReadyEmail.dart';
import 'package:dashboard_desginland/Core/server/sendUserNotificationApi.dart';
import 'package:dashboard_desginland/Core/server/send_pending_email.dart';
import 'package:dashboard_desginland/Core/widgets/error_dailog_custom.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:dashboard_desginland/model/user_model.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/get_permision.dart';
import 'order_details_widget.dart';

class OrdersWidget extends StatefulWidget {
  const OrdersWidget({super.key});

  @override
  State<OrdersWidget> createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends State<OrdersWidget> with SingleTickerProviderStateMixin {
  final List<String> _statuses = ['pending', 'shipping', 'completed', 'cancelled'];
  final List<String> _tabs = ['All', 'Pending', 'Shipping', 'Completed', 'Cancelled'];

  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<String> _permision = [];
  String _searchQuery = '';

  // كاش لتخزين أسماء العملاء لتسريع عملية البحث وتجنب الاستعلامات المتكررة
  final Map<String, String> _userNamesCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _start();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _start() async {
    _permision = await GetPermisionUser();
    if (mounted) setState(() {});
  }

  void _saveNotification(String userID, String status, String orderID,String title,String body) async {
    try {
      await _firestore.collection('user').doc(userID).collection('notifications').add({
        'isRead': false,
        'body': body,
        "title": title,
        "targetUser": userID,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      showErrorDialog(context, "Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permision.contains("orders")) return  AccessDefindView();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text("Orders & Financial Management", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
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
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: Column(
        children: [
          // 🔍 شريط البحث برقم الطلب أو اسم العميل
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by Order # or Customer Name...",
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryPurple),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tabFilter) => _buildOrdersList(tabFilter)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String filterStatus) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collectionGroup('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        var docs = snapshot.data?.docs ?? [];

        // 1. تصفية التبويب (Tab Filter)
        if (filterStatus != 'All') {
          docs = docs.where((doc) {
            final status = (doc.data()['status'] ?? 'pending').toString().toLowerCase();
            return status == filterStatus.toLowerCase();
          }).toList();
        }

        // 2. تصفية البحث (Search Filter)
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data();
            final orderNumber = (data['orderNumber'] ?? '').toString().toLowerCase();
            final orderId = doc.id.toLowerCase();
            final userId = data['userId'] ?? doc.reference.parent.parent?.id ?? '';

            // جلب اسم العميل من الـ Manual Data أو من كاش أسماء العملاء
            String customerName = (data['customerName'] ?? '').toString().toLowerCase();

            // التحقق من عنوان Selected Address إن وجد
            final selectedAddress = data['selectedAddress'];
            if (selectedAddress is Map) {
              final fullName = (selectedAddress['fullName'] ?? selectedAddress['name'] ?? '').toString().toLowerCase();
              if (fullName.isNotEmpty) customerName = fullName;
            }

            // الاستعانة بالكاش لبيانات المستخدم المسجل
            if (_userNamesCache.containsKey(userId)) {
              customerName = _userNamesCache[userId]!.toLowerCase();
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
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final orderDoc = docs[index];
            final orderData = orderDoc.data();
            final String orderId = orderDoc.id;
            final String userId = orderData['userId'] ?? orderDoc.reference.parent.parent?.id ?? '';

            final String currentStatus = orderData['status'] ?? 'pending';
            final num totalPrice = orderData['totalPrice'] ?? 0;
            final List items = orderData['items'] as List? ?? [];
            final bool isManual = orderData['isManual'] ?? false;
            final int orderNumber = orderData['orderNumber'] ?? 0;

            String formattedDate = 'N/A';
            if (orderData['createdAt'] is Timestamp) {
              final dt = (orderData['createdAt'] as Timestamp).toDate();
              formattedDate = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
            }

            return Card(
              elevation: 0,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isManual ? Colors.orange.shade300 : Colors.grey.shade200),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailView(
                        orderId: orderId,
                        userId: userId,
                        orderData: orderData,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Order #${orderNumber != 0 ? orderNumber : orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              if (isManual) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    border: Border.all(color: Colors.orange.shade200),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text("Manual", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                )
                              ]
                            ],
                          ),
                          _buildStatusDropdown(userId, orderId, currentStatus, totalPrice, orderDoc.reference, orderNumber, orderData),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isManual && (orderData['customerName']?.toString().isNotEmpty ?? false)) ...[
                                Text(
                                  "Customer: ${orderData['customerName']}",
                                  style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
                                ),
                              ] else if (userId.isNotEmpty) ...[
                                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                  future: _firestore.collection('user').doc(userId).get(),
                                  builder: (context, userSnapshot) {
                                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                                      return Text(
                                        "Customer: ${_userNamesCache[userId] ?? 'Loading...'}",
                                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                      );
                                    }

                                    String userName = "Unknown User";
                                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                      final userData = userSnapshot.data!.data();

                                      // 1. البحث في حقل name المباشر
                                      if (userData?['name'] != null && userData!['name'].toString().isNotEmpty) {
                                        userName = userData['name'];
                                      }
                                      // 2. البحث داخل مصفوفة العناوين addresses[0]['fullName'] أو ['name']
                                      else if (userData?['addresses'] is List && (userData!['addresses'] as List).isNotEmpty) {
                                        final firstAddr = (userData['addresses'] as List).first;
                                        if (firstAddr is Map) {
                                          userName = firstAddr['fullName'] ?? firstAddr['name'] ?? userName;
                                        }
                                      }
                                      // 3. الحل الأخير
                                      else {
                                        userName = orderData['customerName'] ?? orderData['userEmail'] ?? userId;
                                      }
                                    } else {
                                      userName = orderData['customerName'] ?? orderData['userEmail'] ?? userId;
                                    }

                                    // حفظ الاسم في الكاش ليعمل معه شريط البحث تلقائياً
                                    _userNamesCache[userId] = userName;

                                    return Text(
                                      "Customer: $userName",
                                      style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
                                    );
                                  },
                                ),
                              ] else ...[
                                Text(
                                  "Customer: ${orderData['customerName'] ?? orderData['userEmail'] ?? 'Guest'}",
                                  style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text("Date: $formattedDate", style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text("${items.length} Item(s)", style: const TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Text("$totalPrice EGP", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusDropdown(String userId, String orderId, String currentStatus, num total, DocumentReference orderRef,
      int orderNumber, Map<String, dynamic> orderData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: _getStatusBgColor(currentStatus), borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statuses.contains(currentStatus.toLowerCase()) ? currentStatus.toLowerCase() : 'pending',
          icon: Icon(Icons.arrow_drop_down, color: _getStatusColor(currentStatus)),
          style: TextStyle(color: _getStatusColor(currentStatus), fontWeight: FontWeight.bold, fontSize: 11),
          onChanged: (String? newStatus) async {
            if (newStatus != null && newStatus != currentStatus) {
              await orderRef.update({'status': newStatus});
              final selectedAddress = orderData['selectedAddress'] ?? {};
              final customerName = selectedAddress['fullName'] ?? orderData['customerName'];

              if (userId.isNotEmpty) {
                UserModel user = await getClientData(context, userId);
                if (newStatus == "pending") {
                  sendInvoiceEmail(
                    customerEmail: user.email,
                    orderId: orderId,
                    total: total.toDouble(),
                    orderNumber: orderNumber,
                    items: orderData['items'],
                    customerName: customerName,
                  );
                } else if (newStatus == "shipping") {
                  sendOrderShippingEmail(
                    customerEmail: user.email,
                    orderId: orderNumber.toString(),
                    customerName: customerName,
                  );
                  sendUserNotificationApi(
                    userId: userId,
                    title: "Order Confirmed!",
                    body: "We’re now preparing your order with care.",
                  );
                  _saveNotification(userId, newStatus, orderId,"Order Confirmed!","We’re now preparing your order with care.");

                } else if (newStatus == "completed") {
                  sendOrderReadyEmail(
                    customerEmail: user.email,
                    orderId: orderNumber.toString(),
                    customerName: customerName,
                  );
                  sendUserNotificationApi(
                    userId: userId,
                    title: "Order Shipped!",
                    body: "Please expect a call from our courier.",
                  );
                  _saveNotification(userId, newStatus, orderId,"Order Shipped!","Please expect a call from our courier.");
                } else {
                  sendCancelInvoiceEmail(
                    customerEmail: user.email,
                    orderId: orderId,
                    total: total.toDouble(),
                    items: orderData['items'],
                    customerName: customerName,
                    orderNumber: orderNumber,
                  );
                  sendUserNotificationApi(
                    userId: userId,
                    title: "Your Order Updated Status",
                    body: "Your Order Status $newStatus!",
                  );
                  _saveNotification(userId, newStatus, orderId,"Your Order Updated Status","Your Order Status $newStatus!");
                }
              }

              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status updated to $newStatus")));
            }
          },
          items: _statuses.map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value.toUpperCase()))).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'shipping': return Colors.blue;
      default: return Colors.orange;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green.shade50;
      case 'cancelled': return Colors.red.shade50;
      case 'shipping': return Colors.blue.shade50;
      default: return Colors.orange.shade50;
    }
  }
}

// =========================================================================
// 🎨 صفحة واجهة إنشاء الطلب اليدوي
// =========================================================================
class CreateManualOrderPage extends StatefulWidget {
  const CreateManualOrderPage({super.key});

  @override
  State<CreateManualOrderPage> createState() => _CreateManualOrderPageState();
}

class _CreateManualOrderPageState extends State<CreateManualOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final additionalPhoneController = TextEditingController();

  final addressTitleController = TextEditingController(text: "Home");
  final detailsController = TextEditingController();
  final buildingController = TextEditingController();
  final floorController = TextEditingController();
  final apartmentController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final landmarkController = TextEditingController();

  final itemTitleController = TextEditingController();
  final priceController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFA6BAC8),
      appBar: AppBar(
        title: const Text("Create Manual Order", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? MediaQuery.of(context).size.width * 0.2 : 16.0,
          vertical: 24.0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionCard(
                title: "1. Customer Profile",
                icon: Icons.person_outline,
                children: [
                  _buildTextField(
                    controller: nameController,
                    label: "Customer Full Name *",
                    hint: "e.g. John Doe",
                    validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: phoneController,
                          label: "Primary Phone *",
                          hint: "01xxxxxxxxx",
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: additionalPhoneController,
                          label: "Alternative Phone",
                          hint: "Optional",
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: "2. Shipping Address Details",
                icon: Icons.location_on_outlined,
                children: [
                  _buildTextField(
                    controller: addressTitleController,
                    label: "Address Label",
                    hint: "e.g. Home, Office, Studio",
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: detailsController,
                    label: "Street Address / Details *",
                    hint: "e.g. 15 El-Tahrir St.",
                    validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(controller: buildingController, label: "Building", hint: "e.g. 12B")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField(controller: floorController, label: "Floor", hint: "e.g. 3rd")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField(controller: apartmentController, label: "Apt No.", hint: "e.g. 302")),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(controller: cityController, label: "City", hint: "e.g. Alexandria")),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(controller: stateController, label: "Governorate / State", hint: "e.g. Cairo")),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: landmarkController,
                    label: "Landmark",
                    hint: "e.g. Near Metro Station",
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: "3. Order Items & Pricing",
                icon: Icons.shopping_bag_outlined,
                children: [
                  _buildTextField(
                    controller: itemTitleController,
                    label: "Product / Service Description *",
                    hint: "e.g. Custom Canvas Print (60x90cm)",
                    validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: priceController,
                    label: "Total Price (EGP) *",
                    hint: "0.00",
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required";
                      if (double.tryParse(v) == null) return "Invalid price";
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isLoading ? "Creating Order..." : "Submit Manual Order",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isLoading ? null : _submitOrder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryPurple, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5)),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double price = double.parse(priceController.text.trim());

      int nextOrderNumber = 1000;
      try {
        final querySnapshot = await _firestore
            .collectionGroup('orders')
            .orderBy('orderNumber', descending: true)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final maxNumber = querySnapshot.docs.first.data()['orderNumber'];
          if (maxNumber is int) {
            nextOrderNumber = maxNumber + 1;
          }
        }
      } catch (e) {
        final querySnapshot = await _firestore.collectionGroup('orders').get();
        if (querySnapshot.docs.isNotEmpty) {
          int maxNum = 1000;
          for (var doc in querySnapshot.docs) {
            final numVal = doc.data()['orderNumber'];
            if (numVal is int && numVal > maxNum) {
              maxNum = numVal;
            }
          }
          nextOrderNumber = maxNum + 1;
        }
      }

      final Map<String, dynamic> addressMap = {
        'title': addressTitleController.text.trim().isEmpty ? 'Home' : addressTitleController.text.trim(),
        'fullName': nameController.text.trim(),
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'additionalPhone': additionalPhoneController.text.trim(),
        'addressDetails': detailsController.text.trim(),
        'details': detailsController.text.trim(),
        'building': buildingController.text.trim(),
        'floor': floorController.text.trim(),
        'apartment': apartmentController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'landmark': landmarkController.text.trim(),
      };

      await _firestore.collection('orders').add({
        'orderNumber': nextOrderNumber,
        'customerName': nameController.text.trim(),
        'customerPhone': phoneController.text.trim(),
        'selectedAddress': addressMap,
        'totalPrice': price,
        'status': 'pending',
        'isManual': true,
        'userId': '',
        'createdAt': FieldValue.serverTimestamp(),
        'items': [
          {
            'title': itemTitleController.text.trim(),
            'price': price,
            'quantity': 1,
          }
        ]
      });
      await _firestore.collection('app_info').doc("const").update({
        "order_number":nextOrderNumber+1
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✨ Manual Order #$nextOrderNumber Created Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, "Error Creating Order", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}