import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.status,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
      case 'received':
        bg = AppColors.badgeGreenBg;
        fg = AppColors.badgeGreenText;
        break;
      case 'pending':
      case 'processing':
        bg = AppColors.badgeAmberBg;
        fg = AppColors.badgeAmberText;
        break;
      case 'withdrawn':
      case 'deposit':
        bg = AppColors.badgeBlueBg;
        fg = AppColors.badgeBlueText;
        break;
      case 'failed':
      case 'rejected':
      default:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            status,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
