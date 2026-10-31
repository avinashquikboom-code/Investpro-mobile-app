import '../views/investments/offline_payment_requests_view.dart';
import '../views/help/investor_requests_view.dart';
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';

import 'package:get/get.dart';

import '../views/auth/forgot_password_view.dart';
import '../views/auth/login_view.dart';
import '../views/kyc/kyc_view.dart';
import '../views/auth/register_view.dart';
import '../views/bank/bank_account_view.dart';
import '../views/help/help_support_view.dart';
import '../views/home/main_navigation_shell.dart';
import '../views/investments/invest_now_view.dart';
import '../views/investments/investment_details_view.dart';
import '../views/investments/investment_success_view.dart';
import '../views/investments/my_investments_view.dart';
import '../views/investments/payment_confirmation_view.dart';
import '../views/notifications/notifications_view.dart';
import '../views/profile/edit_profile_view.dart';
import '../views/profile/profile_view.dart';
import '../views/projects/project_details_view.dart';
import '../views/projects/projects_view.dart';
import '../views/returns/returns_view.dart';
import '../views/settings/settings_view.dart';
import '../views/splash/splash_view.dart';
import '../views/transactions/transaction_history_view.dart';
import '../views/withdrawals/withdrawal_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.offlinePayments, page: () => const OfflinePaymentRequestsView()),
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      transition: Transition.native,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.home,
      page: () => const MainNavigationShell(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.projects,
      page: () => const ProjectsView(isTab: false),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.projectDetails,
      page: () => const ProjectDetailsView(),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.investNow,
      page: () => const InvestNowView(),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.paymentConfirmation,
      page: () => const PaymentConfirmationView(),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.investmentSuccess,
      page: () => const InvestmentSuccessView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.myInvestments,
      page: () => const MyInvestmentsView(isTab: false),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.investmentDetails,
      page: () => const InvestmentDetailsView(),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.returns,
      page: () => const ReturnsView(isTab: false),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.withdrawals,
      page: () => const WithdrawalView(),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.transactions,
      page: () => const TransactionHistoryView(),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.profile,
      page: () => const ProfileView(isTab: false),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.editProfile,
      page: () => const EditProfileView(),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.bankDetails,
      page: () => const BankAccountView(),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.helpSupport,
      page: () => const HelpSupportView(),
      transition: Transition.native,
    ),
    GetPage(
      middlewares: [DemoSessionGuard()],
      name: AppRoutes.kyc,
      page: () => const KycView(),
      transition: Transition.native,
    ),
    GetPage(middlewares:[DemoSessionGuard()],name:AppRoutes.requests,page:()=>const InvestorRequestsView()),
  ];
}

class DemoSessionGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      Get.find<AuthController>().isLoggedIn.value
      ? null
      : const RouteSettings(name: AppRoutes.login);
}
