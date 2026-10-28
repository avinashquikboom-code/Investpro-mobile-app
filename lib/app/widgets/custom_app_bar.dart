import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? titleColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.backgroundColor,
    this.titleColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final canPop =
        showBackButton && (Navigator.canPop(context) || onBackPressed != null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;

    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: canPop
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: titleColor ?? defaultTitleColor,
              ),
              onPressed: onBackPressed ?? () => Get.back(),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? defaultTitleColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
    );
  }
}
