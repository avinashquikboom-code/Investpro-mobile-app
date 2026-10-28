class AppConstants {
  AppConstants._();

  static const String appName = 'InvestPro';
  static const String appTagline = 'Grow Your Wealth With Trusted Investments';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyRememberMe = 'remember_me';
  static const String keyUserEmail = 'user_email';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'app_language';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyBiometricsEnabled = 'biometrics_enabled';
  static const String keyProjectsData = 'projects_data';
  static const String keyInvestmentsData = 'investments_data';
  static const String keyTransactionsData = 'transactions_data';
  static const String keyReturnsData = 'returns_data';
  static const String keyNotificationsData = 'notifications_data';
  static const String keyUserData = 'user_data';
  static const String keyAvailableBalance = 'available_balance';

  // Financial Limits
  static const double minInvestmentAmount = 1000.0;
  static const double maxInvestmentAmount = 1000000.0;
  static const double minWithdrawalAmount = 500.0;

  // Preset Chips
  static const List<double> quickInvestAmounts = [10000, 25000, 50000, 100000];

  // Bank Info & Demo Disclosures
  static const String demoBankName = 'HDFC Bank';
  static const String demoBankAccount = '•••• 4829';
  static const String demoBankIfsc = 'HDFC0001234';
  static const String riskDisclosure =
      'Investments are subject to market risks. Projected returns are estimates based on term performance and are not guaranteed returns.';
}
