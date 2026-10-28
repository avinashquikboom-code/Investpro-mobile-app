# InvestPro — Investment Management Mobile Application

A modern, professional, fully interactive investment management mobile application built with **Flutter**, **Dart (null safety)**, and **GetX**, matching the reference UI/UX design specifications down to the exact colors, typography, and layout.

---

## 📱 Features & Implemented Screens (All 18 Screens)

1. **Splash Screen** — Fullscreen emerald green gradient with centered growth logo, tagline, animated bottom plant curves, and session-aware auto navigation.
2. **Login Screen** — Form validation, email/mobile input, password visibility toggle, remember me checkbox, forgot password recovery dialog, and demo authentication.
3. **Register Screen** — Segmented role toggle (Investor/Admin demo preview), name, email, phone, password strength validation, and local profile persistence.
4. **Home / Dashboard** — Deep emerald curved header, avatar greeting ("Hello, Rohit Sharma"), unread notification badge, reactive portfolio summary card (₹ 85,000, +12% growth), 3 statistical overview cards (Invested, Returns, Projects), pull-to-refresh, and featured project list.
5. **Projects List** — Category filter pills (`All Projects`, `Active`, `Completed`), project cards with return rate, tenure, target amount, and status badge.
6. **Project Details** — Expected returns, funding progress bar with live percentage (Already Raised vs. Required), term details, and investment risk disclosure.
7. **Invest Now** — Amount input, preset quick chips (`₹ 10K`, `₹ 25K`, `₹ 50K`, `₹ 1L`), reactive calculation of expected return and maturity amount via `InvestmentCalculator`.
8. **Payment Confirmation** — Order breakdown, payment method selector (UPI, Net Banking, Debit/Credit Card, Wallet), terms and conditions agreement, simulated gateway processing with loading state.
9. **Investment Success** — Fullscreen emerald gradient, large checkmark badge, white summary card with generated reference ID, and quick actions to view investments or return home.
10. **My Investments** — Reactive filter tabs (`Active`, `Completed`, `Withdrawn`), real-time completion progress indicators, and investment details access.
11. **Investment Details** — Investment summary, expected vs. maturity amounts, and a 4-stage vertical progress timeline (Start → Development → Launch → Return Period).
12. **Returns** — Total returns card with growth badge, filter tabs (`Monthly`, `Quarterly`, `Yearly`), return payout history with Received/Pending status badges, and upcoming payout date banner.
13. **Withdrawal Request** — Available balance card (₹ 12,480), modal withdrawal form with balance checks, bank account selector, and withdrawal transaction history.
14. **Transaction History** — Filter pills (`All`, `Investment`, `Return`, `Withdrawal`), colored transaction icons, amounts, timestamps, and detail inspection sheet.
15. **Profile** — User avatar, Investor ID (`INV001`), menu items for Personal Info, Bank Details (verified HDFC Bank sheet), Investment History, Withdrawal History, Settings, Help & Support, and Logout confirmation.
16. **Edit Profile** — Profile avatar with camera badge, form fields (name, email, mobile), form validation, and reactive updates across Home and Profile.
17. **Notifications** — Categorized notifications with distinct icon accents, timestamp formatting, unread badge indicators, and mark-as-read/mark-all-as-read functionality.
18. **Settings** — Multi-language switcher (**English**, **हिन्दी**, **मराठी**) with live runtime translation updates, light/dark/system theme switching, notification preference toggle, biometric login simulation toggle, change password modal, and version display.

---

## 🎨 Design System & Color Palette

- **Primary**: `#006B3C` (Dark Emerald Green)
- **Primary Dark**: `#004D2C`
- **Primary Light**: `#0E9F53`
- **Accent**: `#35C76F`
- **Background**: `#F8FCFA` (Light Mint White)
- **Surface**: `#FFFFFF`
- **Text Primary**: `#102D25`
- **Text Secondary**: `#71847D`
- **Border**: `#E0EBE5`
- **Success**: `#16A34A`
- **Warning**: `#F59E0B`
- **Error**: `#EF4444`

Typography: **Google Fonts (Poppins)** with consistent weights and spacing across Android and iOS.

---

## 🛠️ Architecture & Technology Stack

- **Flutter**: 3.47+ (Stable Channel)
- **State Management & Navigation**: GetX (`Get.put()`, `Get.find()`, `Obx()`, no bindings per architecture specification)
- **Architecture**: Clean MVC (Model - View - Controller - Service - Utils)
- **Local Persistence**: `GetStorage`
- **Typography**: `google_fonts` (Poppins)
- **Formatting**: `intl` (Indian Currency `₹` and date formatting)
- **SVG / Vector Rendering**: `flutter_svg` and custom painters for decorative canvas graphics.

### Financial Calculation Formula

All calculations are encapsulated in `InvestmentCalculator`:

$$\text{Expected Total Return} = \frac{\text{Principal} \times \text{Return Rate \%}}{100}$$

$$\text{Projected Maturity Amount} = \text{Principal} + \text{Expected Total Return}$$

$$\text{Monthly Projected Return} = \frac{\text{Expected Total Return}}{\text{Duration in Months}}$$

Amounts are computed using decimal-safe rounding and formatted using Indian Numbering convention (e.g. `₹ 50,000`, `₹ 1,00,000`).

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.24 or higher)
- Dart SDK (v3.5 or higher)
- Android Studio / Xcode for device simulation

### Installation

```bash
# Navigate to the mobile app directory
cd mobile-app

# Fetch dependencies
flutter pub get

# Verify codebase health (0 analyzer issues)
flutter analyze

# Execute automated unit and widget test suite
flutter test

# Run the application on connected device or simulator
flutter run
```

---

## 🧪 Testing

Comprehensive tests cover:
- Financial return calculations (`InvestmentCalculator`)
- Currency and date formatting (`CurrencyFormatter`, `DateFormatter`)
- Form validators (email, phone, investment amount limits, withdrawal balance bounds)
- Widget rendering and interaction (`AppLogo`, `CustomButton`, `StatusBadge`)

To run tests:
```bash
flutter test
```
