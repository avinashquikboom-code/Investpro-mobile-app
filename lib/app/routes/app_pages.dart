import 'package:get/get.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
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
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainNavigationShell(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.projects,
      page: () => const ProjectsView(isTab: false),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.projectDetails,
      page: () => const ProjectDetailsView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.investNow,
      page: () => const InvestNowView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.paymentConfirmation,
      page: () => const PaymentConfirmationView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.investmentSuccess,
      page: () => const InvestmentSuccessView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.myInvestments,
      page: () => const MyInvestmentsView(isTab: false),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.investmentDetails,
      page: () => const InvestmentDetailsView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.returns,
      page: () => const ReturnsView(isTab: false),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.withdrawals,
      page: () => const WithdrawalView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.transactions,
      page: () => const TransactionHistoryView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(isTab: false),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      transition: Transition.rightToLeft,
    ),
  ];
}
