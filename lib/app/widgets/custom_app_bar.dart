import 'package:flutter/material.dart';

import 'app_app_bar.dart';

export 'app_app_bar.dart';
export 'app_back_button.dart';

/// Legacy alias and wrapper around [AppAppBar] for backward compatibility.
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
    return AppAppBar(
      title: title,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: titleColor,
    );
  }
}
