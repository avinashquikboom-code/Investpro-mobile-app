import '../../widgets/account_sync.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';

class KycView extends StatefulWidget {
  const KycView({super.key});
  @override
  State<KycView> createState() => _KycViewState();
}
class _KycViewState extends State<KycView> {
  List<dynamic> _rows = [];
  bool _loading = true, _busy = false;
  String? _error;
  String _search = '';
  String _type = 'PAN_CARD';
  @override
  void initState() { super.initState(); }
  Future<void> _load() async {
    try { final rows = await Get.find<ApiService>().kyc(); if (mounted) setState(() { _rows = rows; _error = null; }); }
    catch (_) { if (mounted) setState(() => _error = 'Unable to load KYC requests. Retry.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _action(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try { await action(); await _load(); }
    catch (_) { if (mounted) setState(() => _error = 'Request failed. Refresh before retrying.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _view(String id) async {
    final url = await Get.find<ApiService>().kycDocumentUrl(id);
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) throw StateError('Unable to open document');
  }
  Future<void> _upload() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg']);
    if (result.isEmpty) return;
    final file = result.single;
    if ((await file.length() ?? 5 * 1024 * 1024 + 1) > 5 * 1024 * 1024) { setState(() => _error = 'Select a PDF, PNG or JPEG up to 5 MB.'); return; }
    final bytes = await file.readAsBytes();
    await _action(() => Get.find<ApiService>().submitKyc(_type, bytes, file.name));
  }
  @override
  Widget build(BuildContext context) {
    final rows = _rows.where((row) => '$row'.toLowerCase().contains(_search.toLowerCase())).toList();
    return Scaffold(appBar: const CustomAppBar(title: 'KYC Documents', showBackButton: true), body: AccountSync(authenticated: true, refresh: _load, child: Column(children: [
      TextField(decoration: const InputDecoration(labelText: 'Search KYC requests', prefixIcon: Icon(Icons.search)), onChanged: (value) => setState(() => _search = value)),
      if (_error != null) ListTile(title: Text(_error!), trailing: TextButton(onPressed: _load, child: const Text('Retry'))),
      DropdownButton<String>(value: _type, items: ['PAN_CARD', 'AADHAR_CARD', 'PASSPORT', 'BANK_STATEMENT'].map((type) => DropdownMenuItem(value: type, child: Text(type.replaceAll('_', ' ')))).toList(), onChanged: _busy ? null : (type) => setState(() => _type = type!)), TextButton.icon(onPressed: _busy ? null : _upload, icon: const Icon(Icons.upload_file), label: const Text('Submit document (up to 5 MB)')),
      if (_busy) const LinearProgressIndicator(),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: _load, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(), children: [
          if (rows.isEmpty) const ListTile(title: Text('No KYC requests')),
          for (final row in rows) Card(child: Column(children: [ListTile(
            title: Text('${row['investor']?['fullName'] ?? ''} ${row['documentType']}'),
            subtitle: Text('${row['status']}\n${row['rejectionReason'] ?? ''}'),
            trailing: IconButton(tooltip: 'View private document', icon: const Icon(Icons.visibility_outlined), onPressed: _busy ? null : () => _action(() => _view('${row['id']}')))),
            
          ])),
        ]))),
    ])));
  }
}
