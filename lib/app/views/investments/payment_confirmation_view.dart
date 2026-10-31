import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remixicon/remixicon.dart';

import '../../controllers/investment_controller.dart';
import '../../services/api_service.dart';
import '../../services/payment_error.dart';
import '../../services/offline_payment_config.dart';

import 'package:flutter/foundation.dart';

import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/unsaved_changes_guard.dart';

/// Redesigned production-ready Confirm Payment view matching reference layout.
class PaymentConfirmationView extends StatefulWidget {
  const PaymentConfirmationView({super.key});

  @override
  State<PaymentConfirmationView> createState() =>
      _PaymentConfirmationViewState();
}

class _PaymentConfirmationViewState extends State<PaymentConfirmationView>
    with WidgetsBindingObserver {
  final TextEditingController _utrController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Map<String, dynamic>? settings;
  bool _settingsLoading = false;
  String? _settingsError;
  Future<void>? _settingsRequest;
  String _transferMethod = 'BANK_TRANSFER';
  String? _lastEligibilityDiagnostic;
  PlatformFile? _proofFile;
  Uint8List? _proofBytes;
  double _uploadProgress = 0.0;
  String? _utrError;
  String? _proofError;
  String? _paymentError;
  Map<String, dynamic>? _submittedData;
  Directory? _previewDirectory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final invCtrl = Get.find<InvestmentController>();
    if (invCtrl.selectedPaymentMethod.value != 'Offline Payment' &&
        invCtrl.selectedPaymentMethod.value != 'Razorpay Checkout') {
      invCtrl.selectedPaymentMethod.value = 'Razorpay Checkout';
    }
    invCtrl.agreeToTerms.value = false;

    _utrController.addListener(() {
      _validateUtr(_utrController.text);
      if (mounted) {
        setState(() {});
      } // Every edit can change submission eligibility.
    });

    if (invCtrl.isLive) {
      _loadSettings();
    } else {
      settings = OfflinePaymentConfig.parse({
        'enabled': true,
        'accountHolderName': 'InvestPro Capital PVT LTD',
        'bankName': 'HDFC Bank',
        'accountNumber': '50200012345678',
        'ifscCode': 'HDFC0001234',
        'upiId': 'investpro@hdfcbank',
        'maxBytes': 5242880,
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !Get.find<InvestmentController>().isProcessingPayment.value) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() {
    if (!Get.find<InvestmentController>().isLive) return Future.value();
    if (_settingsRequest != null) return _settingsRequest!;
    final task = _fetchSettings();
    _settingsRequest = task;
    return task.whenComplete(() => _settingsRequest = null);
  }

  Future<void> _fetchSettings() async {
    if (mounted) {
      setState(() {
        _settingsLoading = true;
        _settingsError = null;
      });
    }
    try {
      final value = OfflinePaymentConfig.parse(
        await Get.find<ApiService>().object(
          '/mobile/investments/offline-payment/settings',
        ),
      );
      if (!mounted) return;
      setState(() {
        settings = value;
        final methods = value['acceptedMethods'] as List;
        if (!methods.contains(_transferMethod) && methods.isNotEmpty) {
          _transferMethod = methods.first as String;
        }
      });
      if (kDebugMode) {
        debugPrint(
          'Offline settings enabled=${value['enabled']} configured=${value['configured']} proofRequired=true methods=${(value['acceptedMethods'] as List).join(',')} maxBytes=${value['maxBytes']}',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _settingsError = error is FormatException
              ? error.message
              : PaymentError.message(
                  error,
                  fallback: 'Unable to load payment settings. Please refresh.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => _settingsLoading = false);
    }
  }

  String? _offlineBlocker(InvestmentController controller) {
    if (_settingsLoading) return 'Checking offline payment availability…';
    if (_settingsError != null) return _settingsError;
    if (settings == null) return 'Load payment settings before continuing.';
    if (settings!['enabled'] != true) {
      return 'Offline payment is currently disabled by the administrator. Please select Razorpay Checkout.';
    }
    if (settings!['configured'] != true) {
      return 'Offline payment instructions are incomplete. Please use Razorpay Checkout or contact support.';
    }
    if (controller.currentProject.value == null) return 'Select a project.';
    if (controller.amountError != null) return controller.amountError;
    if (!OfflinePaymentConfig.validReference(_utrController.text)) {
      return 'Enter a valid payment reference (6–64 letters or digits; / and - are allowed separators).';
    }
    if (_proofBytes == null || _proofFile == null) {
      return 'Select a JPG, PNG or PDF payment proof to upload with your submission.';
    }
    if (_proofError != null) return _proofError;
    if (!controller.agreeToTerms.value) {
      return 'Accept the Investment Terms & Risk Disclosures to continue.';
    }
    if (controller.isProcessingPayment.value) {
      return 'Uploading proof and submitting payment details…';
    }
    return null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _utrController.dispose();
    _previewDirectory
        ?.delete(recursive: true)
        .catchError((Object _) => _previewDirectory!);
    super.dispose();
  }

  void _validateUtr(String value) {
    final trimmed = value.trim().toUpperCase();
    if (trimmed.isEmpty) {
      if (_utrError != null) setState(() => _utrError = null);
    } else if (!OfflinePaymentConfig.validReference(trimmed)) {
      if (_utrError != 'Enter a valid payment reference (6–64 characters).') {
        setState(
          () =>
              _utrError = 'Enter a valid payment reference (6–64 characters).',
        );
      }
    } else {
      if (_utrError != null) setState(() => _utrError = null);
    }
  }

  Future<void> _pickFile() async {
    if (Get.find<InvestmentController>().isProcessingPayment.value) return;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (!mounted || result.isEmpty) return;
      final file = result.single;
      final maxBytes = (settings?['maxBytes'] as num?)?.toInt() ?? 5242880;
      final length = await file.length();
      if (length == null || length <= 0 || length > maxBytes) {
        throw const FormatException('Select a file of at most 5 MB');
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > maxBytes) {
        throw FormatException(
          'Select a non-empty file of at most ${_formatBytes(maxBytes)}',
        );
      }
      _validateMime(bytes);
      if (!mounted) return;
      setState(() {
        _proofFile = file;
        _proofBytes = bytes;
        _proofError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _proofError = e
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('FormatException: ', ''),
        );
      }
    }
  }

  String _validateMime(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71 &&
        bytes[4] == 13 &&
        bytes[5] == 10 &&
        bytes[6] == 26 &&
        bytes[7] == 10) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      return 'image/jpeg';
    }
    if (bytes.length >= 5 &&
        ascii.decode(bytes.sublist(0, 5), allowInvalid: true) == '%PDF-') {
      return 'application/pdf';
    }
    throw const FormatException('Select a valid JPG, PNG or PDF');
  }

  bool get _isImageProof {
    if (_proofBytes == null) return false;
    try {
      return _validateMime(_proofBytes!).startsWith('image/');
    } catch (_) {
      return false;
    }
  }

  Future<void> _previewPdf() async {
    if (_proofBytes == null) return;
    try {
      final directory = await getTemporaryDirectory();
      _previewDirectory ??= await Directory(
        '${directory.path}/investpro-payment-preview-',
      ).createTemp();
      final file = File('${_previewDirectory!.path}/payment-proof.pdf');
      await file.writeAsBytes(_proofBytes!, flush: true);
      final result = await OpenFilex.open(file.path, type: 'application/pdf');
      if (result.type != ResultType.done) {
        throw const FormatException(
          'No PDF viewer is available on this device.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _proofError = e
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('FormatException: ', ''),
        );
      }
    }
  }

  void _copyToClipboard(String label, String value) {
    if (value.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: value.trim()));
    Get.snackbar(
      'Copied',
      '$label copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      icon: const Icon(Remix.check_line, color: Colors.white),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Remix.shield_check_line,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Terms & Risk Disclosures',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please review the following investment terms carefully:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTermBullet(
                  'Capital Commitment',
                  'Investments are committed for the specified duration. Early withdrawal or liquidity options are subject to administrative guidelines.',
                  isDark,
                ),
                const SizedBox(height: 8),
                _buildTermBullet(
                  'Projected Returns',
                  'All returns are contractual projected estimates and subject to commercial project execution.',
                  isDark,
                ),
                const SizedBox(height: 8),
                _buildTermBullet(
                  'Payment Verification',
                  'Offline payments require verification against bank statements before investment activation. Submitting details does not immediately activate investments.',
                  isDark,
                ),
                const SizedBox(height: 8),
                _buildTermBullet(
                  'Regulatory Compliance',
                  'By continuing, you confirm that you are investing legally sourced funds and agree to all platform dispute resolution policies.',
                  isDark,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTermBullet(String title, String desc, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(
            Remix.checkbox_circle_fill,
            color: AppColors.primary,
            size: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitOfflinePayment() async {
    final invCtrl = Get.find<InvestmentController>();
    if (invCtrl.isProcessingPayment.value) return;

    final utr = _utrController.text.trim().toUpperCase();
    if (!OfflinePaymentConfig.validReference(utr)) {
      setState(
        () => _utrError = 'Enter a valid payment reference (6–64 characters).',
      );
      return;
    }
    if (_proofFile == null || _proofBytes == null) {
      setState(() => _proofError = 'Please upload a valid payment proof.');
      return;
    }
    if (!invCtrl.agreeToTerms.value) {
      Get.snackbar(
        'Terms Required',
        'Please accept the Investment Terms & Risk Disclosures.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final blocker = _offlineBlocker(invCtrl);
    if (blocker != null) {
      setState(() => _paymentError = blocker);
      return;
    }
    invCtrl.isProcessingPayment.value = true;
    setState(() {
      _paymentError = null;
      _uploadProgress = 0.0;
    });

    try {
      final project = invCtrl.currentProject.value;
      if (project == null) throw const FormatException('Project not selected');

      if (!invCtrl.isLive) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        setState(() {
          _submittedData = {
            'id':
                'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
            'status': 'PENDING_VERIFICATION',
            'amount': invCtrl.investmentAmount.value,
            'utrNumber': utr,
          };
        });
        return;
      }

      final methodBeforeRefresh = _transferMethod;
      final destinationBeforeRefresh = settings;
      final session = Get.find<ApiService>().sessionVersion;
      await _loadSettings();
      if (!mounted) return;
      if (Get.find<ApiService>().sessionVersion != session) {
        throw const PaymentFailure(
          'Your session changed. Reopen Confirm Payment to continue.',
        );
      }
      if (_settingsError != null ||
          settings?['enabled'] != true ||
          settings?['configured'] != true) {
        throw PaymentFailure(
          _settingsError ??
              'Offline payment is unavailable. Please use Razorpay Checkout.',
        );
      }
      final destinationFields = methodBeforeRefresh == 'UPI'
          ? ['upiId']
          : ['accountHolderName', 'bankName', 'accountNumber', 'ifscCode'];
      if (methodBeforeRefresh != _transferMethod ||
          destinationFields.any(
            (field) => destinationBeforeRefresh?[field] != settings?[field],
          )) {
        throw const PaymentFailure(
          'Payment instructions changed. Please review the updated destination before submitting.',
        );
      }
      final slot =
          'offline_request_${base64Url.encode(utf8.encode('${project.id}:${invCtrl.investmentAmount.value}:$utr'))}';
      var key = await _storage.read(key: slot);
      key ??= base64Url.encode(
        List<int>.generate(24, (_) => Random.secure().nextInt(256)),
      );
      await _storage.write(key: slot, value: key);

      if (!mounted || Get.find<ApiService>().sessionVersion != session) {
        throw const PaymentFailure(
          'Your session changed. Reopen Confirm Payment to continue.',
        );
      }
      if (kDebugMode) {
        debugPrint(
          'Offline submit eligible=true enabled=true configured=true referenceValid=true proofSelected=true termsAccepted=true; proof uploads in this request',
        );
      }
      final response = await Get.find<ApiService>().dio.post(
        '/mobile/investments/offline-payment',
        data: FormData.fromMap({
          'projectId': project.id,
          'amount': invCtrl.investmentAmount.value.toString(),
          'paymentMethod': 'OFFLINE',
          'transferMethod': _transferMethod,
          'utrNumber': utr,
          'termsAccepted': 'true',
          'idempotencyKey': key,
          'paymentProof': MultipartFile.fromBytes(
            _proofBytes!,
            filename: _proofFile!.name,
            contentType: DioMediaType.parse(_validateMime(_proofBytes!)),
          ),
        }),
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
        onSendProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );

      if (!mounted || Get.find<ApiService>().sessionVersion != session) return;
      final body = response.data;
      if (body is! Map ||
          body['success'] != true ||
          body['data'] is! Map ||
          ![
            'PENDING_VERIFICATION',
            'APPROVED',
            'REJECTED',
          ].contains(body['data']['status']) ||
          body['data']['id'] == null) {
        throw const PaymentFailure(
          'The server did not confirm your payment request. Retry safely with the same details.',
        );
      }
      if (mounted) {
        setState(
          () => _submittedData = Map<String, dynamic>.from(body['data'] as Map),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _paymentError = PaymentError.message(e));
      }
    } finally {
      invCtrl.isProcessingPayment.value = false;
      if (mounted) setState(() {});
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final invCtrl = Get.find<InvestmentController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return UnsavedChangesGuard(
      controllers: [_utrController],
      changes: [
        invCtrl.selectedPaymentMethod.stream,
        invCtrl.agreeToTerms.stream,
      ],
      snapshot: () =>
          '${invCtrl.selectedPaymentMethod.value}|${invCtrl.agreeToTerms.value}|${_utrController.text}|${_proofFile?.name ?? ''}',
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.background,
        appBar: CustomAppBar(
          title: 'confirmPayment'.tr,
          backgroundColor: isDark
              ? AppColors.backgroundDark
              : AppColors.background,
          titleColor: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimary,
        ),
        body: SafeArea(
          child: ResponsiveHelper.responsiveContainer(
            context: context,
            maxWidth: 600,
            child: Obx(() {
              final project = invCtrl.currentProject.value;
              if (project == null) {
                return const Center(child: Text('No project selected'));
              }

              final calc = invCtrl.calculationResult;
              final isOffline =
                  invCtrl.selectedPaymentMethod.value == 'Offline Payment';

              if (_submittedData != null) {
                return _buildSubmittedView(isDark);
              }

              final offlineBlocker = _offlineBlocker(invCtrl);
              final canSubmitOffline = offlineBlocker == null;
              if (kDebugMode && isOffline) {
                final diagnostic =
                    'Offline eligibility enabled=${settings?['enabled'] == true} configured=${settings?['configured'] == true} settingsLoading=$_settingsLoading settingsFailed=${_settingsError != null} projectSelected=true amountValid=${invCtrl.amountError == null} referenceValid=${OfflinePaymentConfig.validReference(_utrController.text)} proofSelected=${_proofFile != null && _proofBytes != null} termsAccepted=${invCtrl.agreeToTerms.value} processing=${invCtrl.isProcessingPayment.value} canSubmit=$canSubmitOffline';
                if (diagnostic != _lastEligibilityDiagnostic) {
                  debugPrint(diagnostic);
                  _lastEligibilityDiagnostic = diagnostic;
                }
              }
              final canSubmitOnline =
                  !invCtrl.isProcessingPayment.value &&
                  invCtrl.agreeToTerms.value &&
                  invCtrl.amountError == null;

              final canSubmit = isOffline ? canSubmitOffline : canSubmitOnline;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Investment Summary Card
                    _buildInvestmentSummaryCard(project.name, calc, isDark),
                    const SizedBox(height: 24),

                    // 2. Payment Method Selection Heading & Cards
                    Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentMethodCard(
                      title: 'Razorpay Checkout',
                      subtitle: 'Cards, NetBanking, UPI, Wallets',
                      icon: Remix.lock_line,
                      isSelected: !isOffline,
                      onTap: invCtrl.isProcessingPayment.value
                          ? null
                          : () => invCtrl.setPaymentMethod('Razorpay Checkout'),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentMethodCard(
                      title: 'Offline Payment',
                      subtitle: _settingsLoading
                          ? 'Checking availability…'
                          : settings?['enabled'] == false
                          ? 'Unavailable • disabled by the administrator'
                          : 'Bank Transfer / UPI • admin verification required',
                      icon: Remix.bank_line,
                      isSelected: isOffline,
                      onTap:
                          invCtrl.isProcessingPayment.value ||
                              _settingsLoading ||
                              settings?['enabled'] != true ||
                              settings?['configured'] != true ||
                              _settingsError != null
                          ? null
                          : () {
                              invCtrl.setPaymentMethod('Offline Payment');
                              _loadSettings();
                            },
                      isDark: isDark,
                    ),

                    if (!isOffline &&
                        !_settingsLoading &&
                        (_settingsError != null ||
                            settings?['enabled'] != true ||
                            settings?['configured'] != true))
                      TextButton(
                        onPressed: invCtrl.isProcessingPayment.value
                            ? null
                            : _loadSettings,
                        child: const Text('Refresh payment settings'),
                      ),

                    // 3. Conditional Offline Payment Section
                    if (isOffline) ...[
                      const SizedBox(height: 20),
                      _buildOfflinePaymentInstructionsCard(isDark),
                      const SizedBox(height: 18),
                      if (!_settingsLoading &&
                          _settingsError == null &&
                          settings?['enabled'] == true &&
                          settings?['configured'] == true) ...[
                        if ((settings!['acceptedMethods'] as List).length > 1)
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final method
                                  in settings!['acceptedMethods'] as List)
                                ChoiceChip(
                                  label: Text(
                                    method == 'UPI' ? 'UPI' : 'Bank Transfer',
                                  ),
                                  selected: _transferMethod == method,
                                  onSelected: invCtrl.isProcessingPayment.value
                                      ? null
                                      : (_) => setState(
                                          () => _transferMethod =
                                              method as String,
                                        ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        _buildUtrField(isDark),
                        const SizedBox(height: 18),
                        _buildProofUploadContainer(isDark),
                      ],
                    ],

                    const SizedBox(height: 20),

                    // 4. Demo indicators & failure simulations (if in demo mode)
                    if (!invCtrl.isLive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Remix.information_line,
                              color: Color(0xFFD97706),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'DEMO PAYMENT • No real money is charged.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Simulate payment failure'),
                        value: invCtrl.simulateFailure.value,
                        onChanged: invCtrl.isProcessingPayment.value
                            ? null
                            : (v) => invCtrl.simulateFailure.value = v,
                      ),
                    ],

                    // Inline Error Banners
                    if (_paymentError != null ||
                        invCtrl.paymentError.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Remix.error_warning_line,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _paymentError ?? invCtrl.paymentError.value,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 5. Terms and Risk Disclosure Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: invCtrl.agreeToTerms.value,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: invCtrl.isProcessingPayment.value
                                ? null
                                : invCtrl.toggleTerms,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: invCtrl.isProcessingPayment.value
                                ? null
                                : () => invCtrl.toggleTerms(
                                    !invCtrl.agreeToTerms.value,
                                  ),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: GestureDetector(
                                      onTap: _showTermsDialog,
                                      child: const Text(
                                        'Investment Terms & Risk Disclosures',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' and acknowledge that returns are projected estimates.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (isOffline && offlineBlocker != null) ...[
                      Text(
                        offlineBlocker,
                        key: const ValueKey('offline-submit-reason'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // 6. Bottom Payment Action Button
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: isDark
                            ? AppColors.surfaceDarkElevated
                            : const Color(0xFFD1D5DB),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: canSubmit
                          ? () {
                              if (isOffline) {
                                _submitOfflinePayment();
                              } else {
                                invCtrl.confirmAndPay();
                              }
                            }
                          : null,
                      child: invCtrl.isProcessingPayment.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isOffline
                                  ? 'Submit Payment Details'
                                  : 'Proceed to Pay ${CurrencyFormatter.format(calc.principal)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: canSubmit
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.textSecondaryDark
                                          : const Color(0xFF6B7280)),
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentSummaryCard(
    String projectName,
    dynamic calc,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            projectName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'amountInvested'.tr,
            CurrencyFormatter.format(calc.principal),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'expectedReturnTotal'.tr,
            CurrencyFormatter.format(calc.expectedTotalReturn),
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'maturityAmount'.tr,
            CurrencyFormatter.format(calc.projectedMaturityAmount),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'investmentPeriod'.tr,
            '${calc.durationMonths} Months',
            isDark: isDark,
          ),
          Divider(
            height: 24,
            color: isDark ? AppColors.borderDark : AppColors.divider,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Total Payable',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  CurrencyFormatter.format(calc.principal),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? color,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  color ??
                  (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    final bgColor = isSelected
        ? (isDark ? AppColors.surfaceDarkElevated : AppColors.lightMint)
        : (isDark ? AppColors.surfaceDark : Colors.white);

    final borderColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.borderDark : AppColors.border);

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: isSelected ? 1.5 : 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : (isDark
                            ? AppColors.surfaceDarkElevated
                            : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflinePaymentInstructionsCard(bool isDark) {
    if (_settingsError != null ||
        (!_settingsLoading &&
            settings != null &&
            (settings!['enabled'] != true ||
                settings!['configured'] != true))) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _settingsError ??
                  (settings!['enabled'] != true
                      ? 'Offline payment is currently disabled by the administrator.'
                      : 'Offline payment instructions are incomplete.'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed:
                      Get.find<InvestmentController>().isProcessingPayment.value
                      ? null
                      : _loadSettings,
                  child: const Text('Refresh payment settings'),
                ),
                TextButton(
                  onPressed: () => Get.find<InvestmentController>()
                      .setPaymentMethod('Razorpay Checkout'),
                  child: const Text('Use Razorpay Checkout'),
                ),
              ],
            ),
          ],
        ),
      );
    }
    if (_settingsLoading || settings == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDarkElevated : AppColors.lightMint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.borderDark
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : AppColors.lightMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.primary.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Remix.bank_line, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Offline Payment Instructions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.primaryDark,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh payment settings',
                onPressed:
                    Get.find<InvestmentController>().isProcessingPayment.value
                    ? null
                    : _loadSettings,
                icon: const Icon(
                  Remix.refresh_line,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Transfer the exact investment amount to the company bank account or UPI ID below, then enter your UTR and upload proof of payment.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          Divider(
            height: 20,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          if ((settings!['accountHolderName'] ?? '').toString().isNotEmpty)
            _buildBankDetailRow(
              label: 'Account Name',
              value: settings!['accountHolderName'].toString(),
              canCopy: false,
              isDark: isDark,
            ),
          if ((settings!['bankName'] ?? '').toString().isNotEmpty)
            _buildBankDetailRow(
              label: 'Bank Name',
              value: settings!['bankName'].toString(),
              canCopy: false,
              isDark: isDark,
            ),
          if ((settings!['accountNumber'] ?? '').toString().isNotEmpty)
            _buildBankDetailRow(
              label: 'Account Number',
              value: settings!['accountNumber'].toString(),
              canCopy: true,
              isDark: isDark,
            ),
          if ((settings!['ifscCode'] ?? '').toString().isNotEmpty)
            _buildBankDetailRow(
              label: 'IFSC Code',
              value: settings!['ifscCode'].toString(),
              canCopy: true,
              isDark: isDark,
            ),
          if ((settings!['upiId'] ?? '').toString().isNotEmpty)
            _buildBankDetailRow(
              label: 'UPI ID',
              value: settings!['upiId'].toString(),
              canCopy: true,
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildBankDetailRow({
    required String label,
    required String value,
    bool canCopy = false,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: SelectableText(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (canCopy) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _copyToClipboard(label, value),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Remix.file_copy_line,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtrField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Reference / UTR Number',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const ValueKey('offline-utr'),
          readOnly: Get.find<InvestmentController>().isProcessingPayment.value,
          controller: _utrController,
          textCapitalization: TextCapitalization.characters,
          keyboardType: TextInputType.text,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9/-]')),
            LengthLimitingTextInputFormatter(64),
          ],
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Enter UTR / Reference Number',
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorText: _utrError,
            prefixIcon: const Icon(
              Remix.hashtag,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProofUploadContainer(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Payment Proof',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (_proofFile == null)
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(14),
            child: CustomPaint(
              painter: DashedRectPainter(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.primary.withValues(alpha: 0.5),
                dash: 6.0,
                gap: 4.0,
                radius: 14.0,
                strokeWidth: 1.4,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : const Color(0xFFFAFCFA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Remix.upload_cloud_2_line,
                        size: 26,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Upload Payment Proof',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG or PDF (Max 5 MB)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDarkElevated
                  : AppColors.lightMint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                if (_isImageProof && _proofBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _proofBytes!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Remix.file_pdf_2_line,
                      size: 28,
                      color: Colors.red,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _proofFile!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatBytes(_proofBytes?.length ?? 0)} • Selected, not uploaded yet',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (!_isImageProof)
                        InkWell(
                          onTap: _previewPdf,
                          child: const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              'Preview PDF',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Replace attachment',
                      icon: const Icon(
                        Remix.refresh_line,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      onPressed: _pickFile,
                    ),
                    IconButton(
                      tooltip: 'Remove attachment',
                      icon: const Icon(
                        Remix.delete_bin_line,
                        size: 20,
                        color: AppColors.error,
                      ),
                      onPressed:
                          Get.find<InvestmentController>()
                              .isProcessingPayment
                              .value
                          ? null
                          : () => setState(() {
                              _proofFile = null;
                              _proofBytes = null;
                            }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (_uploadProgress > 0 && _uploadProgress < 1.0) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
        ],
        if (_proofError != null) ...[
          const SizedBox(height: 6),
          Text(
            _proofError!,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmittedView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.lightMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Remix.check_line,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Payment details submitted',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Status: ${_submittedData!['status'] ?? 'PENDING_VERIFICATION'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              'Request: ${_submittedData!['id'] ?? ''}\nStatus: ${_submittedData!['status'] ?? ''}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Your investment remains pending until an administrator verifies receipt. Do not pay again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Get.back(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight, mathematically exact dashed border painter for rounded rectangles.
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  const DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dash = 6.0,
    this.gap = 4.0,
    this.radius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dash < metric.length)
            ? dash
            : metric.length - distance;
        final extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedRectPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dash != oldDelegate.dash ||
      gap != oldDelegate.gap ||
      radius != oldDelegate.radius;
}
