// lib/core/warehouse/reports/screen/reports_screen.dart - UPDATED WITH GRID DESIGN (2 Columns)

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/core/warehouse/reports/controller/reports_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportsController());


    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 40,
            ),
          );
        }
        return _buildContent(context, controller);
      }),
    );
  }

  Widget _buildContent(BuildContext context, ReportsController controller) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isWeb = ResponsiveUtils.isWeb(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          _buildReportGrid(controller, isMobile, isWeb),

          const SizedBox(height: 24),
          _buildRecentReports(controller, isMobile),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReportGrid(
    ReportsController controller,
    bool isMobile,
    bool isWeb,
  ) {
    final reports = controller.reports;
    final crossAxisCount = isWeb ? 4 : 2;
    final childAspectRatio = isWeb ? 1.1 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Inventory Reports',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              if (!isMobile)
                Text(
                  '${reports.length} reports',
                  style: TextStyle(
                    fontSize: 12,
                    color: kSubText,
                  ),
                ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isMobile ? 10 : 16,
            mainAxisSpacing: isMobile ? 10 : 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(report, isMobile, controller);
          },
        ),
      ],
    );
  }

  Widget _buildReportCard(
    Map<String, dynamic> report,
    bool isMobile,
    ReportsController controller,
  ) {
    final color = report['color'] as Color;

    return InkWell(
      onTap: () => controller.navigateToReport(report),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                report['icon'] as IconData,
                size: isMobile ? 28 : 32,
                color: color,
              ),
            ),
            SizedBox(height: isMobile ? 10 : 12),
            Text(
              report['title'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isMobile ? 4 : 6),
            Text(
              report['subtitle'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                color: kSubText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Open →',
                style: TextStyle(
                  fontSize: isMobile ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // RECENTLY VIEWED
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRecentReports(ReportsController controller, bool isMobile) {
    final recentReports = controller.recentReports;

    if (recentReports.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Recently Viewed',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              if (!isMobile)
                Text(
                  '${recentReports.length} reports',
                  style: TextStyle(
                    fontSize: 12,
                    color: kSubText,
                  ),
                ),
            ],
          ),
        ),
        // Grid of 2 for recent reports as well
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: isMobile ? 10 : 16,
            mainAxisSpacing: isMobile ? 8 : 12,
            childAspectRatio: 3.5,
          ),
          itemCount: recentReports.length,
          itemBuilder: (context, index) {
            final report = recentReports[index];
            return _buildRecentReportCard(report, isMobile, controller);
          },
        ),
      ],
    );
  }

  Widget _buildRecentReportCard(
    Map<String, dynamic> report,
    bool isMobile,
    ReportsController controller,
  ) {
    final color = report['color'] as Color;

    return InkWell(
      onTap: () => controller.navigateToReport(report),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isMobile ? 36 : 40,
              height: isMobile ? 36 : 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                report['icon'] as IconData,
                size: isMobile ? 18 : 20,
                color: color,
              ),
            ),
            SizedBox(width: isMobile ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    report['title'] as String,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: isMobile ? 10 : 12,
                        color: kSubText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(report['date'] as DateTime),
                        style: TextStyle(
                          fontSize: isMobile ? 9 : 10,
                          color: kSubText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: isMobile ? 16 : 20,
              color: kSubText,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}