import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dashboard_desginland/feature/Users/widget/user_details_widget.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../controller/order_detail_controller.dart';

class OrderCustomerInfoCard extends StatelessWidget {
  final OrderDetailController controller;
  final bool isDark;
  final String formattedDate;

  const OrderCustomerInfoCard({
    super.key,
    required this.controller,
    required this.isDark,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedTextColor = isDark ? Colors.grey[400] : AppColors.textMuted;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    final order = controller.orderData;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Customer Info".tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            Divider(height: 20, color: dividerColor),
            Obx(() {
              final userModel = controller.userModel.value;
              final customerName =
                  order['customerName'] ?? order['userEmail'] ?? userModel?.Name ?? '';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("${"Customer Name:".tr} $customerName",
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                leading: const Icon(Icons.person, color: AppColors.primaryPurple),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: mutedTextColor),
                onTap: () {
                  if (controller.userData.value != null) {
                    Get.to(() => UserDetailView(
                      userId: controller.userId,
                      userData: controller.userData.value!,
                    ));
                  }
                },
              );
            }),
            const SizedBox(height: 4),
            SelectableText("${"Order Date:".tr} $formattedDate",
                style: TextStyle(color: mutedTextColor, fontSize: 13)),

            if (order['selectedAddress'] != null) ...[
              Divider(height: 24, color: dividerColor),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.primaryPurple, size: 20),
                  const SizedBox(width: 8),
                  Text("Delivery Address".tr,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                ),
                child: _buildAddressDetailsWidget(order['selectedAddress']),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressDetailsWidget(dynamic addressData) {
    if (addressData is! Map) {
      return Text(addressData.toString(),
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textDark));
    }

    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedTextColor = isDark ? Colors.grey[400] : AppColors.textMuted;
    final addr = Map<String, dynamic>.from(addressData);

    final String title = addr['title'] ?? addr['name'] ?? '';
    final String recipientName = addr['name'] ?? addr['fullName'] ?? '';
    final String phone = addr['phone'] ?? addr['phoneNumber'] ?? '';
    final String additionalPhone = addr['additionalPhone'] ?? '';

    final String details = addr['addressDetails'] ?? addr['details'] ?? addr['street'] ?? '';
    final String building = addr['building'] ?? addr['buildingNumber'] ?? '';
    final String floor = addr['floor'] ?? addr['floorNumber'] ?? '';
    final String apartment = addr['apartment'] ?? addr['apartmentNumber'] ?? '';
    final String landmark = addr['landmark'] ?? '';
    final String city = addr['city'] ?? '';
    final String state = addr['state'] ?? addr['governorate'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPurple,
                        fontSize: 12),
                  ),
                ),
                if (recipientName.isNotEmpty && recipientName != title) ...[
                  const SizedBox(width: 8),
                  Text("($recipientName)",
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                ],
              ],
            ),
          ),
        if (details.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: SelectableText("العنوان: $details",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
          ),
        if (building.isNotEmpty || floor.isNotEmpty || apartment.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: SelectableText(
              "المبنى: ${building.isEmpty ? '-' : building} | الدور: ${floor.isEmpty ? '-' : floor} | الشقة: ${apartment.isEmpty ? '-' : apartment}",
              style: TextStyle(fontSize: 12, color: mutedTextColor),
            ),
          ),
        if (landmark.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: SelectableText("علامة مميزة: $landmark",
                style: TextStyle(fontSize: 12, color: mutedTextColor)),
          ),
        if (city.isNotEmpty || state.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: SelectableText(
                "المدينة / المحافظة: $city ${state.isNotEmpty ? '($state)' : ''}",
                style: TextStyle(fontSize: 12, color: mutedTextColor)),
          ),
        if (phone.isNotEmpty || additionalPhone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 14, color: mutedTextColor),
              const SizedBox(width: 4),
              SelectableText(
                "رقم الهاتف: $phone ${additionalPhone.isNotEmpty ? ' | آخر: $additionalPhone' : ''}",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.lightBlueAccent : Colors.blueGrey),
              ),
            ],
          ),
        ],
      ],
    );
  }
}