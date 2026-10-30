import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/demo_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';

class KycView extends StatefulWidget {
  const KycView({super.key});

  @override
  State<KycView> createState() => _KycViewState();
}

class _KycViewState extends State<KycView> {
  final ApiService _api = Get.find<ApiService>();
  final DemoRepository _repo = Get.find<DemoRepository>();

  List<dynamic> _requests = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;

  String _selectedDocType = 'PAN_CARD';
  PlatformFile? _selectedFile;
  int? _selectedFileSize;

  final Map<String, Map<String, dynamic>> _docTypes = {
    'PAN_CARD': {
      'label': 'PAN Card',
      'desc': 'Permanent Account Number issued by Income Tax Dept',
      'icon': Icons.badge_outlined,
    },
    'AADHAR_CARD': {
      'label': 'Aadhaar Card',
      'desc': 'Unique Identification Authority of India (UIDAI)',
      'icon': Icons.credit_card_rounded,
    },
    'PASSPORT': {
      'label': 'Passport',
      'desc': 'Government-issued Indian Passport (front & back)',
      'icon': Icons.menu_book_rounded,
    },
    'BANK_STATEMENT': {
      'label': 'Bank Statement',
      'desc': 'Last 3 months certified bank account statement',
      'icon': Icons.account_balance_outlined,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadKycRequests();
  }

  Future<void> _loadKycRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rows = await _api.kyc();
      if (mounted) {
        setState(() {
          _requests = rows;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load KYC history. Please pull to refresh.';
        });
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result.isNotEmpty) {
        final file = result.first;
        final len = await file.length();
        if ((len ?? 5 * 1024 * 1024 + 1) > 5 * 1024 * 1024) {
          Get.snackbar(
            'File Too Large',
            'Please select a document smaller than 5 MB.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
          return;
        }

        setState(() {
          _selectedFile = file;
          _selectedFileSize = len;
          _errorMessage = null;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Picker Error',
        'Unable to select document. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _uploadKycDocument() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final bytes = await _selectedFile!.readAsBytes();
      await _api.submitKyc(_selectedDocType, bytes, _selectedFile!.name);
      await _repo.syncFromBackend();

      if (mounted) {
        setState(() {
          _selectedFile = null;
          _selectedFileSize = null;
          _isUploading = false;
        });
      }

      await _loadKycRequests();

      Get.snackbar(
        'Document Submitted',
        'Your $_selectedDocType has been received and queued for compliance verification.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Failed to submit document. Please check connection and retry.';
        });
      }
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
    } catch (_) {
      Get.snackbar('Error', 'Unable to retrieve secure document link.');
    }
  }

  String _formatDocName(String type) {
    return _docTypes[type]?['label'] ?? type.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVerified = _repo.currentUser.value?.isKycVerified == true;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(
        title: 'KYC Verification',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
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
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a document type and upload a clear PDF or photo.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isUploading ? null : _uploadKycDocument,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 20),
                        label: Text(
                          _isUploading ? 'Uploading & Encrypting...' : 'Submit ${_formatDocName(_selectedDocType)}',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

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
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.error, fontSize: 12),
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
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (_requests.isEmpty)
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isVerified
            ? const LinearGradient(
                colors: [Color(0xFF1B4D3E), Color(0xFF0F3026)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF1A252F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isVerified
                      ? const Color(0xFF4ADE80).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVerified ? Icons.verified_user_rounded : Icons.shield_outlined,
                  color: isVerified ? const Color(0xFF4ADE80) : Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isVerified ? 'KYC VERIFIED ACCOUNT' : 'KYC VERIFICATION REQUIRED',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: isVerified ? const Color(0xFF4ADE80) : const Color(0xFFB4E0CA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isVerified
                ? 'Your identity is fully verified.'
                : 'Unlock Full Investment & Withdrawal Privileges',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isVerified
                ? 'Your account complies with financial guidelines. Payouts and wallet withdrawals are enabled.'
                : 'Submit valid government documentation to unlock higher investment limits and instant bank payouts.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFFE2EBE6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocTypeSelector(bool isDark) {
    return Column(
      children: _docTypes.entries.map((entry) {
        final key = entry.key;
        final data = entry.value;
        final isSelected = _selectedDocType == key;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(14),
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
              onTap: () => setState(() => _selectedDocType = key),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF3F8F5)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        data['icon'] as IconData,
                        color: isSelected ? Colors.white : AppColors.primary,
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
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            data['desc'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.border),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropzone(bool isDark) {
    if (_selectedFile != null) {
      final sizeKb = ((_selectedFileSize ?? 0) / 1024).toStringAsFixed(1);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedFile!.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$sizeKb KB • Ready to submit',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 20),
              tooltip: 'Remove File',
              onPressed: () => setState(() {
                _selectedFile = null;
                _selectedFileSize = null;
              }),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFC7D7CE),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to Browse Document',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Supports PDF, PNG, JPG or JPEG (Maximum 5 MB)',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'REJECTED':
        badgeBg = AppColors.error.withValues(alpha: 0.12);
        badgeText = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        badgeBg = AppColors.warning.withValues(alpha: 0.12);
        badgeText = AppColors.warning;
        statusIcon = Icons.schedule_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
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
                    child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
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
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${id.length > 8 ? id.substring(0, 8) : id}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rejection reason: $rejectionReason',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.error),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _viewDocument(id),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text(
                      'View Document',
                      style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600),
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
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.folder_open_rounded, size: 36, color: AppColors.textSecondary),
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
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
      'Full legal name and date of birth must match your registered profile.',
      'Uploaded files are encrypted in compliance with financial regulations.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Submission Guidelines',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
