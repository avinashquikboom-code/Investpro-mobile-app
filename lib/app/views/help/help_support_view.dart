import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';

class HelpSupportView extends StatefulWidget {
  const HelpSupportView({super.key});

  @override
  State<HelpSupportView> createState() => _HelpSupportViewState();
}

class _HelpSupportViewState extends State<HelpSupportView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, String>> _faqs = [
    {
      'category': 'Returns',
      'question': 'When will my investment returns be credited?',
      'answer':
          'Returns are automatically calculated according to each project\'s payout schedule (monthly or at maturity). Once settled by the treasury, dividends are directly credited to your InvestPro Wallet balance and are immediately withdrawable.',
    },
    {
      'category': 'Withdrawals',
      'question': 'How long do withdrawals take to reflect in my bank?',
      'answer':
          'Once approved by our financial verification team, withdrawals are dispatched via automated IMPS/NEFT rails. Funds typically reflect in your primary verified bank account within 2 to 24 business hours.',
    },
    {
      'category': 'KYC & Security',
      'question': 'What documents are required for KYC verification?',
      'answer':
          'We accept government-issued photo identity documents including PAN Card, Aadhaar Card, and Passport. Ensure all four corners are clearly visible and the document is not expired.',
    },
    {
      'category': 'Investments',
      'question': 'Are my investments legally protected and secured?',
      'answer':
          'Yes. Every opportunity on InvestPro undergoes rigorous financial vetting, regulatory asset backing, and third-party legal validation before being listed on the platform.',
    },
    {
      'category': 'Banking',
      'question': 'Can I link multiple bank accounts for withdrawals?',
      'answer':
          'Yes, you can link multiple savings or current bank accounts. You can designate one account as your primary destination for automated payouts and switch anytime from the Bank Details screen.',
    },
    {
      'category': 'Investments',
      'question': 'Can I withdraw my capital before project maturity?',
      'answer':
          'Investments have committed tenures to guarantee projected returns. Early liquidity options or secondary transfers may be available subject to project terms and administrative approval.',
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchEmail() async {
    const email = 'support@investpro.app';
    final uri = Uri.parse('mailto:$email?subject=InvestPro%20Support%20Request');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(const ClipboardData(text: email));
        Get.snackbar(
          'Email Copied',
          '$email copied to clipboard.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      await Clipboard.setData(const ClipboardData(text: email));
      Get.snackbar('Email Copied', '$email copied to clipboard.');
    }
  }

  Future<void> _launchPhone() async {
    final uri = Uri.parse('tel:1800482900');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Get.snackbar('Helpline', 'Call us at 1800-482-900 (Toll-Free, 9 AM - 7 PM)');
      }
    } catch (_) {
      Get.snackbar('Helpline', 'Call us at 1800-482-900');
    }
  }

  void _openTicketBottomSheet(BuildContext context) {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String category = 'Investment Inquiry';
    bool busy = false;

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
                          'Submit Support Ticket',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
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
                      'Our specialist support desk will review and respond to your ticket within 2 hours.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    Text(
                      'Issue Category',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: category,
                          isExpanded: true,
                          dropdownColor: isDark ? AppColors.surfaceDarkElevated : Colors.white,
                          items: [
                            'Investment Inquiry',
                            'Withdrawal & Payout',
                            'KYC & Account Verification',
                            'Bank Linking Assistance',
                            'Technical & App Issue',
                          ].map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => category = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Subject
                    Text(
                      'Subject',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subjectCtrl,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Brief summary of the issue',
                        hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
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
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Message
                    Text(
                      'Detailed Message',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: messageCtrl,
                      maxLines: 4,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Describe what happened, including dates or references...',
                        hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
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
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: busy
                            ? null
                            : () async {
                                final subj = subjectCtrl.text.trim();
                                final msg = messageCtrl.text.trim();
                                if (subj.length < 3 || msg.length < 5) {
                                  Get.snackbar(
                                    'Incomplete Ticket',
                                    'Please provide both a subject and details for your request.',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: AppColors.warning,
                                    colorText: Colors.black,
                                  );
                                  return;
                                }

                                setSheetState(() => busy = true);
                                await Future.delayed(const Duration(milliseconds: 600));

                                Navigator.of(context).pop();
                                final ticketId = 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                                Get.snackbar(
                                  'Ticket Submitted (#$ticketId)',
                                  'Our concierge team is investigating and will notify you shortly.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.success,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 4),
                                );
                              },
                        child: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Submit Support Ticket',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ['All', 'Returns', 'Withdrawals', 'Investments', 'KYC & Security', 'Banking'];

    final filteredFaqs = _faqs.where((faq) {
      final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          faq['question']!.toLowerCase().contains(_searchQuery) ||
          faq['answer']!.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(
        title: 'helpSupport'.tr,
        showBackButton: true,
      ),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Concierge Card
                _buildHeroCard(isDark),
                const SizedBox(height: 20),

                // 2. Direct Channels (Email, Phone, WhatsApp)
                Text(
                  'Direct Assistance Channels',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildContactChannel(
                        icon: Icons.email_outlined,
                        title: 'Email',
                        subtitle: 'support@investpro.app',
                        isDark: isDark,
                        onTap: _launchEmail,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildContactChannel(
                        icon: Icons.phone_outlined,
                        title: 'Toll-Free',
                        subtitle: '1800-482-900',
                        isDark: isDark,
                        onTap: _launchPhone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Ticket Launcher Card
                _buildTicketLauncherCard(context, isDark),
                const SizedBox(height: 24),

                // 4. FAQ Header & Search
                Text(
                  'Frequently Asked Questions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search queries or topics...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 5. Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.borderDark : AppColors.border),
                            ),
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // 6. Accordion FAQs
                if (filteredFaqs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Text(
                      'No matching answers found for "$_searchQuery".',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ...filteredFaqs.map((faq) => _buildFaqTile(faq, isDark)),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4D3E), Color(0xFF0F3026)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.25),
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
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headset_mic_rounded, color: Color(0xFF4ADE80), size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'INVESTOR CONCIERGE',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: const Color(0xFFB4E0CA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'How can we support you today?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Get direct guidance on return schedules, wallet withdrawals, KYC documentation, and investment contracts.',
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

  Widget _buildContactChannel({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketLauncherCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF3F8F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFD4E0D9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Have a specific issue?',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Submit a formal ticket with your account reference for trackable resolution.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => _openTicketBottomSheet(context),
            child: Text(
              'New Ticket',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(Map<String, String> faq, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          title: Text(
            faq['question']!,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                faq['answer']!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
