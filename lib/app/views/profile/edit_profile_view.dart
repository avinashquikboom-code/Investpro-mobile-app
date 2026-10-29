import '../../widgets/unsaved_changes_guard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return UnsavedChangesGuard(controllers: [profileCtrl.nameController, profileCtrl.emailController, profileCtrl.phoneController], child: Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(title: 'editProfile'.tr),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 480,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with Camera Edit Badge
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent, width: 3),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 54,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Full Name
                CustomTextField(
                  controller: profileCtrl.nameController,
                  label: 'fullName'.tr,
                  hintText: 'enterFullName'.tr,
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),

                // Email
                CustomTextField(
                  controller: profileCtrl.emailController,
                  label: 'email'.tr,
                  hintText: 'enterEmail'.tr,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),

                // Mobile Number
                CustomTextField(
                  controller: profileCtrl.phoneController,
                  label: 'mobileNumber'.tr,
                  hintText: 'enterMobileNumber'.tr,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),

                // Save Changes Button
                Obx(() {
                  return CustomButton(
                    text: 'saveChanges'.tr,
                    isLoading: profileCtrl.isSaving.value,
                    onPressed: profileCtrl.saveProfile,
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
