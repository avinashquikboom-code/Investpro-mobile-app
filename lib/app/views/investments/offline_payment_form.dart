import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../../controllers/investment_controller.dart';
import '../../services/api_service.dart';
import '../../services/payment_error.dart';
import '../../theme/app_colors.dart';

class OfflinePaymentForm extends StatefulWidget {
  final Map<String, dynamic> settings;
  final InvestmentController controller;
  final Map<String, dynamic>? resubmission;
  const OfflinePaymentForm({super.key, required this.settings, required this.controller, this.resubmission});
  @override
  State<OfflinePaymentForm> createState() => _OfflinePaymentFormState();
}
class _OfflinePaymentFormState extends State<OfflinePaymentForm> {
  final reference = TextEditingController();
  final storage = const FlutterSecureStorage();
  PlatformFile? proof;
  Uint8List? proofBytes;
  double progress = 0;
  bool agreed = false;
  Directory? previewDirectory;
  String? error;
  Map<String, dynamic>? submitted;
  bool get busy => widget.controller.isProcessingPayment.value;
  @override
  void dispose() { reference.dispose(); previewDirectory?.delete(recursive: true).catchError((Object _) => previewDirectory!); super.dispose(); }
  Future<void> pick() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf']);
      if (!mounted || result.isEmpty) return;
      final file = result.single;
      final length = await file.length();
      if (length == null || length > (widget.settings['maxBytes'] as num? ?? 5242880)) throw const FormatException('Select a file of at most 5 MB');
      final bytes = await file.readAsBytes();
      mime(bytes);
      setState(() { proof = file; proofBytes = bytes; error = null; });
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
  }
  String mime(Uint8List bytes) {
    if (bytes.length >= 8 && bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71 && bytes[4] == 13 && bytes[5] == 10 && bytes[6] == 26 && bytes[7] == 10) return 'image/png';
    if (bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255) return 'image/jpeg';
    if (bytes.length >= 5 && ascii.decode(bytes.sublist(0, 5), allowInvalid: true) == '%PDF-') return 'application/pdf';
    throw const FormatException('Select a valid JPG, PNG or PDF');
  }
  Future<void> previewPdf() async {
    try {
      final directory = await getTemporaryDirectory();
      previewDirectory ??= await Directory('${directory.path}/investpro-payment-preview-').createTemp();
      final file = File('${previewDirectory!.path}/payment-proof.pdf');
      await file.writeAsBytes(proofBytes!, flush: true);
      final result = await OpenFilex.open(file.path, type: 'application/pdf');
      if (result.type != ResultType.done) throw const FormatException('No PDF viewer is available on this device.');
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
  }
  Future<void> send() async {
    if (busy || !agreed || proof == null) return;
    final utr = widget.resubmission?['utrNumber']?.toString() ?? reference.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9][A-Z0-9/-]{5,63}$').hasMatch(utr)) { setState(() => error = 'Enter a valid payment reference (6–64 characters).'); return; }
    widget.controller.isProcessingPayment.value = true;
    setState(() { error = null; progress = 0; });
    try {
      final project = widget.controller.currentProject.value;
      final correction = widget.resubmission;
      // Persist by immutable request fields so uncertain responses and app restarts reuse the key.
      final slot = correction != null ? 'offline_resubmit_${correction['id']}_${correction['reviewedAt']}' : 'offline_request_${base64Url.encode(utf8.encode('${project!.id}:${widget.controller.investmentAmount.value}:$utr'))}';
      var key = await storage.read(key: slot);
      key ??= base64Url.encode(List<int>.generate(24, (_) => Random.secure().nextInt(256)));
      await storage.write(key: slot, value: key);
      final response = await Get.find<ApiService>().dio.post(correction == null ? '/mobile/investments/offline-payment' : '/mobile/investments/offline-payment/${correction['id']}/resubmit', data: FormData.fromMap({
        if (correction == null) ...{'projectId': project!.id, 'amount': widget.controller.investmentAmount.value.toString(), 'paymentMethod': 'OFFLINE', 'utrNumber': utr}, 'termsAccepted': 'true', 'idempotencyKey': key,
        'paymentProof': MultipartFile.fromBytes(proofBytes!, filename: proof!.name, contentType: DioMediaType.parse(mime(proofBytes!))),
      }), options: Options(receiveTimeout: const Duration(seconds: 60), sendTimeout: const Duration(seconds: 60)), onSendProgress: (sent, total) { if (mounted && total > 0) setState(() => progress = sent / total); });
      if (mounted) setState(() => submitted = Map<String, dynamic>.from(response.data['data'] as Map));
    } catch (e) { if (mounted) setState(() => error = PaymentError.message(e)); }
    finally { widget.controller.isProcessingPayment.value = false; if (mounted) setState(() {}); }
  }
  @override
  Widget build(BuildContext context) {
    if (submitted != null) {
      return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Payment details submitted', style: TextStyle(fontWeight: FontWeight.bold)),
      SelectableText('Request: ${submitted!['id']}\nStatus: ${submitted!['status']}'),
      const Text('Your investment remains pending until an administrator verifies receipt. Do not pay again.'),
      TextButton(onPressed: () => Get.back(), child: const Text('Done')),
    ])));
    }
    return PopScope(canPop: !busy, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Offline Payment Instructions', style: TextStyle(fontWeight: FontWeight.w700)),
      const Text('Bank Transfer / UPI. Use the destination below. Proof alone does not confirm receipt.'),
      for (final field in {'accountHolderName': 'Account Holder Name', 'bankName': 'Bank Name', 'accountNumber': 'Account Number', 'ifscCode': 'IFSC Code', 'upiId': 'UPI ID'}.entries)
        if ((widget.settings[field.key] ?? '').toString().isNotEmpty)
          ListTile(contentPadding: EdgeInsets.zero, title: Text(field.value), subtitle: SelectableText(widget.settings[field.key].toString()), trailing: ['accountNumber', 'ifscCode', 'upiId'].contains(field.key) ? IconButton(tooltip: 'Copy ${field.value}', icon: const Icon(Icons.copy), onPressed: () => Clipboard.setData(ClipboardData(text: widget.settings[field.key].toString()))) : null),
      const Text('Projected returns are estimates and subject to investment risk.'),
      if (widget.resubmission != null) Text('Corrected proof for UTR ${widget.resubmission!['utrNumber']}. The project, amount and transfer reference stay the same. Contact support if the reference itself needs correction.'),
      if (widget.resubmission == null) TextField(controller: reference, enabled: !busy, decoration: const InputDecoration(labelText: 'Payment Reference / UTR Number'), maxLength: 64),
      OutlinedButton.icon(onPressed: busy ? null : pick, icon: const Icon(Icons.attach_file), label: Text(proof == null ? 'Upload Proof (JPG, PNG, PDF · 5 MB)' : 'Replace attachment')),
      if (proof != null) ...[
        Text(proof!.name),
        if (mime(proofBytes!).startsWith('image/')) Image.memory(proofBytes!, height: 180, fit: BoxFit.contain)
        else TextButton(onPressed: previewPdf, child: const Text('Preview selected PDF')),
        TextButton(onPressed: busy ? null : () => setState(() => proof = null), child: const Text('Remove attachment')),
      ],
      CheckboxListTile(contentPadding: EdgeInsets.zero, value: agreed, onChanged: busy ? null : (v) => setState(() => agreed = v ?? false), title: const Text('I accept the Investment Terms & Risk Disclosure. Returns are not guaranteed.')),
      if (busy) LinearProgressIndicator(value: progress),
      if (error != null) Text(error!, style: const TextStyle(color: AppColors.error)),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.primary), onPressed: busy || !agreed || proof == null ? null : send, child: Text(busy ? 'Submitting…' : 'Submit Payment Details')),
    ]));
  }
}
