import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      // ✅ AppBar for mobile - this fixes the missing app bar issue
      appBar: isWeb ? null : AppBar(
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: isWeb
          ? _buildWebLayout(context)
          : _buildMobileLayout(context),
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWeb ? 32 : 20),
      child: Column(
        children: [
          // ✅ Only show last updated on mobile if no app bar? But keep it
          _buildLastUpdated(),
          const SizedBox(height: 20),
          _buildSection(
            title: '1. Acceptance of Terms',
            content: 'By downloading, accessing, or using LedgerPro Pro ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.',
          ),
          _buildSection(
            title: '2. Description of Service',
            content: 'LedgerPro Pro provides financial management tools including but not limited to: income/expense tracking, invoice generation, bank account management, financial reporting, and data backup services.',
          ),
          _buildSection(
            title: '3. User Accounts',
            content: '• You must provide accurate and complete information when creating an account\n• You are responsible for maintaining the confidentiality of your password\n• You are responsible for all activities that occur under your account\n• Notify us immediately of any unauthorized use of your account',
          ),
          _buildSection(
            title: '4. Subscription and Billing',
            content: '• The App offers a 30-day free trial period\n• After the trial, a subscription is required to continue using the service\n• Subscription fees are billed in advance on a monthly or yearly basis\n• All payments are non-refundable except as required by law',
          ),
          _buildSection(
            title: '5. User Responsibilities',
            content: '• You agree to use the App only for lawful purposes\n• You are responsible for the accuracy of all data you enter\n• You will not attempt to hack, disrupt, or damage the App\n• You will not use the App to store illegal or harmful content',
          ),
          _buildSection(
            title: '6. Data Ownership and Privacy',
            content: '• You retain ownership of all data you enter into the App\n• We do not share your data with third parties without your consent\n• We implement security measures to protect your data\n• For more details, please review our Privacy Policy',
          ),
          _buildSection(
            title: '7. Intellectual Property',
            content: 'The App, including its code, design, logo, and content, is owned by Zoltech Solutions and is protected by copyright and intellectual property laws.',
          ),
          _buildSection(
            title: '8. Limitation of Liability',
            content: 'To the maximum extent permitted by law, Zoltech Solutions shall not be liable for any indirect, incidental, or consequential damages arising from your use of the App.',
          ),
          _buildSection(
            title: '9. Termination',
            content: 'We may terminate or suspend your account immediately, without prior notice, for conduct that violates these Terms of Service or for other harmful conduct.',
          ),
          _buildSection(
            title: '10. Changes to Terms',
            content: 'We reserve the right to modify these terms at any time. We will notify users of any material changes via email or through the App.',
          ),
          _buildSection(
            title: '11. Contact Information',
            content: 'For questions about these Terms of Service, please contact us at:\n📧 legal@ledgerpro.com\n📞 +92 300 1234567',
          ),
          _buildAcknowledgement(),
          const SizedBox(height: 20),
          _buildAcceptButton(),
        ],
      ),
    );
  }

  // ==================== WEB LAYOUT ====================
  Widget _buildWebLayout(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWebHeader(),
                const SizedBox(height: 30),
                _buildWebSection(
                  title: '1. Acceptance of Terms',
                  content: 'By downloading, accessing, or using LedgerPro ("the Platform"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the Platform.',
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  title: '2. Description of Service',
                  content: 'LedgerPro provides cloud-based financial management tools including but not limited to: income/expense tracking, invoice generation, bank account management, financial reporting, real-time analytics, and secure data backup services.',
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  title: '3. User Accounts',
                  content: '• You must provide accurate and complete information when creating an account\n• You are responsible for maintaining the confidentiality of your password\n• You are responsible for all activities that occur under your account\n• Notify us immediately of any unauthorized use of your account\n• Multi-factor authentication is recommended for enhanced security',
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  title: '4. Subscription and Billing',
                  content: '• The Platform offers a 30-day free trial period\n• After the trial, a subscription is required to continue using the service\n• Subscription fees are billed in advance on a monthly or yearly basis\n• All payments are processed securely via our payment partners\n• Subscriptions automatically renew unless cancelled before the renewal date\n• All payments are non-refundable except as required by law',
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  title: '5. User Responsibilities',
                  content: '• You agree to use the Platform only for lawful purposes\n• You are responsible for the accuracy of all data you enter\n• You will not attempt to hack, disrupt, or damage the Platform\n• You will not use the Platform to store illegal or harmful content\n• You will comply with all applicable laws and regulations',
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  title: '6. Data Ownership and Privacy',
                  content: '• You retain ownership of all data you enter into the Platform\n• We do not share your data with third parties without your consent\n• We implement industry-standard security measures to protect your data\n• For more details, please review our Privacy Policy\n• You can export your data at any time',
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  title: '7. Intellectual Property',
                  content: 'The Platform, including its code, design, logo, and content, is owned by Zoltech Solutions and is protected by copyright and intellectual property laws.',
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  title: '8. Limitation of Liability',
                  content: 'To the maximum extent permitted by law, Zoltech Solutions shall not be liable for any indirect, incidental, or consequential damages arising from your use of the Platform.',
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  title: '9. Termination',
                  content: 'We may terminate or suspend your account immediately, without prior notice, for conduct that violates these Terms of Service or for other harmful conduct.',
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  title: '10. Changes to Terms',
                  content: 'We reserve the right to modify these terms at any time. We will notify users of any material changes via email or through the Platform.',
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  title: '11. Contact Information',
                  content: 'For questions about these Terms of Service, please contact us at:\n📧 legal@ledgerpro.com\n📞 +92 300 1234567\n📍 Suite 123, Technology Park, Karachi, Pakistan',
                ),
                const SizedBox(height: 30),
                _buildWebAcknowledgement(),
                const SizedBox(height: 24),
                _buildWebAcceptButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== WEB HEADER ====================
  Widget _buildWebHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, const Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last Updated: April 28, 2026',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Version 2.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            'These terms govern your use of LedgerPro\'s services and form a legally binding agreement.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WEB SECTION ====================
  Widget _buildWebSection({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7A8FA6),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WEB ACKNOWLEDGEMENT ====================
  Widget _buildWebAcknowledgement() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'By using this platform, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE65100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WEB ACCEPT BUTTON ====================
  Widget _buildWebAcceptButton() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                AppSnackbar.success(Colors.green, 'Accepted', 'You have accepted the Terms of Service');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'I Accept the Terms',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Decline',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== MOBILE WIDGETS ====================
  Widget _buildLastUpdated() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.update, color: kPrimary, size: 16),
          const SizedBox(width: 8),
          Text(
            'Last Updated: April 28, 2026',
            style: TextStyle(
              fontSize: 12,
              color: kPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7A8FA6),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcknowledgement() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF9800)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'By using this app, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFE65100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          Get.back();
          AppSnackbar.success(Colors.green, 'Accepted', 'You have accepted the Terms of Service');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'I Accept the Terms',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}