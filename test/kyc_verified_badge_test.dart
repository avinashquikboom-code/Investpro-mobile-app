import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remixicon/remixicon.dart';
import 'package:investpro/app/models/user_model.dart';
import 'package:investpro/app/widgets/kyc_verified_badge.dart';

void main() {
  group('KycVerifiedBadge Widget Tests', () {
    testWidgets('renders verified badge with correct icon, color, and tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KycVerifiedBadge(size: 16),
          ),
        ),
      );

      final iconFinder = find.byIcon(Remix.verified_badge_fill);
      expect(iconFinder, findsOneWidget);

      final Icon iconWidget = tester.widget(iconFinder);
      expect(iconWidget.color, const Color(0xFF1D9BF0));
      expect(iconWidget.size, 16.0);

      final tooltipFinder = find.byType(Tooltip);
      expect(tooltipFinder, findsOneWidget);
      final Tooltip tooltipWidget = tester.widget(tooltipFinder);
      expect(tooltipWidget.message, 'KYC Verified');
    });

    test('UserModel.isKycVerified returns true only when verified', () {
      const verifiedUser = UserModel(
        id: '1',
        fullName: 'Test User',
        email: 'test@example.com',
        mobileNumber: '9999999999',
        kycStatus: 'VERIFIED',
      );
      expect(verifiedUser.isKycVerified, isTrue);

      const approvedUser = UserModel(
        id: '2',
        fullName: 'Approved User',
        email: 'test2@example.com',
        mobileNumber: '9999999998',
        kycStatus: 'APPROVED',
      );
      expect(approvedUser.isKycVerified, isTrue);

      const pendingUser = UserModel(
        id: '3',
        fullName: 'Pending User',
        email: 'test3@example.com',
        mobileNumber: '9999999997',
        kycStatus: 'PENDING',
      );
      expect(pendingUser.isKycVerified, isFalse);

      const rejectedUser = UserModel(
        id: '4',
        fullName: 'Rejected User',
        email: 'test4@example.com',
        mobileNumber: '9999999996',
        kycStatus: 'REJECTED',
      );
      expect(rejectedUser.isKycVerified, isFalse);

      const notSubmittedUser = UserModel(
        id: '5',
        fullName: 'Not Submitted User',
        email: 'test5@example.com',
        mobileNumber: '9999999995',
        kycStatus: 'NOT_SUBMITTED',
      );
      expect(notSubmittedUser.isKycVerified, isFalse);
    });
  });
}

