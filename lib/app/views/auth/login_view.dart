import 'package:remixicon/remixicon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _identity = TextEditingController();
  final _password = TextEditingController();
  final _identityFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _identity.clear();
    _password.clear();
  }

  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    _identityFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _login() {
    FocusManager.instance.primaryFocus?.unfocus();
    final identity = _identity.text.trim();
    final password = _password.text;
    Get.find<AuthController>().login(identity, password);
  }

  Widget _field(bool password) {
    final auth = Get.find<AuthController>();
    return Obx(
      key: ValueKey(
        password ? 'password-input-region' : 'identity-input-region',
      ),
      () => TextFormField(
        key: ValueKey(password ? 'login-password' : 'login-identity'),
        controller: password ? _password : _identity,
        focusNode: password ? _passwordFocus : _identityFocus,
        obscureText: password && !auth.isPasswordVisible.value,
        enabled: !auth.isLoading.value,
        readOnly: false,
        enableInteractiveSelection: true,
        keyboardType: password
            ? TextInputType.visiblePassword
            : TextInputType.emailAddress,
        textInputAction: password ? TextInputAction.done : TextInputAction.next,
        autofillHints: null,
        enableSuggestions: false,
        autocorrect: false,
        onFieldSubmitted: (_) {
          if (password) {
            _login();
          } else {
            _passwordFocus.requestFocus();
          }
        },
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: (password ? 'password' : 'emailOrMobile').tr,
          prefixIcon: Icon(password ? Remix.lock_2_line : Remix.user_3_line),
          suffixIcon: password
              ? IconButton(
                  tooltip: 'Show or hide password',
                  onPressed: auth.togglePasswordVisibility,
                  icon: Icon(
                    auth.isPasswordVisible.value
                        ? Remix.eye_line
                        : Remix.eye_off_line,
                  ),
                )
              : ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _identity,
                  builder: (context, value, _) {
                    if (value.text.isNotEmpty && !auth.isLoading.value) {
                      return IconButton(
                        tooltip: 'Clear input',
                        onPressed: () {
                          _identity.clear();
                        },
                        icon: const Icon(
                          Remix.close_line,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      );
                    }
                    return const SizedBox(width: 0, height: 0);
                  },
                ),
        ),
      ),
    );
  }

  Widget _rememberAndForgot() {
    final auth = Get.find<AuthController>();
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
              () => SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: auth.rememberMe.value,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: auth.toggleRememberMe,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'rememberMe'.tr,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'forgotPassword'.tr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _createAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton(
        onPressed: () => Get.toNamed(AppRoutes.register),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
        child: Text(
          'createNewAccount'.tr,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _secureFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Remix.shield_check_line, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          'secureAndTrusted'.tr,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fullHeight =
                constraints.maxHeight + MediaQuery.viewInsetsOf(context).bottom;
            final showBrand = fullHeight > 590 * scale;
            final gap = (fullHeight * .022).clamp(6.0, 18.0);
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth < 360 ? 16 : 24,
                          vertical: 8,
                        ),
                        child: AutofillGroup(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showBrand) ...[
                                const AppLogo(size: 56, fontSize: 24),
                                SizedBox(height: gap),
                              ],
                              Text(
                                'welcomeBack'.tr,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'loginSubtitle'.tr,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              SizedBox(height: gap),
                              _field(false),
                              SizedBox(height: gap),
                              _field(true),
                              SizedBox(height: gap / 2),
                              _rememberAndForgot(),
                              SizedBox(height: gap),
                              Obx(
                                () => ElevatedButton(
                                  onPressed: auth.isLoading.value
                                      ? null
                                      : _login,
                                  child: auth.isLoading.value
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text('login'.tr),
                                ),
                              ),
                              SizedBox(height: gap),
                              _createAccountButton(),
                              if (showBrand) ...[
                                SizedBox(height: gap),
                                _secureFooter(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
