import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Platform back affordance. maybePop respects route-local PopScope policies.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final double iconSize;
  final String? tooltip;
  final TargetPlatform? platform;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.icon,
    this.iconSize = 24,
    this.tooltip,
    this.platform,
  });

  @override
  Widget build(BuildContext context) {
    final ios = (platform ?? Theme.of(context).platform) == TargetPlatform.iOS;
    final label =
        tooltip ?? MaterialLocalizations.of(context).backButtonTooltip;
    final navigator = Navigator.maybeOf(context);
    final canPop =
        ModalRoute.of(context)?.canPop ?? navigator?.canPop() ?? false;
    final callback =
        onPressed ??
        (canPop
            ? () {
                navigator?.maybePop();
              }
            : null);
    final glyph = Icon(
      icon ?? (ios ? CupertinoIcons.back : Icons.arrow_back),
      size: iconSize,
      color: color,
    );
    return SizedBox(
      width: 48,
      height: 48,
      child: ios
          ? Tooltip(
              message: label,
              child: Semantics(
                button: true,
                label: label,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: callback,
                  child: glyph,
                ),
              ),
            )
          : IconButton(
              tooltip: label,
              onPressed: callback,
              icon: glyph,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
    );
  }
}
