import 'package:flutter/material.dart';

class RecommendationsSection extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;
  final bool isDark;

  const RecommendationsSection({
    Key? key,
    required this.recommendations,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: recommendations.map((rec) {
        final Color recColor = rec['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: recColor.withOpacity(isDark ? 0.2 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: recColor.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: recColor,
                radius: 20,
                child: Icon(rec['icon'], color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.amber.shade300 : recColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec['desc'],
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}