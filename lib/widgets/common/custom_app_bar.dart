import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor ?? AppColors.whiteColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor ?? AppColors.primaryColor,
      foregroundColor: foregroundColor ?? AppColors.whiteColor,
      elevation: elevation,
      leading: leading ?? (automaticallyImplyLeading ? Builder(
        builder: (context) {
          final canPop = Navigator.of(context).canPop();
          return IconButton(
            icon: Icon(
              canPop ? Icons.arrow_back : Icons.menu,
              color: foregroundColor ?? AppColors.whiteColor,
            ),
            onPressed: () {
              if (canPop) {
                Navigator.of(context).pop();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          );
        },
      ) : null),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      iconTheme: IconThemeData(
        color: foregroundColor ?? AppColors.whiteColor,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}