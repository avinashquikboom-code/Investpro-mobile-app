import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/bank_account_model.dart';
import '../../services/api_service.dart';
import '../../services/demo_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';

class BankAccountView extends StatefulWidget {
  const BankAccountView({super.key});

  @override
  State<BankAccountView> createState() => _BankAccountViewState();
}

class _BankAccountViewState extends State<BankAccountView> {
  final ApiService _api = Get.find<ApiService>();
  final DemoRepository _repo = Get.find<DemoRepository>();

  List<BankAccountModel> _accounts = [];
  bool _isLoading = true;

  // Masking toggles for account numbers
  final Set<String> _revealedAccounts = <String>{};

  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
  }

  Future<void> _loadBankAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _api.dio.get('/mobile/bank-accounts');
      if (data.statusCode == 200 && data.data['success'] == true) {
        final list = (data.data['data'] as List)
            .map((item) => BankAccountModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (mounted) {
          setState(() {
            _accounts = list;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {
      // Fallback: check profile bank if available
      final user = _repo.currentUser.value;
      if (user.bankName.isNotEmpty && user.accountNumber.isNotEmpty) {
        if (mounted) {
          setState(() {
            _accounts = [
              BankAccountModel(
                id: 'primary-profile-bank',
                accountHolderName: user.fullName,
                accountNumber: user.accountNumber,
                bankName: user.bankName,
                ifscCode: user.ifscCode,
                accountType: 'SAVINGS',
                isPrimary: true,
                isVerified: user.isBankVerified,
              ),
            ];
            _isLoading = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openAddAccountSheet(BuildContext context) {
    final holderCtrl = TextEditingController(text: _repo.currentUser.value.fullName);
    final accNumCtrl = TextEditingController();
    final confirmAccNumCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    final bankNameCtrl = TextEditingController();

    String selectedType = 'SAVINGS';
    bool isPrimary = _accounts.isEmpty;
    String? formError;
    bool sheetBusy = false;

    final popularBanks = [
      'HDFC Bank',
      'State Bank of India',
      'ICICI Bank',
      'Axis Bank',
      'Kotak Mahindra',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.borderDark : const Color(0xFFD4E0D9),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Bank Account',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    Text(
                      'Provide your verified bank account for fast return payouts and withdrawals.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Bank Selector
                    Text(
                      'Popular Banks',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: popularBanks.map((bName) {
                          final isSelected = bankNameCtrl.text == bName;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                bName,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (val) {
                                setSheetState(() {
                                  bankNameCtrl.text = val ? bName : '';
                                });
                              },
                              selectedColor: AppColors.primary,
                              backgroundColor: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF3F8F5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.border),
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bank Name Field
                    _buildInputField(
                      controller: bankNameCtrl,
                      label: 'Bank Name',
                      hint: 'e.g. HDFC Bank, SBI',
                      icon: Icons.account_balance_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Account Holder Name
                    _buildInputField(
                      controller: holderCtrl,
                      label: 'Account Holder Name',
                      hint: 'As printed on bank records',
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                      capitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),

                    // Account Number
                    _buildInputField(
                      controller: accNumCtrl,
                      label: 'Account Number',
                      hint: 'Enter 9 to 18 digit account number',
                      icon: Icons.pin_outlined,
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),

                    // Confirm Account Number
                    _buildInputField(
                      controller: confirmAccNumCtrl,
                      label: 'Re-enter Account Number',
                      hint: 'Confirm account number',
                      icon: Icons.lock_outline_rounded,
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),

                    // IFSC Code
                    _buildInputField(
                      controller: ifscCtrl,
                      label: 'IFSC Code',
                      hint: '11-character code (e.g. HDFC0001234)',
                      icon: Icons.qr_code_rounded,
                      isDark: isDark,
                      capitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        LengthLimitingTextInputFormatter(11),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Account Type Selector (Savings vs Current)
                    Row(
                      children: [
                        Text(
                          'Account Type:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('Savings'),
                          selected: selectedType == 'SAVINGS',
                          onSelected: (val) {
                            if (val) setSheetState(() => selectedType = 'SAVINGS');
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: selectedType == 'SAVINGS' ? Colors.white : null,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Current'),
                          selected: selectedType == 'CURRENT',
                          onSelected: (val) {
                            if (val) setSheetState(() => selectedType = 'CURRENT');
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: selectedType == 'CURRENT' ? Colors.white : null,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Primary Account Checkbox
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isPrimary,
                      onChanged: _accounts.isEmpty
                          ? null // First account must be primary
                          : (val) => setSheetState(() => isPrimary = val ?? false),
                      title: Text(
                        'Set as primary account for payouts',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                    ),

                    if (formError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formError!,
                                style: const TextStyle(color: AppColors.error, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: sheetBusy
                            ? null
                            : () async {
                                final hName = holderCtrl.text.trim();
                                final bName = bankNameCtrl.text.trim();
                                final accNum = accNumCtrl.text.trim();
                                final confirmAccNum = confirmAccNumCtrl.text.trim();
                                final ifsc = ifscCtrl.text.trim().toUpperCase();

                                if (hName.length < 2) {
                                  setSheetState(() => formError = 'Enter valid account holder name');
                                  return;
                                }
                                if (bName.length < 2) {
                                  setSheetState(() => formError = 'Select or enter bank name');
                                  return;
                                }
                                if (!RegExp(r'^\d{8,20}$').hasMatch(accNum)) {
                                  setSheetState(() => formError = 'Enter valid 8 to 20 digit account number');
                                  return;
                                }
                                if (accNum != confirmAccNum) {
                                  setSheetState(() => formError = 'Account numbers do not match');
                                  return;
                                }
                                if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
                                  setSheetState(() => formError = 'Enter valid 11-digit IFSC code (e.g. HDFC0001234)');
                                  return;
                                }

                                setSheetState(() {
                                  sheetBusy = true;
                                  formError = null;
                                });

                                try {
                                  final payload = {
                                    'accountHolderName': hName,
                                    'accountNumber': accNum,
                                    'bankName': bName,
                                    'ifscCode': ifsc,
                                    'accountType': selectedType,
                                    'isPrimary': isPrimary,
                                  };

                                  final res = await _api.dio.post('/mobile/bank-accounts', data: payload);
                                  if (res.statusCode == 200 || res.statusCode == 201) {
                                    await _repo.syncFromBackend();
                                    Get.back();
                                    _loadBankAccounts();
                                    Get.snackbar(
                                      'Bank Account Added',
                                      '$bName ending in ${accNum.substring(accNum.length - 4)} linked successfully.',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppColors.success,
                                      colorText: Colors.white,
                                      margin: const EdgeInsets.all(16),
                                    );
                                  } else {
                                    setSheetState(() {
                                      sheetBusy = false;
                                      formError = res.data['message']?.toString() ?? 'Unable to save bank account.';
                                    });
                                  }
                                } catch (e) {
                                  setSheetState(() {
                                    sheetBusy = false;
                                    formError = 'Failed to link account. Please verify details and retry.';
                                  });
                                }
                              },
                        child: sheetBusy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Link & Save Bank Account',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          inputFormatters: inputFormatters,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF9FBF9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(
        title: 'bankDetails'.tr,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Add Bank Account',
            onPressed: () => _openAddAccountSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: RefreshIndicator(
            onRefresh: _loadBankAccounts,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security Assurance Card
                  _buildSecurityBanner(isDark),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Linked Bank Accounts',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openAddAccountSheet(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Account'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isLoading) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  ] else if (_accounts.isEmpty) ...[
                    _buildEmptyState(context, isDark),
                  ] else ...[
                    ..._accounts.map((acc) => _buildBankCard(acc, isDark)),
                  ],

                  const SizedBox(height: 24),
                  _buildGuidelinesCard(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF3F8F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFD4E0D9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified Financial Settlement',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Bank accounts are encrypted with 256-bit bank grade security. All dividend return payouts and wallet withdrawals are settled directly into your verified primary account.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(BankAccountModel account, bool isDark) {
    final isRevealed = _revealedAccounts.contains(account.id);
    final displayedAccNum = isRevealed ? account.accountNumber : account.maskedAccountNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: account.isPrimary
            ? const LinearGradient(
                colors: [Color(0xFF1B4D3E), Color(0xFF0F3026)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: account.isPrimary
            ? null
            : (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: account.isPrimary
              ? Colors.transparent
              : (isDark ? AppColors.borderDark : AppColors.border),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: account.isPrimary
                ? const Color(0xFF1B4D3E).withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Bank Icon, Bank Name & Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: account.isPrimary
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    account.initials,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: account.isPrimary ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.bankName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: account.isPrimary
                              ? Colors.white
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${account.accountType} ACCOUNT',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: account.isPrimary
                              ? const Color(0xFFB4E0CA)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                if (account.isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF4ADE80), width: 1),
                    ),
                    child: Text(
                      'PRIMARY',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4ADE80),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Account Number Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACCOUNT NUMBER',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: account.isPrimary
                            ? Colors.white.withValues(alpha: 0.7)
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayedAccNum,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: account.isPrimary
                            ? Colors.white
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    isRevealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: account.isPrimary
                        ? Colors.white.withValues(alpha: 0.8)
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                    size: 20,
                  ),
                  tooltip: isRevealed ? 'Hide account number' : 'Show account number',
                  onPressed: () {
                    setState(() {
                      if (isRevealed) {
                        _revealedAccounts.remove(account.id);
                      } else {
                        _revealedAccounts.add(account.id);
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Bottom Details: Holder Name & IFSC
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACCOUNT HOLDER',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.7,
                          color: account.isPrimary
                              ? Colors.white.withValues(alpha: 0.7)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.accountHolderName.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: account.isPrimary
                              ? Colors.white
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'IFSC CODE',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                        color: account.isPrimary
                            ? Colors.white.withValues(alpha: 0.7)
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.ifscCode,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: account.isPrimary
                            ? Colors.white
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Verification Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: account.isPrimary
                    ? Colors.black.withValues(alpha: 0.2)
                    : (isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF3F8F5)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    account.isVerified ? Icons.verified_rounded : Icons.schedule_rounded,
                    size: 15,
                    color: account.isVerified
                        ? (account.isPrimary ? const Color(0xFF4ADE80) : AppColors.success)
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    account.isVerified ? 'Direct Payout Ready (Verified)' : 'Pending Verification',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: account.isVerified
                          ? (account.isPrimary ? const Color(0xFF4ADE80) : AppColors.success)
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_outlined, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'No Bank Account Linked',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Link your bank account to receive automated return payouts and make fast withdrawals.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _openAddAccountSheet(context),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            label: Text(
              'Add Primary Bank Account',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelinesCard(bool isDark) {
    final guidelines = [
      'Account holder name must match your KYC government photo ID.',
      'Only Indian savings and current accounts in INR are accepted.',
      'Ensure the IFSC code matches your bank branch for NEFT/IMPS transfers.',
      'Verified bank accounts are credited automatically on each return cycle.',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Important Banking Guidelines',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...guidelines.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 5,
                    height: 5,
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
