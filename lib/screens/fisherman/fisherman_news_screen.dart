import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../widgets/fisherman/news_card.dart';
import 'fisherman_drawer.dart';

class FishermanNewsScreen extends StatelessWidget {
  const FishermanNewsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.news,
          style: TextStyle(
            color: AppColors.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.whiteColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const FishermanDrawer(),
      body: Container(
        color: AppColors.newsBackground,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) {
            return NewsCard(
              title: 'Weather Update ${index + 1}',
              content: 'Important weather information for fishermen. Strong winds expected tomorrow morning. Please take necessary precautions.',
              imageUrl: 'https://via.placeholder.com/300x200',
              publishDate: DateTime.now().subtract(Duration(days: index)),
            );
          },
        ),
      ),
    );
  }
}