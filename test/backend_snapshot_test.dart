import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/services/backend_snapshot.dart';

void main() {
  test('preserves approval and settlement as distinct statuses', () {
    for (final status in ['PENDING', 'APPROVED', 'PROCESSING', 'COMPLETED', 'REJECTED']) {
      final row = BackendSnapshot.withdrawal({'id':'w','amount':'125.50','status':status,'requestedAt':'2026-10-30T00:00:00Z'});
      expect(row.status.toUpperCase(), status);
      expect(row.amount, 125.5);
    }
  });
  test('requires backend verification before displaying active investment', () {
    final raw = {'id':'i','status':'ACTIVE','amount':'100','agreedRoi':'12','totalExpectedReturns':'6','tenureMonths':6};
    expect(BackendSnapshot.investment(raw).status, 'Payment unverified');
    expect(BackendSnapshot.investment({...raw,'paymentVerified':true}).status, 'Active');
    expect(BackendSnapshot.investment({...raw,'status':'PENDING_PAYMENT'}).status, 'Pending payment');
    expect(BackendSnapshot.investment(raw).expectedReturn, 6);
  });
  test('does not invent bank details or verification', () {
    final user = BackendSnapshot.user({'id':'i','fullName':'Investor','user':{'status':'ACTIVE'}});
    expect(user.bankAccountId, isNull);
    expect(user.bankName, isEmpty);
    expect(user.isBankVerified, false);
  });
}
