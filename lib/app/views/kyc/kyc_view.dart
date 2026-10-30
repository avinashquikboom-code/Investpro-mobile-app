import 'package:remixicon/remixicon.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../controllers/kyc_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';

class KycView extends StatefulWidget {
  const KycView({super.key});

  @override
  State<KycView> createState() => _KycViewState();
}

class _KycViewState extends State<KycView> with WidgetsBindingObserver {
  final ApiService _api = Get.find<ApiService>();
  late final KycController _kyc;
  Worker? _changes;

  List<dynamic> _requests = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;

  String _selectedDocType = 'PAN_CARD';
  ({String name})? get _selectedFile =>
      _kyc.bytes.value == null ? null : (name: _kyc.fileName.value);
  int? get _selectedFileSize => _kyc.bytes.value?.length;

  final Map<String, Map<String, dynamic>> _docTypes = {
    'PAN_CARD': {
      'label': 'PAN Card',
      'desc': 'Permanent Account Number issued by Income Tax Dept',
      'icon': Remix.id_card_line,
    },
    'AADHAR_CARD': {
      'label': 'Aadhaar Card',
      'desc': 'Unique Identification Authority of India (UIDAI)',
      'icon': Remix.bank_card_line,
    },
    'PASSPORT': {
      'label': 'Passport',
      'desc': 'Government-issued passport',
      'icon': Remix.book_open_line,
    },
    'BANK_STATEMENT': {
      'label': 'Bank Statement',
      'desc': 'Bank statement',
      'icon': Remix.bank_line,
    },
  };

  @override
  void initState() {
    super.initState();
    _kyc = Get.isRegistered<KycController>()
        ? Get.find<KycController>()
        : Get.put(KycController(_api));
    WidgetsBinding.instance.addObserver(this);
    _changes = everAll([_kyc.bytes, _kyc.error, _kyc.progress], (_) {
      if (mounted) {
        setState(() {
          _errorMessage = _kyc.error.value.isEmpty ? null : _kyc.error.value;
        });
      }
    });
    _loadKycRequests();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isUploading) _loadKycRequests();
  }

  @override
  void dispose() {
    _changes?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _kyc.removeFile();
    super.dispose();
  }

  Future<void> _loadKycRequests() async {
    if (_isUploading) return;
    setState(() => _isLoading = true);
    await _kyc.load();
    if (mounted) {
      setState(() {
        _requests = _kyc.rows.toList();
        _isLoading = false;
        _errorMessage = _kyc.error.value.isEmpty ? null : _kyc.error.value;
        if (_kyc.types.isNotEmpty && !_kyc.types.contains(_selectedDocType)) {
          _selectedDocType = _kyc.selectedType.value;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    if (_isUploading) return;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (result.isEmpty || !mounted) return;
      final file = result.single;
      final size = await file.length();
      if (size == null || _kyc.maxBytes == null || size > _kyc.maxBytes!) {
        setState(
          () => _errorMessage = 'Choose a PDF, PNG or JPEG within the configured file size limit.',
        );
        return;
      }
      _kyc.selectFile(file.name, await file.readAsBytes());
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Unable to read this file. Select it again.',
        );
      }
    }
  }

  Future<void> _uploadKycDocument() async {
    if (_isUploading) return;
    _kyc.selectedType.value = _selectedDocType;
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });
    final docName = _formatDocName(_selectedDocType);
    final accepted = await _kyc.submit();
    if (!mounted) return;
    setState(() {
      _isUploading = false;
      _requests = _kyc.rows.toList();
      _errorMessage = _kyc.error.value.isEmpty ? null : _kyc.error.value;
    });
    if (accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$docName submitted successfully. Your document is pending verification.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _viewDocument(String id) async {
    try {
      final url = await _api.kycDocumentUrl(id);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Document Link', 'Could not open document viewer.');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = _kyc.safeError(e));
    }
  }

  String _formatDocName(String type) {
    return _docTypes[type]?['label'] ?? type.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVerified = _kyc.status.value == 'VERIFIED';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(
        title: 'KYC Verification',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Remix.refresh_line, color: AppColors.primary),
            tooltip: 'Refresh Status',
            onPressed: _loadKycRequests,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: RefreshIndicator(
            onRefresh: _loadKycRequests,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Status Banner
                  _buildStatusHeroCard(isVerified, isDark),
                  const SizedBox(height: 20),

                  // 2. Upload Document Card
                  Text(
                    'Upload KYC Document',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a document type and upload a clear PDF or photo.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Document Type Selector Chips
                  _buildDocTypeSelector(isDark),
                  const SizedBox(height: 16),

                  // File Dropzone / Selected File Card
                  _buildDropzone(isDark),
                  const SizedBox(height: 16),

                  // Upload Button
                  if (_selectedFile != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isUploading || _kyc.selectionError != null
                            ? null
                            : _uploadKycDocument,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Remix.upload_cloud_2_line,
                                color: Colors.white,
                                size: 20,
                              ),
                        label: Text(
                          _isUploading
                              ? 'Uploading ${(_kyc.progress.value * 100).round()}%'
                              : 'Submit ${_formatDocName(_selectedDocType)}',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  if (_isUploading)
                    LinearProgressIndicator(value: _kyc.progress.value),
                  if (_selectedFile != null && _kyc.selectionError != null)
                    Text(_kyc.selectionError!),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
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
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 3. Document Submission History
                  Text(
                    'Submitted Documents History',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (_requests.isEmpty && _errorMessage == null)
                    _buildEmptyHistory(isDark)
                  else
                    ..._requests.map((req) => _buildKycItemCard(req, isDark)),

                  const SizedBox(height: 20),

                  // 4. Verification Guidelines
                  _buildGuidelines(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeroCard(bool isVerified, bool isDark) {
    final status = _kyc.status.value;
    final label = switch (status) {
      'VERIFIED' => 'Verified',
      'PENDING' => 'Pending Review',
      'REJECTED' => 'Rejected',
      'NOT_SUBMITTED' => 'Not Submitted',
      _ => 'Status unavailable',
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lightMint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified
                    ? Remix.shield_check_line
                    : Remix.shield_line,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'KYC: $label',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isVerified ? 'Your identity verification has been approved.' : 'Submit a supported identity document for admin review. Rejected documents can be replaced and resubmitted.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDocTypeSelector(bool isDark) {
    return Column(
      children: _docTypes.entries
          .where((entry) => _kyc.types.contains(entry.key))
          .map((entry) {
            final key = entry.key;
            final data = entry.value;
            final isSelected = _selectedDocType == key;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.border),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _isUploading
                      ? null
                      : () => setState(() {
                          _selectedDocType = key;
                          _kyc.selectedType.value = key;
                        }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                      ? AppColors.surfaceDarkElevated
                                      : AppColors.secondaryBackground),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            data['icon'] as IconData,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['label'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                data['desc'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Remix.checkbox_circle_line
                              : Remix.radio_button_line,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.border),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          })
          .toList(),
    );
  }

  Widget _buildDropzone(bool isDark) {
    final bytes = _kyc.bytes.value;
    final isPdf = bytes != null &&
        bytes.length >= 5 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bytes != null
              ? AppColors.primary.withValues(alpha: 0.35)
              : (isDark ? AppColors.borderDark : AppColors.border),
          width: bytes != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (bytes != null) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Ready to submit',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${((_selectedFileSize ?? 0) / 1024).toStringAsFixed(1)} KB',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isPdf ? Remix.file_pdf_2_line : Remix.image_2_line,
                  color: isPdf ? AppColors.error : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFile?.name ?? 'Selected file',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isPdf &&
                bytes.isNotEmpty &&
                (bytes[0] == 137 || bytes[0] == 255))
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  color: isDark
                      ? AppColors.surfaceDarkElevated
                      : AppColors.secondaryBackground,
                  child: Image.memory(
                    bytes,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stack) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Image preview unavailable. Replace damaged files.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDarkElevated
                      : AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPdf ? Remix.file_pdf_2_line : Remix.file_text_line,
                      color: isPdf ? AppColors.error : AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        isPdf ? 'PDF Document Ready' : 'Document Attached',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _isUploading ? null : _kyc.removeFile,
                  icon: const Icon(
                    Remix.delete_bin_line,
                    size: 16,
                    color: AppColors.error,
                  ),
                  label: Text(
                    'Remove File',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _isUploading || _kyc.maxBytes == null ? null : _pickFile,
            icon: Icon(
              bytes == null ? Remix.attachment_2 : Remix.refresh_line,
              size: 18,
              color: AppColors.primary,
            ),
            label: Text(
              bytes == null ? 'Select document' : 'Replace document',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _kyc.maxBytes == null
                ? 'Loading file requirements…'
                : 'PDF, PNG or JPEG · Maximum ${(_kyc.maxBytes! / (1024 * 1024)).toStringAsFixed(0)} MB',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKycItemCard(dynamic req, bool isDark) {
    final status = (req['status']?.toString() ?? 'PENDING').toUpperCase();
    final docType = req['documentType']?.toString() ?? '';
    final rejectionReason = req['rejectionReason']?.toString();
    final id = req['id']?.toString() ?? '';

    Color badgeBg;
    Color badgeText;
    IconData statusIcon;

    switch (status) {
      case 'APPROVED':
      case 'VERIFIED':
        badgeBg = AppColors.success.withValues(alpha: 0.12);
        badgeText = AppColors.success;
        statusIcon = Remix.checkbox_circle_line;
        break;
      case 'REJECTED':
        badgeBg = AppColors.error.withValues(alpha: 0.12);
        badgeText = AppColors.error;
        statusIcon = Remix.close_circle_line;
        break;
      default:
        badgeBg = AppColors.warning.withValues(alpha: 0.12);
        badgeText = AppColors.warning;
        statusIcon = Remix.time_line;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Remix.shield_line,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDocName(docType),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${id.length > 8 ? id.substring(0, 8) : id}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: badgeText, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: badgeText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Remix.information_line,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rejection reason: $rejectionReason',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _viewDocument(id),
                    icon: const Icon(Remix.eye_line, size: 16),
                    label: Text(
                      'View Document',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Remix.folder_open_line,
            size: 36,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            'No KYC Records Found',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Upload a document above to begin verification.',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelines(bool isDark) {
    final rules = [
      'Document photo must be sharp, in color, and completely legible.',
      'All 4 corners of the identity card must be clearly visible in the image.',
      'Review any rejection reason before replacing and resubmitting a document.',
      'Documents are stored privately and require authorized viewing links.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Remix.verified_badge_line,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Submission Guidelines',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rule,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
