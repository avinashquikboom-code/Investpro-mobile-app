import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';

import '../models/project_model.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

class ExploreProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const ExploreProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  IconData _getCategoryIcon(String iconType) {
    switch (iconType.toLowerCase()) {
      case 'code':
        return Remix.code_s_slash_line;
      case 'mobile':
        return Remix.smartphone_line;
      case 'gear':
      case 'ai':
        return Remix.settings_5_line;
      case 'solar':
      case 'energy':
        return Remix.sun_line;
      case 'real-estate':
      case 'building':
        return Remix.building_2_line;
      case 'agriculture':
      case 'plant':
        return Remix.plant_line;
      default:
        return Remix.briefcase_line;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (project.progressPercentage / 100).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5EFEA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Banner Image with Overlaid Badges
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      height: 144,
                      width: double.infinity,
                      child: project.imageUrl != null && project.imageUrl!.trim().isNotEmpty
                          ? Image.network(
                              project.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildImagePlaceholder(isDark),
                            )
                          : _buildImagePlaceholder(isDark),
                    ),
                  ),

                  // Top-Left: Category Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(project.iconType),
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            project.category.isNotEmpty ? project.category : 'General',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top-Right: Tenure Badge
                  if (project.durationMonths > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '${project.durationMonths} Months',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // 2. Project Card Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Name
                    Text(
                      project.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Short Description
                    Text(
                      project.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Funding Progress Bar with Percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Funding Progress',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${project.progressPercentage.toStringAsFixed(0)}% funded',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: isDark ? AppColors.borderDark : const Color(0xFFE5EFEA),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Divider
                    Divider(
                      height: 1,
                      color: isDark ? AppColors.borderDark : const Color(0xFFF0F4F2),
                    ),
                    const SizedBox(height: 10),

                    // Minimum Investment & Expected Return
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Min Investment',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                project.minInvestment > 0
                                    ? CurrencyFormatter.format(project.minInvestment)
                                    : CurrencyFormatter.format(5000),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF102F25),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Expected Return',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                project.hasReturnData
                                    ? '${project.returnRatePercent.toInt()}% p.a.'
                                    : '${project.returnRatePercent.toInt()}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              _getCategoryIcon(project.iconType),
              color: Colors.white.withValues(alpha: 0.08),
              size: 110,
            ),
          ),
          Icon(
            _getCategoryIcon(project.iconType),
            color: Colors.white.withValues(alpha: 0.8),
            size: 42,
          ),
        ],
      ),
    );
  }
}

