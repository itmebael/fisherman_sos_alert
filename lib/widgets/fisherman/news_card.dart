import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class NewsCard extends StatelessWidget {
  final String title;
  final String content;
  final String imageUrl;
  final DateTime publishDate;

  const NewsCard({
    super.key,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.publishDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 160,
              width: double.infinity,
              color: AppColors.primaryColor.withOpacity(0.1),
              child: const Icon(
                Icons.wb_sunny,
                size: 60,
                color: AppColors.primaryColor,
              ),
            ),
          ),

          // Text content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // ✅ Fixed Row (no overflow)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${publishDate.day}/${publishDate.month}/${publishDate.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis, // shrink if needed
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _showFullNews(context);
                      },
                      child: const Text(
                        'Read More',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullNews(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
