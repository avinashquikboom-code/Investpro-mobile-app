import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0 or 0 to 100
  final double height;
  final Color? color;
  final Color? backgroundColor;

  const CustomProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (value > 1.0 ? value / 100.0 : value).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: normalized,
        minHeight: height,
        backgroundColor: backgroundColor ?? (isDark ? AppColors.borderDark : const Color(0xFFE8F2EC)),
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.accent),
      ),
    );
  }
}

class TimelineStepWidget extends StatelessWidget {
  final String title;
  final String date;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  const TimelineStepWidget({
    super.key,
    required this.title,
    required this.date,
    this.isCompleted = false,
    this.isActive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color circleColor;
    Widget innerIcon;

    if (isCompleted) {
      circleColor = AppColors.primary;
      innerIcon = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isActive) {
      circleColor = AppColors.accent;
      innerIcon = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );
    } else {
      circleColor = isDark ? AppColors.borderDark : const Color(0xFFD0DCD5);
      innerIcon = const SizedBox.shrink();
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Line & Circle
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: innerIcon),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : const Color(0xFFE0EBE5)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Step Description
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
