import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/investment_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/investment_card.dart';

class MyInvestmentsView extends StatelessWidget {
  final bool isTab;

  const MyInvestmentsView({super.key, this.isTab = true});

  @override
  Widget build(BuildContext context) {
    final invCtrl = Get.find<InvestmentController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filterTabs = ['Active', 'Completed', 'Withdrawn'];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(
        title: 'myInvestments'.tr,
        showBackButton: !isTab,
      ),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: Column(
            children: [
              // Filter Tabs (Active, Completed, Withdrawn)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Obx(() {
                  return Row(
                    children: filterTabs.map((filter) {
                      final isSelected = invCtrl.myInvestmentsFilter.value == filter;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => invCtrl.setMyInvestmentsFilter(filter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : (isDark ? AppColors.surfaceDark : Colors.white),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : (isDark ? AppColors.borderDark : AppColors.border),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textPrimary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ),

              // Investments List
              Expanded(
                child: Obx(() {
                  final list = invCtrl.filteredInvestments;
                  if (list.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.savings_outlined,
                      title: 'No ${invCtrl.myInvestmentsFilter.value} Investments',
                      message: 'You have no investments recorded under this category.',
                      buttonText: 'Explore Projects',
                      onButtonPressed: () => Get.toNamed(AppRoutes.projects),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final investment = list[index];
                      return InvestmentCard(
                        investment: investment,
                        onTap: () {
                          invCtrl.selectInvestment(investment);
                          Get.toNamed(AppRoutes.investmentDetails);
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
