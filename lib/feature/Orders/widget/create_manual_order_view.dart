import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/order_service.dart';
import '../../../Core/widgets/error_dailog_custom.dart';

class CreateManualOrderPage extends StatefulWidget {
  const CreateManualOrderPage({super.key});

  @override
  State<CreateManualOrderPage> createState() => _CreateManualOrderPageState();
}

class _CreateManualOrderPageState extends State<CreateManualOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OrderService _orderService = OrderService();

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
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    additionalPhoneController.dispose();
    addressTitleController.dispose();
    detailsController.dispose();
    buildingController.dispose();
    floorController.dispose();
    apartmentController.dispose();
    cityController.dispose();
    stateController.dispose();
    landmarkController.dispose();
    itemTitleController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFA6BAC8);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text("Create Manual Order", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
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
                isDark: isDark,
                title: "1. Customer Profile",
                icon: Icons.person_outline,
                children: [
                  _buildTextField(
                    isDark: isDark,
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
                          isDark: isDark,
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
                          isDark: isDark,
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
                isDark: isDark,
                title: "2. Shipping Address Details",
                icon: Icons.location_on_outlined,
                children: [
                  _buildTextField(
                    isDark: isDark,
                    controller: addressTitleController,
                    label: "Address Label",
                    hint: "e.g. Home, Office, Studio",
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    isDark: isDark,
                    controller: detailsController,
                    label: "Street Address / Details *",
                    hint: "e.g. 15 El-Tahrir St.",
                    validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(isDark: isDark, controller: buildingController, label: "Building", hint: "e.g. 12B")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField(isDark: isDark, controller: floorController, label: "Floor", hint: "e.g. 3rd")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField(isDark: isDark, controller: apartmentController, label: "Apt No.", hint: "e.g. 302")),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(isDark: isDark, controller: cityController, label: "City", hint: "e.g. Alexandria")),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(isDark: isDark, controller: stateController, label: "Governorate / State", hint: "e.g. Cairo")),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    isDark: isDark,
                    controller: landmarkController,
                    label: "Landmark",
                    hint: "e.g. Near Metro Station",
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                isDark: isDark,
                title: "3. Order Items & Pricing",
                icon: Icons.shopping_bag_outlined,
                children: [
                  _buildTextField(
                    isDark: isDark,
                    controller: itemTitleController,
                    label: "Product / Service Description *",
                    hint: "e.g. Custom Canvas Print (60x90cm)",
                    validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    isDark: isDark,
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

  Widget _buildSectionCard({required bool isDark, required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
              ),
            ],
          ),
          Divider(height: 24, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final borderColor = isDark ? Colors.grey.shade700 : const Color(0xFFE2E8F0);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : AppColors.textMuted),
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5)),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double price = double.parse(priceController.text.trim());
      final int nextOrderNumber = await _orderService.getNextOrderNumber();

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
        "order_number": nextOrderNumber + 1
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