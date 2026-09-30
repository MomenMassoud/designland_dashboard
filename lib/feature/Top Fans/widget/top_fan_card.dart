import 'package:flutter/material.dart';
import '../../../model/top_fan_model.dart';

class TopFanCard extends StatelessWidget {
  final TopFanModel fan;
  final int rank;
  final bool isDark;
  final VoidCallback onViewReport;
  final VoidCallback onSendPromoCode;

  const TopFanCard({
    super.key,
    required this.fan,
    required this.rank,
    required this.isDark,
    required this.onViewReport,
    required this.onSendPromoCode,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          // شارة الترتيب Rank
          CircleAvatar(
            radius: 18,
            backgroundColor: rank == 1
                ? const Color(0xFFFFD700)
                : rank == 2
                ? const Color(0xFFC0C0C0)
                : rank == 3
                ? const Color(0xFFCD7F32)
                : const Color(0xFF6366F1).withOpacity(0.2),
            child: Text(
              "#$rank",
              style: TextStyle(
                color: rank <= 3 ? Colors.black : const Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // الصورة الشخصية
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF6366F1),
            backgroundImage: fan.profileImage != null ? NetworkImage(fan.profileImage!) : null,
            child: fan.profileImage == null
                ? Text(
              fan.name.isNotEmpty ? fan.name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )
                : null,
          ),
          const SizedBox(width: 12),

          // تفاصيل المستخدم
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fan.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                ),
                Text(
                  fan.phone.isNotEmpty ? fan.phone : fan.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),

          // عدد الطلبات المكتملة والإجمالي
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${fan.completedOrdersCount} Orders",
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${fan.totalSpent.toStringAsFixed(2)} EGP",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          // قائمة الأكشنز (الثلاث نقاط)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDark ? const Color(0xFF2A2A3C) : Colors.white,
            onSelected: (value) {
              if (value == 'report') {
                onViewReport();
              } else if (value == 'promo') {
                onSendPromoCode();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: Color(0xFF6366F1), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'View User Report',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'promo',
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_outlined, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Send Promo Code',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}