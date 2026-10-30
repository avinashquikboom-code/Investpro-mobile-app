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
  bool _passwordStep = false;

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

  void _next() {
    setState(() => _passwordStep = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _passwordFocus.requestFocus();
    });
  }

  Widget _field(bool password, bool compact) {
    final auth = Get.find<AuthController>();
    return Obx(
      () => TextFormField(
        key: ValueKey(password ? 'login-password' : 'login-identity'),
        controller: password ? _password : _identity,
        focusNode: password ? _passwordFocus : _identityFocus,
        obscureText: password && !auth.isPasswordVisible.value,
        enabled: !auth.isLoading.value,
        readOnly: false,
        enableInteractiveSelection: true,
        keyboardType: password
            ? TextInputType.text
            : TextInputType.emailAddress,
        textInputAction: password ? TextInputAction.done : TextInputAction.next,
        autofillHints: null,
        enableSuggestions: false,
        autocorrect: false,
        onFieldSubmitted: (_) {
          if (password) {
            _login();
          } else if (compact) {
            _next();
          } else {
            _passwordFocus.requestFocus();
          }
        },
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: (password ? 'password' : 'emailOrMobile').tr,
          prefixIcon: Icon(
            password
                ? Remix.lock_2_line
                : Remix.user_3_line,
          ),
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
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _options() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _rememberAndForgot(),
      const SizedBox(height: 12),
      _createAccountButton(),
    ],
  );

  Widget _secureFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Remix.shield_check_line,
          size: 16,
          color: AppColors.primary,
        ),
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
            final compact = constraints.maxHeight < 440 * scale;
            // Preserve the focused password when the keyboard changes layout.
            final passwordStep = _passwordStep || _passwordFocus.hasFocus;
            final showBrand = !compact && constraints.maxHeight > 590 * scale;
            final gap = (constraints.maxHeight * .022).clamp(6.0, 18.0);
            return TapRegion(
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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
                          if (!compact) ...[
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
                          ],
                          if (!compact || !passwordStep) _field(false, compact),
                          if (!compact) SizedBox(height: gap),
                          if (!compact || passwordStep) _field(true, compact),
                          if (!compact) ...[
                            SizedBox(height: gap / 2),
                            _rememberAndForgot(),
                          ],
                          SizedBox(height: gap),
                          Obx(
                            () => ElevatedButton(
                              onPressed: auth.isLoading.value
                                  ? null
                                  : compact && !passwordStep
                                  ? _next
                                  : _login,
                              child: auth.isLoading.value
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      compact && !passwordStep
                                          ? 'Next'
                                          : 'login'.tr,
                                    ),
                            ),
                          ),
                          if (compact)
                            Row(
                              children: [
                                if (passwordStep)
                                  IconButton(
                                    tooltip: 'emailOrMobile'.tr,
                                    onPressed: () {
                                      _passwordFocus.unfocus();
                                      setState(() => _passwordStep = false);
                                    },
                                    icon: const Icon(Remix.edit_line),
                                  ),
                                Flexible(
                                  child: TextButton(
                                    onPressed: () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      showDialog<void>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text('welcomeBack'.tr),
                                          content: _options(),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Get.back(),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: const Text('More options'),
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            SizedBox(height: gap),
                            _createAccountButton(),
                            if (showBrand) ...[
                              SizedBox(height: gap),
                              _secureFooter(),
                            ],
                          ],
                        ],
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
