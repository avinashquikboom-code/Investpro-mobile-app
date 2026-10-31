import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/services/backend_snapshot.dart';
import 'package:investpro/app/models/transaction_model.dart';
import 'package:investpro/app/models/investment_model.dart';
import 'package:investpro/app/utils/display_value.dart';

void main() {
  const project = '5beffe56-c013-4828-9e12-0caf83a648f6';
  const transaction = '21d1f53f-37c5-402a-ae81-a35bc466f4d8';
  test('live transaction keeps navigation ID but displays joined name and actual transaction number', () {
    final model = BackendSnapshot.transaction({
      'id': transaction,
      'type': 'INVESTMENT',
      'amount': '100',
      'status': 'PENDING',
      'createdAt': '2026-10-31',
      'transactionReference': 'TXN-0042',
      'investment': {
        'projectId': project,
        'project': {'title': 'Actual Project'},
      },
    });
    expect(model.id, transaction);
    expect(model.projectId, project);
    expect(model.projectName, 'Actual Project');
    expect(model.referenceId, 'TXN-0042');
  });
  test(
    'legacy transaction cache preserves its exact UUID reference',
    () {
      final model = TransactionModel.fromJson({
        'id': transaction,
        'type': 'investment',
        'title': 'Investment',
        'subtitle': 'Project',
        'amount': 100,
        'date': '2026-10-31',
        'referenceId': transaction,
      });
      expect(model.id, transaction);
      expect(model.referenceId, transaction);
      expect(
        TransactionModel.fromJson({
          ...model.toJson(),
          'referenceId': 'TXN-1234',
        }).referenceId,
        'TXN-1234',
      );
    },
  );
  test('investment follows project relation and stored invoice, preserving internal ID', () {
    final model = BackendSnapshot.investment({
      'id': 'investment',
      'projectId': project,
      'projectName': project,
      'investmentReference': 'INV-001',
      'project': {'title': 'Actual Project'},
      'amount': '100',
      'agreedRoi': 12,
      'tenureMonths': 12,
      'startDate': '2026-01-01',
      'maturityDate': '2027-01-01',
    });
    expect(model.projectId, project);
    expect(model.projectName, 'Actual Project');
    expect(model.reference, 'INV-001');
    expect(
      InvestmentModel.fromJson({...model.toJson(), 'projectName': project})
          .projectName,
      project,
    );
    expect(
      InvestmentModel.fromJson({
        ...model.toJson(),
        'investmentReference': 'INV-$transaction',
      }).reference,
      'INV-$transaction',
    );
    expect(
      BackendSnapshot.investment({
        'id': 'investment',
        'projectId': project,
        'investmentReference': 'INV-$transaction',
      }).reference,
      'INV-$transaction',
    );
  });
  test('missing values use N/A while supplied IDs remain complete', () {
    expect(DisplayValue.reference('INV-$transaction'), 'INV-$transaction');
    expect(DisplayValue.text(null), 'N/A');
    expect(DisplayValue.reference('INV-001'), 'INV-001');
    expect(BackendSnapshot.transaction({'id': transaction}).referenceId, 'N/A');
    expect(
      BackendSnapshot.investment({'id': 'investment', 'projectId': project})
          .projectName,
      'N/A',
    );
  });
}
