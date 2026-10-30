import 'package:remixicon/remixicon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../services/local_storage_service.dart';
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
  final _passwordFocus = FocusNode();
  bool _passwordStep = false;

  @override
  void initState() {
    super.initState();
    final storage = Get.find<LocalStorageService>();
    if (storage.rememberMe) _identity.text = storage.userEmail ?? '';
    _identity.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _login() {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.find<AuthController>().login(_identity.text.trim(), _password.text);
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
        focusNode: password ? _passwordFocus : null,
        obscureText: password && !auth.isPasswordVisible.value,
        enabled: !auth.isLoading.value,
        keyboardType: password
            ? TextInputType.visiblePassword
            : TextInputType.emailAddress,
        textInputAction: password ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: (_) {
          if (password) {
            _login();
          } else if (compact) {
            _next();
          } else {
            _passwordFocus.requestFocus();
          }
        },
        autofillHints: password
            ? const [AutofillHints.password]
            : const [AutofillHints.username],
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
              : (_identity.text.isNotEmpty && !auth.isLoading.value
                    ? IconButton(
                        tooltip: 'Clear input',
                        onPressed: () {
                          _identity.clear();
                          setState(() {});
                        },
                        icon: const Icon(
                          Remix.close_line,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null),
        ),
      ),
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
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
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
                              ],
                            ),
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
