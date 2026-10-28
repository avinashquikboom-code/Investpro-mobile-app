import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_back_button.dart';

/// Standardized platform-independent AppBar for InvestPro.
///
/// Features:
/// - Consistent centered title alignment across iOS and Android
/// - Standard typography, colors, and ellipsis truncation
/// - Uniform chevron back icon and safe back navigation
/// - Symmetrical layout to prevent title shifting when actions or leading exist
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final bool? showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final double scrolledUnderElevation;
  final PreferredSizeWidget? bottom;
  final double leadingWidth;
  final TextStyle? titleTextStyle;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.showBackButton,
    this.onBackPressed,
    this.actions,
    this.centerTitle = true,
    this.automaticallyImplyLeading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.scrolledUnderElevation = 0,
    this.bottom,
    this.leadingWidth = 56,
    this.titleTextStyle,
    this.systemOverlayStyle,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultFgColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final effectiveFgColor =
        foregroundColor ?? theme.appBarTheme.foregroundColor ?? defaultFgColor;

    // Resolve leading widget
    Widget? effectiveLeading = leading;
    if (effectiveLeading == null) {
      final canPop =
          showBackButton ??
          (onBackPressed != null || (ModalRoute.of(context)?.canPop ?? false));
      if (canPop) {
        effectiveLeading = AppBackButton(
          onPressed: onBackPressed,
          color: foregroundColor ?? defaultFgColor,
        );
      }
    }

    // Resolve title widget with guaranteed center alignment & ellipsis
    Widget? effectiveTitle = titleWidget;
    if (effectiveTitle == null && title != null && title!.isNotEmpty) {
      final defaultStyle =
          theme.appBarTheme.titleTextStyle ??
          TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: effectiveFgColor,
          );

      effectiveTitle = Text(
        title!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: (titleTextStyle ?? defaultStyle).copyWith(
          color: foregroundColor ?? defaultStyle.color ?? effectiveFgColor,
        ),
      );
    }

    return AppBar(
      title: effectiveTitle != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: effectiveTitle,
            )
          : null,
      centerTitle: centerTitle,
      leading: effectiveLeading,
      leadingWidth: effectiveLeading != null ? leadingWidth : null,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      backgroundColor:
          backgroundColor ??
          theme.appBarTheme.backgroundColor ??
          Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      bottom: bottom,
      systemOverlayStyle:
          systemOverlayStyle ?? theme.appBarTheme.systemOverlayStyle,
    );
  }
}
