import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: Text(
          isWeb ? 'BisonsTechs' : 'About App',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildAppHeader(),
            _buildAppDescription(),
            _buildFeaturesList(),
            _buildVersionInfo(),
            _buildSocialLinks(),
            _buildCopyright(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    final isWeb = ResponsiveUtils.isWeb(Get.context!);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isWeb ? 60 : 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isWeb ? 24 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isWeb ? 30 : 25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              'assets/logo.png',
              height: isWeb ? 96 : 72,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: isWeb ? 24 : 20),
          Text(
            isWeb ? 'BisonsTechs' : 'BisonsTechs Pro',
            style: TextStyle(
              fontSize: isWeb ? 36 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isWeb
                ? 'Professional BisonsTechs Management System'
                : 'Smart BisonsTechs Solution',
            style: TextStyle(fontSize: isWeb ? 16 : 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildAppDescription() {
    final isWeb = ResponsiveUtils.isWeb(Get.context!);

    return Padding(
      padding: EdgeInsets.all(isWeb ? 32 : 20),
      child: Container(
        padding: EdgeInsets.all(isWeb ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
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
                  padding: EdgeInsets.all(isWeb ? 10 : 8),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isWeb ? 14 : 12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: kPrimary,
                    size: isWeb ? 28 : 24,
                  ),
                ),
                SizedBox(width: isWeb ? 16 : 12),
                Text(
                  'About This App',
                  style: TextStyle(
                    fontSize: isWeb ? 22 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            SizedBox(height: isWeb ? 20 : 16),
            Text(
              isWeb
                  ? 'BisonsTechs is a comprehensive financial management platform designed to help businesses of all sizes track their finances, manage invoices, generate reports, and make informed business decisions. Our web-based solution provides real-time access to your financial data from anywhere.'
                  : 'BisonsTechs Pro is a comprehensive financial management solution designed to help businesses of all sizes track their finances, manage invoices, generate reports, and make informed business decisions.',
              style: TextStyle(
                fontSize: isWeb ? 16 : 14,
                color: const Color(0xFF7A8FA6),
                height: 1.5,
              ),
            ),
            SizedBox(height: isWeb ? 20 : 16),
            Text(
              isWeb
                  ? 'Whether you are a small business owner, freelancer, or accountant, BisonsTechs provides all the tools you need to manage your finances efficiently and accurately on any device with internet access.'
                  : 'Whether you are a small business owner, freelancer, or accountant, BisonsTechs Pro provides all the tools you need to manage your finances efficiently and accurately.',
              style: TextStyle(
                fontSize: isWeb ? 16 : 14,
                color: const Color(0xFF7A8FA6),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final isWeb = ResponsiveUtils.isWeb(Get.context!);

    final features = [
      {
        'icon': Icons.trending_up,
        'title': 'Income & Expense Tracking',
        'color': const Color(0xFF2ECC71),
      },
      {
        'icon': Icons.receipt,
        'title': 'Invoice & Bill Management',
        'color': const Color(0xFF3498DB),
      },
      {
        'icon': Icons.account_balance,
        'title': 'Bank Account Management',
        'color': const Color(0xFF9B59B6),
      },
      {
        'icon': Icons.assessment,
        'title': 'Financial Reports',
        'color': const Color(0xFF1ABC9C),
      },
    ];

    if (isWeb) {
      features.addAll([
        {
          'icon': Icons.cloud_queue,
          'title': 'Cloud Sync',
          'color': const Color(0xFFE67E22),
        },
        {
          'icon': Icons.security,
          'title': 'Data Security',
          'color': const Color(0xFFE74C3C),
        },
      ]);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 32 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isWeb ? '🚀 Key Features' : '✨ Key Features',
            style: TextStyle(
              fontSize: isWeb ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: isWeb ? 24 : 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isWeb ? 3 : 2,
            mainAxisSpacing: isWeb ? 24 : 16,
            crossAxisSpacing: isWeb ? 24 : 16,
            childAspectRatio: isWeb ? 1.8 : 1.5,
            children: features.map((feature) {
              return Container(
                padding: EdgeInsets.all(isWeb ? 16 : 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
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
                      padding: EdgeInsets.all(isWeb ? 12 : 10),
                      decoration: BoxDecoration(
                        color: (feature['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(isWeb ? 14 : 12),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: feature['color'] as Color,
                        size: isWeb ? 32 : 28,
                      ),
                    ),
                    SizedBox(height: isWeb ? 12 : 8),
                    Text(
                      feature['title'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isWeb ? 14 : 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    final isWeb = ResponsiveUtils.isWeb(Get.context!);

    return Padding(
      padding: EdgeInsets.all(isWeb ? 32 : 20),
      child: Container(
        padding: EdgeInsets.all(isWeb ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.code,
              'Version',
              isWeb ? '2.0.0' : '1.0.0',
              isWeb,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today,
              'Release Date',
              'April 2026',
              isWeb,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.web,
              'Platform',
              isWeb ? 'Web' : 'Android & iOS',
              isWeb,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.update,
              'Last Updated',
              'April 28, 2026',
              isWeb,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isWeb) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isWeb ? 10 : 8),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
          ),
          child: Icon(icon, color: kPrimary, size: isWeb ? 22 : 20),
        ),
        SizedBox(width: isWeb ? 20 : 16),
        Text(
          label,
          style: TextStyle(
            fontSize: isWeb ? 15 : 14,
            color: const Color(0xFF7A8FA6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: isWeb ? 15 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks() {
    final isWeb = ResponsiveUtils.isWeb(Get.context!);

    final socialLinks = [
      {
        'icon': Icons.web,
        'label': 'Website',
        'url': 'https://zoltech.com',
        'color': const Color(0xFF1AB4F5),
      },
      {
        'icon': Icons.facebook,
        'label': 'Facebook',
        'url': 'https://facebook.com/zoltech',
        'color': const Color(0xFF1877F2),
      },
      {
        'icon': Icons.link,
        'label': 'LinkedIn',
        'url': 'https://linkedin.com/company/zoltech',
        'color': const Color(0xFF0A66C2),
      },
      {
        'icon': Icons.alternate_email,
        'label': 'Twitter',
        'url': 'https://twitter.com/zoltech',
        'color': const Color(0xFF1DA1F2),
      },
    ];

    if (isWeb) {
      socialLinks.addAll([
        {
          'icon': Icons.podcasts,
          'label': 'Blog',
          'url': 'https://zoltech.com/blog',
          'color': const Color(0xFFE74C3C),
        },
        {
          'icon': Icons.youtube_searched_for,
          'label': 'YouTube',
          'url': 'https://youtube.com/zoltech',
          'color': const Color(0xFFFF0000),
        },
      ]);
    }

    return Padding(
      padding: EdgeInsets.all(isWeb ? 32 : 20),
      child: Container(
        padding: EdgeInsets.all(isWeb ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
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
            Text(
              'Connect With Us',
              style: TextStyle(
                fontSize: isWeb ? 22 : 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            SizedBox(height: isWeb ? 20 : 16),
            Wrap(
              spacing: isWeb ? 16 : 12,
              runSpacing: isWeb ? 16 : 12,
              children: socialLinks.map((social) {
                return GestureDetector(
                  onTap: () async {
                    final Uri url = Uri.parse(social['url']! as String);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWeb ? 20 : 16,
                      vertical: isWeb ? 12 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: (social['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isWeb ? 14 : 12),
                      border: Border.all(
                        color: (social['color'] as Color).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          social['icon'] as IconData,
                          color: social['color'] as Color,
                          size: isWeb ? 20 : 18,
                        ),
                        SizedBox(width: isWeb ? 12 : 8),
                        Text(
                          social['label'] as String,
                          style: TextStyle(
                            fontSize: isWeb ? 14 : 13,
                            fontWeight: FontWeight.w600,
                            color: social['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyright() {
    final isWeb = ResponsiveUtils.isWeb(Get.context!);

    return Padding(
      padding: EdgeInsets.all(isWeb ? 32 : 20),
      child: Column(
        children: [
          Text(
            'Made with ❤️ in Pakistan',
            style: TextStyle(
              fontSize: isWeb ? 14 : 12,
              color: const Color(0xFF7A8FA6),
            ),
          ),
          SizedBox(height: isWeb ? 12 : 8),
          Text(
            isWeb
                ? 'Secure cloud-based platform with enterprise-grade security'
                : 'This app uses industry-standard security practices to protect your data.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWeb ? 13 : 11,
              color: const Color(0xFFB0BEC5),
            ),
          ),
          SizedBox(height: isWeb ? 24 : 20),
        ],
      ),
    );
  }
}
