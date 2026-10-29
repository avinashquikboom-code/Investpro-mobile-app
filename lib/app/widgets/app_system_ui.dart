import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fallback overlays for custom-header, auth and splash routes.
/// AppAppBar's own AnnotatedRegion takes precedence when present.
class AppSystemUi extends StatelessWidget {
  final Widget child;
  final Color? statusSurface;
  const AppSystemUi({super.key, required this.child, this.statusSurface});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkStatus = ThemeData.estimateBrightnessForColor(statusSurface ?? theme.colorScheme.surface) == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: darkStatus ? Brightness.light : Brightness.dark,
        statusBarBrightness: darkStatus ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: theme.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false),
      child: child);
  }
}
