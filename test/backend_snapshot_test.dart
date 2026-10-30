import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/controllers/withdrawal_controller.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/models/withdrawal_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/services/backend_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  DemoRepository liveRepository() {
    final storage = LocalStorageService();
    return DemoRepository(storage, NotificationService(storage), ApiService());
  }
  test('withdrawal history shows the backend approval independently of transaction settlement', () {
    final repo = liveRepository();
    repo.withdrawals.add(WithdrawalModel(id:'w',amount:100,bankName:'Bank',accountNumber:'•••• 1234',requestDate:DateTime(2026),status:'Approved',referenceId:'W1'));
    final controller = WithdrawalController(repo);
    expect(controller.filteredTransactions.single.status, 'Approved');
    expect(controller.filteredTransactions.single.referenceId, 'W1');
    controller.onClose();
  });
  test('new live investment requests are visible in the default All filter', () {
    final repo = liveRepository();
    repo.investments.add(BackendSnapshot.investment({'id':'i','status':'PENDING_PAYMENT','amount':100}));
    final controller = InvestmentController(repo);
    expect(controller.myInvestmentsFilter.value, 'All');
    expect(controller.filteredInvestments.single.status, 'Pending payment');
    controller.onClose();
  });

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
  test('return display separates earned profit from principal and uses actual credit date', () {
    final paid = BackendSnapshot.payout({'id':'s','investmentId':'i','status':'PAID','dueDate':'2026-01-01T00:00:00Z','paidAt':'2026-02-01T00:00:00Z','profitAmount':'12.34','totalAmount':'1012.34'});
    expect(paid.amount, 12.34);
    expect(paid.payoutDate.month, 2);
    final scheduled = BackendSnapshot.payout({'id':'future','investmentId':'i','status':'SCHEDULED','dueDate':'2030-01-01','profitAmount':'20','totalAmount':'1020'});
    expect(scheduled.status, 'Scheduled');
    expect(scheduled.amount, 20);
  });
  test('does not invent bank details or verification', () {
    final user = BackendSnapshot.user({'id':'i','fullName':'Investor','user':{'status':'ACTIVE'}});
    expect(user.bankAccountId, isNull);
    expect(user.bankName, isEmpty);
    expect(user.isBankVerified, false);
  });
}
