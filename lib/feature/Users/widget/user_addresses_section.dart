import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../controller/user_detail_controller.dart';

class UserAddressesSection extends StatelessWidget {
  final UserDetailController controller;

  const UserAddressesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);
    final itemBg = isDark ? const Color(0xFF27273A) : const Color(0xFFF9FAFB);

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Obx(() {
        if (controller.isLoadingUser.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            ),
          );
        }

        final data = controller.userDetails;
        final String phone = data['phone'] ?? 'N/A';
        final List addresses = data['addresses'] as List? ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Addresses & Contact",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: itemBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF6366F1)),
                  const SizedBox(width: 10),
                  Text(
                    "Phone: $phone",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Saved Addresses",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
            ),
            const SizedBox(height: 8),
            if (addresses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text("No saved addresses.", style: TextStyle(color: textSecondary, fontSize: 12)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final map = addresses[index] as Map<String, dynamic>? ?? {};
                  final String fullName = map['fullName'] ?? map['name'] ?? '';
                  final String street = map['street'] ?? '';
                  final String building = map['building'] ?? '';
                  final String floor = map['floor'] ?? '';
                  final String apartment = map['apartment'] ?? '';
                  final String city = map['city'] ?? '';
                  final String governorate = map['governorate'] ?? '';
                  final String landmark = map['landmark'] ?? '';

                  List<String> detailsParts = [];
                  if (building.isNotEmpty) detailsParts.add("Building $building");
                  if (street.isNotEmpty) detailsParts.add("Street $street");
                  if (floor.isNotEmpty) detailsParts.add("Floor $floor");
                  if (apartment.isNotEmpty) detailsParts.add("Apt $apartment");
                  if (landmark.isNotEmpty) detailsParts.add("Near $landmark");
                  if (city.isNotEmpty) detailsParts.add(city);
                  if (governorate.isNotEmpty) detailsParts.add(governorate);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: itemBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (fullName.isNotEmpty)
                                Text(
                                  fullName,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                                ),
                              if (detailsParts.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  detailsParts.join(', '),
                                  style: TextStyle(color: textSecondary, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      }),
    );
  }
}