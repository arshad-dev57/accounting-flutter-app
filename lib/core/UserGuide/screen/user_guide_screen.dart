import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text(
          'User Guide',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1AB4F5),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            _buildHeaderBanner(),
            
            // Welcome Section
            _buildWelcomeSection(),
            
            // Getting Started
            _buildGettingStartedSection(),
            
            // Main Features
            _buildMainFeaturesSection(),
            
            // Navigation Guide
            _buildNavigationGuide(),
            
            // Quick Tips
            // _buildQuickTipsSection(),
            
            // FAQ Section
            _buildFAQSection(),
            
            // Support Section
            _buildSupportSection(),
          ],
        ),
      ),
    );
  }

  // Header Banner
  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1AB4F5), Color(0xFF0D8BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'LedgerPro Pro',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete Guide to Manage Your Business Finances',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // Welcome Section
  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
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
                    color: const Color(0xFF1AB4F5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.waving_hand,
                    color: Color(0xFF1AB4F5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Welcome to LedgerPro Pro!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This guide will help you understand how to use the app effectively to manage your business finances, track income and expenses, create invoices, and much more.',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF7A8FA6),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Getting Started Section
  Widget _buildGettingStartedSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🚀 Getting Started',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          _buildStepCard(
            number: '1',
            title: 'Create Your Account',
            description: 'Sign up with your email and password. Start your 30-day free trial immediately.',
            icon: Icons.person_add,
          ),
          _buildStepCard(
            number: '2',
            title: 'Set Up Your Business Profile',
            description: 'Add your company name, address, and business details to personalize your account.',
            icon: Icons.business,
          ),
          _buildStepCard(
            number: '3',
            title: 'Add Chart of Accounts',
            description: 'Create accounts for Assets, Liabilities, Income, and Expenses to organize your finances.',
            icon: Icons.account_balance_wallet,
          ),
          _buildStepCard(
            number: '4',
            title: 'Start Recording Transactions',
            description: 'Log your daily income, expenses, create invoices, and manage bills.',
            icon: Icons.receipt,
          ),
        ],
      ),
    );
  }

  // Step Card Widget
  Widget _buildStepCard({
    required String number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1AB4F5), Color(0xFF0D8BC0)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF7A8FA6),
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: const Color(0xFF1AB4F5), size: 24),
        ],
      ),
    );
  }

  // Main Features Section
  Widget _buildMainFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ Key Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildFeatureCard(
                icon: Icons.trending_up,
                title: 'Income Tracking',
                description: 'Record and manage all your income sources',
                color: const Color(0xFF2ECC71),
              ),
              _buildFeatureCard(
                icon: Icons.trending_down,
                title: 'Expense Tracking',
                description: 'Track every expense and categorize them',
                color: const Color(0xFFE74C3C),
              ),
              _buildFeatureCard(
                icon: Icons.receipt,
                title: 'Invoice Management',
                description: 'Create and send professional invoices',
                color: const Color(0xFF3498DB),
              ),
              _buildFeatureCard(
                icon: Icons.payment,
                title: 'Payment Tracking',
                description: 'Record payments received and made',
                color: const Color(0xFFF39C12),
              ),
              _buildFeatureCard(
                icon: Icons.account_balance,
                title: 'Bank Accounts',
                description: 'Manage multiple bank accounts',
                color: const Color(0xFF9B59B6),
              ),
              _buildFeatureCard(
                icon: Icons.assessment,
                title: 'Financial Reports',
                description: 'Generate P&L, Balance Sheet, Cash Flow',
                color: const Color(0xFF1ABC9C),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Feature Card
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF7A8FA6),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Navigation Guide
  Widget _buildNavigationGuide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧭 Navigation Guide',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          _buildNavItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            description: 'View your financial summary, charts, and key metrics at a glance.',
          ),
          _buildNavItem(
            icon: Icons.account_balance_wallet,
            title: 'Chart of Accounts',
            description: 'Manage all your financial accounts (Assets, Liabilities, Equity, Income, Expenses).',
          ),
          _buildNavItem(
            icon: Icons.receipt_long,
            title: 'Transactions',
            description: 'View and manage all your financial transactions in one place.',
          ),
          _buildNavItem(
            icon: Icons.assessment,
            title: 'Reports',
            description: 'Generate Profit & Loss, Balance Sheet, Cash Flow, and Trial Balance reports.',
          ),
        
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1AB4F5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1AB4F5), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF7A8FA6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Tips Section
  Widget _buildQuickTipsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1AB4F5), Color(0xFF0D8BC0)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Pro Tips',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTipItem(
              '📊', 
              'Regularly reconcile your accounts to avoid discrepancies'
            ),
            _buildTipItem(
              '💾', 
              'Take regular backups of your financial data'
            ),
            _buildTipItem(
              '📅', 
              'Set reminders for bill payments and invoice due dates'
            ),
            _buildTipItem(
              '📈', 
              'Review financial reports monthly to track business growth'
            ),
            _buildTipItem(
              '🔒', 
              'Keep your password secure and change it periodically'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FAQ Section
  Widget _buildFAQSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❓ Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            question: 'How do I start my free trial?',
            answer: 'Simply create an account and your 30-day free trial will start automatically. No credit card required.',
          ),
          _buildFAQItem(
            question: 'Can I create multiple bank accounts?',
            answer: 'Yes! You can add and manage multiple bank accounts under the Bank Accounts section.',
          ),
          _buildFAQItem(
            question: 'How do I generate financial reports?',
            answer: 'Go to Reports section and select the report you want (P&L, Balance Sheet, Cash Flow, or Trial Balance).',
          ),
          _buildFAQItem(
            question: 'Is my data secure?',
            answer: 'Yes! All your data is encrypted and stored securely. We use industry-standard security practices.',
          ),
          _buildFAQItem(
            question: 'Can I export my data?',
            answer: 'Yes, you can export your transactions and reports in PDF and Excel formats.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.help_outline, color: Color(0xFF1AB4F5), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF7A8FA6),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Support Section
  Widget _buildSupportSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1AB4F5).withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.support_agent, size: 48, color: Color(0xFF1AB4F5)),
            const SizedBox(height: 12),
            Text(
              'Need Help?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Our support team is here to help you',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF7A8FA6),
              ),
            ),
            const SizedBox(height: 16),
            // Row(
            //   children: [
            //     Expanded(
            //       child: OutlinedButton.icon(
            //         onPressed: () {
            //           // TODO: Open email
            //         },
            //         icon: const Icon(Icons.email, size: 18),
            //         label: const Text('Email'),
            //         style: OutlinedButton.styleFrom(
            //           foregroundColor: const Color(0xFF1AB4F5),
            //           side: const BorderSide(color: Color(0xFF1AB4F5)),
            //           padding: const EdgeInsets.symmetric(vertical: 12),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //         ),
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: ElevatedButton.icon(
            //         onPressed: () {
            //           // TODO: Open chat or FAQ
            //         },
            //         icon: const Icon(Icons.chat, size: 18),
            //         label: const Text('Live Chat'),
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: const Color(0xFF1AB4F5),
            //           padding: const EdgeInsets.symmetric(vertical: 12),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 12),
            Text(
              'support@LedgerPro.com',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF1AB4F5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}