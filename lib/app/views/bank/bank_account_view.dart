import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../services/demo_repository.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/unsaved_changes_guard.dart';

class BankAccountView extends StatefulWidget {
  const BankAccountView({super.key});
  @override
  State<BankAccountView> createState() => _BankAccountViewState();
}
class _BankAccountViewState extends State<BankAccountView> {
  final _fields = {for (final key in ['accountHolderName','accountNumber','bankName','ifscCode']) key: TextEditingController()};
  bool _busy = false;
  String? _error;
  @override
  void dispose() { for (final field in _fields.values) { field.dispose(); } super.dispose(); }
  Future<void> _save() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final values = _fields.map((key, field) => MapEntry(key, field.text.trim()));
      if (values['accountHolderName']!.length < 2 || values['bankName']!.length < 2 || !RegExp(r'^\d{8,20}$').hasMatch(values['accountNumber']!) || !RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(values['ifscCode']!)) throw StateError('Check the account name, number, bank and uppercase IFSC.');
      await Get.find<ApiService>().dio.post('/mobile/bank-accounts', data: {...values, 'accountType':'SAVINGS','isPrimary':true});
      await Get.find<DemoRepository>().syncFromBackend();
      if (mounted) { for (final field in _fields.values) { field.clear(); } Navigator.of(context).pop(); }
    } catch (_) { if (mounted) setState(() => _error = 'Unable to save bank account. Check the details and retry.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => UnsavedChangesGuard(controllers: _fields.values.toList(), child: Scaffold(
    appBar: const CustomAppBar(title:'Bank Account',showBackButton:true),
    body: ListView(padding: const EdgeInsets.all(20),children:[
      const Text('Saving an account does not verify it or complete a payout.'),
      for (final entry in _fields.entries) Padding(padding: const EdgeInsets.symmetric(vertical:8),child: TextField(controller:entry.value,enabled:!_busy,decoration:InputDecoration(labelText: {'accountHolderName':'Account holder name','accountNumber':'Account number','bankName':'Bank name','ifscCode':'IFSC'}[entry.key]))),
      if (_error != null) Text(_error!),
      ElevatedButton(onPressed:_busy?null:_save,child:Text(_busy?'Saving…':'Save primary bank account')),
    ])));
}
