import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

/// Reusable KYC Verified badge displaying an Instagram/X-style blue badge
/// with a checkmark for investors whose KYC is verified.
class KycVerifiedBadge extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry padding;

  const KycVerifiedBadge({
    super.key,
    this.size = 16.0,
    this.padding = const EdgeInsets.only(left: 4.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Tooltip(
        message: 'KYC Verified',
        child: Icon(
          Remix.verified_badge_fill,
          color: const Color(0xFF1D9BF0),
          size: size,
        ),
      ),
    );
  }
}
