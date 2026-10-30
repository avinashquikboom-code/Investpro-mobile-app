import 'package:remixicon/remixicon.dart';
import 'package:flutter/material.dart';

import '../models/project_model.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

/// Expanded catalog card; dashboard cards keep their existing presentation.
class ProjectListingCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onDetails;
  final VoidCallback? onInvest;
  final String? investmentHint;

  const ProjectListingCard({
    super.key,
    required this.project,
    required this.onDetails,
    this.onInvest,
    this.investmentHint,
  });

  IconData get _icon => switch (project.iconType.toLowerCase()) {
    'code' => Remix.code_s_slash_line,
    'mobile' => Remix.smartphone_line,
    'gear' || 'ai' => Remix.settings_5_line,
    _ => Remix.briefcase_line,
  };

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    double width,
  ) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: text.titleMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = project.status.toUpperCase();
    final pending = status == 'UPCOMING' || status == 'DRAFT';
    final closed = status == 'CANCELLED';
    final statusBackground = pending
        ? AppColors.badgeAmberBg
        : closed
        ? AppColors.errorLight
        : AppColors.badgeGreenBg;
    final statusForeground = pending
        ? AppColors.badgeAmberText
        : closed
        ? AppColors.error
        : AppColors.badgeGreenText;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (project.imageUrl?.trim().isNotEmpty == true)
            Image.network(
              project.imageUrl!,
              height: 160,
              fit: BoxFit.cover,
              semanticLabel: project.name,
              errorBuilder: (_, error, stack) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, box) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(14) > 19;
                final stackButtons = box.maxWidth < 360 || largeText;
                final metricWidth = box.maxWidth < 220
                    ? box.maxWidth
                    : (box.maxWidth - 16) / 2;
                final details = OutlinedButton(
                  onPressed: onDetails,
                  child: const Text(
                    'View Details',
                    textAlign: TextAlign.center,
                  ),
                );
                final invest = ElevatedButton(
                  onPressed: onInvest,
                  child: const Text('Invest Now', textAlign: TextAlign.center),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lightMint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_icon, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.category,
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                project.name,
                                style: theme.textTheme.titleLarge,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            project.statusLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusForeground,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (project.location?.trim().isNotEmpty == true)
                          Text.rich(
                            TextSpan(
                              children: [
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Icon(
                                    Remix.map_pin_line,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextSpan(text: ' ${project.location}'),
                              ],
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _metric(
                          context,
                          'Expected ROI',
                          project.hasReturnData
                              ? '${project.returnRatePercent}% p.a.'
                              : 'Not available',
                          metricWidth,
                        ),
                        _metric(
                          context,
                          'Investment tenure',
                          project.durationMonths > 0
                              ? '${project.durationMonths} months'
                              : 'Not available',
                          metricWidth,
                        ),
                        _metric(
                          context,
                          'Minimum investment',
                          project.minInvestment > 0
                              ? CurrencyFormatter.format(
                                  project.minInvestment,
                                  showDecimals: true,
                                )
                              : 'Not available',
                          metricWidth,
                        ),
                        _metric(
                          context,
                          'Target funding',
                          project.targetAmount > 0
                              ? CurrencyFormatter.format(
                                  project.targetAmount,
                                  showDecimals: true,
                                )
                              : 'Not available',
                          metricWidth,
                        ),
                        if (project.investorCount != null)
                          _metric(
                            context,
                            'Investors',
                            '${project.investorCount}',
                            metricWidth,
                          ),
                      ],
                    ),
                    if (project.hasFundingData) ...[
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Funding progress',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${project.progressPercentage.toStringAsFixed(1)}% funded',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: project.progressPercentage / 100,
                          minHeight: 7,
                          color: AppColors.primary,
                          backgroundColor: AppColors.lightMint,
                          semanticsLabel: 'Funding progress',
                          semanticsValue:
                              '${project.progressPercentage.toStringAsFixed(1)}%',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${CurrencyFormatter.format(project.raisedAmount, showDecimals: true)} raised of ${CurrencyFormatter.format(project.targetAmount, showDecimals: true)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (stackButtons) ...[
                      SizedBox(width: double.infinity, child: details),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: invest),
                    ] else
                      Row(
                        children: [
                          Expanded(child: details),
                          const SizedBox(width: 12),
                          Expanded(child: invest),
                        ],
                      ),
                    if (investmentHint != null) ...[
                      const SizedBox(height: 8),
                      Text(investmentHint!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
