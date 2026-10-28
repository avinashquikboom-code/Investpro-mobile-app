import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Standardized platform-independent back button for InvestPro.
///
/// Features:
/// - Consistent left-chevron icon across Android and iOS
/// - Accessible 48x48 logical pixels touch target
/// - Localized semantic tooltip
/// - Safe maybePop navigation that never crashes or leaves empty stacks
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final IconData icon;
  final double iconSize;
  final String? tooltip;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.icon = Icons.arrow_back_ios_new_rounded,
    this.iconSize = 19,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final effectiveColor =
        color ?? theme.appBarTheme.iconTheme?.color ?? defaultColor;

    final effectiveTooltip =
        tooltip ?? MaterialLocalizations.of(context).backButtonTooltip;

    return Semantics(
      button: true,
      label: effectiveTooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          icon: Icon(icon, size: iconSize, color: effectiveColor),
          tooltip: effectiveTooltip,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          splashRadius: 24,
          onPressed: () async {
            if (onPressed != null) {
              onPressed!();
              return;
            }
            // Platform-independent safe back navigation
            final navigator = Navigator.maybeOf(context);
            if (navigator != null && await navigator.maybePop()) {
              return;
            }
            if (Get.key.currentState?.canPop() == true) {
              Get.back();
            }
          },
        ),
      ),
    );
  }
}
