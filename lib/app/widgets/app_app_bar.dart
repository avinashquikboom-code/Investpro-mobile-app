import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_back_button.dart';

/// InvestPro navigation presentation, adapted using Flutter's target platform.
/// Legacy wrappers delegate here; this is the only AppBar implementation.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget? leading;
  final bool? showBackButton;
  final bool showMenuButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool? centerTitle;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final double scrolledUnderElevation;
  final PreferredSizeWidget? bottom;
  final double leadingWidth;
  final double toolbarHeight;
  final TextStyle? titleTextStyle;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final TargetPlatform? platform;

  const AppAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.leading,
    this.showBackButton,
    this.showMenuButton = false,
    this.onBackPressed,
    this.actions,
    this.centerTitle,
    this.automaticallyImplyLeading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.scrolledUnderElevation = 0,
    this.bottom,
    this.leadingWidth = 56,
    this.toolbarHeight = kToolbarHeight,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.platform,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    (subtitle == null ? toolbarHeight : toolbarHeight + 16) +
        (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = platform ?? theme.platform;
    final centered = centerTitle ?? target == TargetPlatform.iOS;
    final background =
        backgroundColor ??
        theme.appBarTheme.backgroundColor ??
        theme.colorScheme.surface;
    final foreground =
        foregroundColor ??
        theme.appBarTheme.foregroundColor ??
        theme.colorScheme.onSurface;
    final darkSurface =
        ThemeData.estimateBrightnessForColor(
          background == Colors.transparent
              ? theme.scaffoldBackgroundColor
              : background,
        ) ==
        Brightness.dark;
    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && showMenuButton) {
      ScaffoldState? drawer;
      context.visitAncestorElements((element) {
        if (element is StatefulElement && element.state is ScaffoldState) {
          final state = element.state as ScaffoldState;
          if (state.hasDrawer) {
            drawer = state;
            return false;
          }
        }
        return true;
      });
      if (drawer != null) {
        effectiveLeading = IconButton(
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          icon: const Icon(Icons.menu),
          onPressed: drawer!.openDrawer,
        );
      }
    }
    if (effectiveLeading == null &&
        (showBackButton ?? (ModalRoute.of(context)?.canPop ?? false))) {
      effectiveLeading = AppBackButton(
        onPressed: onBackPressed,
        color: foreground,
        platform: target,
      );
    }
    final style =
        (titleTextStyle ??
                theme.appBarTheme.titleTextStyle ??
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))
            .copyWith(color: foreground);
    Widget? effectiveTitle = titleWidget;
    if (effectiveTitle == null && title != null) {
      effectiveTitle = Text(
        title!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
      if (subtitle != null) {
        effectiveTitle = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: centered
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            effectiveTitle,
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        );
      }
    }
    return AppBar(
      title: effectiveTitle,
      titleTextStyle: style,
      centerTitle: centered,
      leading: effectiveLeading,
      leadingWidth: effectiveLeading == null ? null : leadingWidth,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      toolbarHeight: subtitle == null ? toolbarHeight : toolbarHeight + 16,
      backgroundColor: background,
      foregroundColor: foreground,
      iconTheme: IconThemeData(color: foreground, size: 24),
      actionsIconTheme: IconThemeData(color: foreground, size: 24),
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      bottom: bottom,
      systemOverlayStyle:
          systemOverlayStyle ??
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: darkSurface
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: darkSurface
                ? Brightness.dark
                : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness:
                theme.brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
    );
  }
}
