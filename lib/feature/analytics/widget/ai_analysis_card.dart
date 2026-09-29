import 'package:flutter/material.dart';

class AiAnalysisCard extends StatelessWidget {
  final bool isAnalyzing;
  final String? result;
  final bool isDark;
  final VoidCallback OnClose;

  const AiAnalysisCard({
    Key? key,
    required this.isAnalyzing,
    required this.result,
    required this.isDark,
    required this.OnClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isAnalyzing && result == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.deepPurple.shade900, Colors.indigo.shade900]
              : [Colors.deepPurple.shade900, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(isDark ? 0.5 : 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Gemini AI Executive Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: OnClose,
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          if (isAnalyzing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Colors.amberAccent),
                    SizedBox(height: 12),
                    Text(
                      "Analyzing platform analytics with Gemini AI...",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else if (result != null)
            SelectableText(
              result!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
        ],
      ),
    );
  }
}