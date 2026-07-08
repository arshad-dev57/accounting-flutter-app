import 'dart:convert';
import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/config/apiconfig.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AgedReceivablesScreen extends StatefulWidget {
  const AgedReceivablesScreen({super.key});

  @override
  State<AgedReceivablesScreen> createState() => _AgedReceivablesScreenState();
}

class _AgedReceivablesScreenState extends State<AgedReceivablesScreen> {
  DateTime _asAtDate = DateTime.now();
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<AgedCustomer> _customers = [];
  double totalCurrent = 0;
  double total1to30 = 0;
  double total31to60 = 0;
  double total61to90 = 0;
  double totalOver90 = 0;
  double totalOutstanding = 0;

  final List<String> _filterOptions = [
    'All',
    'Current',
    '1-30 Days',
    '31-60 Days',
    '61-90 Days',
    '90+ Days',
  ];

  @override
  void initState() {
    super.initState();
    _loadAgedReceivablesData();
  }

  Future<void> _loadAgedReceivablesData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final baseUrl = Apiconfig().baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/accounts-receivable/aged'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          final list = body['data']['customers'] as List? ?? [];
          final summary =
              body['data']['summary'] as Map<String, dynamic>? ?? {};

          setState(() {
            _customers = list.map((c) {
              final invoices = (c['invoices'] as List? ?? []).map((inv) {
                return AgedInvoice(
                  id:
                      inv['invoiceNumber']?.toString() ??
                      inv['id']?.toString() ??
                      '',
                  date: DateTime.parse(inv['invoiceDate'].toString()),
                  dueDate: DateTime.parse(inv['dueDate'].toString()),
                  amount: (inv['amount'] as num).toDouble(),
                  paidAmount: (inv['paidAmount'] as num).toDouble(),
                );
              }).toList();

              final customer = AgedCustomer(
                id: c['id'].toString(),
                name: c['name']?.toString() ?? '',
                email: c['email']?.toString() ?? '',
                phone: c['phone']?.toString() ?? '',
                totalOutstanding: (c['totalOutstanding'] as num).toDouble(),
                invoices: invoices,
              );
              customer.current = (c['current'] as num?)?.toDouble() ?? 0;
              customer.days1to30 = (c['days1to30'] as num?)?.toDouble() ?? 0;
              customer.days31to60 = (c['days31to60'] as num?)?.toDouble() ?? 0;
              customer.days61to90 = (c['days61to90'] as num?)?.toDouble() ?? 0;
              customer.daysOver90 = (c['days90plus'] as num?)?.toDouble() ?? 0;
              return customer;
            }).toList();

            totalCurrent = (summary['current'] as num?)?.toDouble() ?? 0;
            total1to30 = (summary['days1to30'] as num?)?.toDouble() ?? 0;
            total31to60 = (summary['days31to60'] as num?)?.toDouble() ?? 0;
            total61to90 = (summary['days61to90'] as num?)?.toDouble() ?? 0;
            totalOver90 = (summary['days90plus'] as num?)?.toDouble() ?? 0;
            totalOutstanding =
                (summary['totalOutstanding'] as num?)?.toDouble() ?? 0;
          });
          return;
        }
      }
      AppSnackbar.error(kDanger, 'Error', 'Failed to load aged receivables');
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to load aged receivables');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateAging() {
    totalCurrent = 0;
    total1to30 = 0;
    total31to60 = 0;
    total61to90 = 0;
    totalOver90 = 0;
    totalOutstanding = 0;

    for (var customer in _customers) {
      double cc = 0, c1 = 0, c2 = 0, c3 = 0, c4 = 0;
      for (var invoice in customer.invoices) {
        double outstanding = invoice.amount - invoice.paidAmount;
        if (outstanding <= 0) continue;
        int daysOverdue = _asAtDate.difference(invoice.dueDate).inDays;
        if (daysOverdue <= 0) {
          cc += outstanding;
          totalCurrent += outstanding;
        } else if (daysOverdue <= 30) {
          c1 += outstanding;
          total1to30 += outstanding;
        } else if (daysOverdue <= 60) {
          c2 += outstanding;
          total31to60 += outstanding;
        } else if (daysOverdue <= 90) {
          c3 += outstanding;
          total61to90 += outstanding;
        } else {
          c4 += outstanding;
          totalOver90 += outstanding;
        }
      }
      customer.current = cc;
      customer.days1to30 = c1;
      customer.days31to60 = c2;
      customer.days61to90 = c3;
      customer.daysOver90 = c4;
      totalOutstanding += customer.totalOutstanding;
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileLayout(context);
    }
    return _buildWebLayout(context);
  }

  // ==================== MOBILE LAYOUT ====================

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context),
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.discreteCircle(
                color: kPrimary,
                size: 40,
              ),
            )
          : Column(
              children: [
                _buildMobileDateBar(context),
                _buildMobileSummaryCards(context),
                _buildMobileFilterBar(context),
                Expanded(child: _buildCustomerList(context)),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _exportToExcel,
        backgroundColor: kPrimary,
        child: const Icon(Icons.download, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Aged Receivables',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.black87),
          onPressed: _selectAsAtDate,
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf, color: Colors.black87),
          onPressed: _generateAndPrintPDF,
        ),
        IconButton(
          icon: const Icon(Icons.print_outlined, color: Colors.black87),
          onPressed: _printReport,
        ),
      ],
    );
  }

  Widget _buildMobileDateBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: kCardBg,
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: kPrimary),
          const SizedBox(width: 6),
          Text(
            'As at:',
            style: TextStyle(
              fontSize: 12,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _selectAsAtDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                DateFormat('dd MMM yyyy').format(_asAtDate),
                style: TextStyle(
                  fontSize: 12,
                  color: kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSummaryCards(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMobileSummaryCard(
              'Current',
              totalCurrent,
              kSuccess,
              Icons.access_time,
            ),
            const SizedBox(width: 12),
            _buildMobileSummaryCard(
              '1-30 Days',
              total1to30,
              kWarning,
              Icons.calendar_view_month,
            ),
            const SizedBox(width: 12),
            _buildMobileSummaryCard(
              '31-60 Days',
              total31to60,
              kWarning,
              Icons.calendar_view_month,
            ),
            const SizedBox(width: 12),
            _buildMobileSummaryCard(
              '61-90 Days',
              total61to90,
              kDanger,
              Icons.calendar_view_month,
            ),
            const SizedBox(width: 12),
            _buildMobileSummaryCard(
              '90+ Days',
              totalOver90,
              kDanger,
              Icons.warning,
            ),
            const SizedBox(width: 12),
            _buildMobileSummaryCard(
              'Total',
              totalOutstanding,
              kPrimary,
              Icons.attach_money,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: kCardBg,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(fontSize: 11, color: kSubText),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  isExpanded: true,
                  style: TextStyle(fontSize: 11, color: kText),
                  dropdownColor: kCardBg,
                  items: _filterOptions
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(
                            f,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedFilter = v!),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WEB LAYOUT ====================

  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildWebTopBar(context),
          if (!_isLoading) ...[_buildWebKpiStrip(), _buildWebToolbar(context)],
          Expanded(
            child: _isLoading
                ? Center(
                    child: LoadingAnimationWidget.discreteCircle(
                      color: kPrimary,
                      size: 32,
                    ),
                  )
                : Column(
                    children: [
                      Expanded(child: _buildCustomerList(context)),
                      _buildWebFooterBar(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(BuildContext context) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Aged Receivables',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const Expanded(child: SizedBox()),
          // As-at date pill
          GestureDetector(
            onTap: _selectAsAtDate,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black26),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'As at: ${DateFormat('dd MMM yyyy').format(_asAtDate)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _webTopBarBtn(Icons.download_outlined, 'Export', _exportToExcel),
          const SizedBox(width: 8),
          _webTopBarBtn(
            Icons.picture_as_pdf_outlined,
            'Save PDF',
            _generateAndPrintPDF,
          ),
          const SizedBox(width: 8),
          _webTopBarBtn(Icons.print_outlined, 'Print', _printReport),
        ],
      ),
    );
  }

  Widget _webTopBarBtn(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15, color: Colors.black87),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.4),
        elevation: 0,
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Colors.black26),
        ),
      ),
    );
  }

  Widget _buildWebKpiStrip() {
    return Container(
      color: kCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildWebKpiTile(
              'Current',
              totalCurrent,
              kSuccess,
              Icons.access_time,
            ),
            _buildWebKpiDivider(),
            _buildWebKpiTile(
              '1-30 Days',
              total1to30,
              kWarning,
              Icons.calendar_view_month,
            ),
            _buildWebKpiDivider(),
            _buildWebKpiTile(
              '31-60 Days',
              total31to60,
              kWarning,
              Icons.calendar_view_month,
            ),
            _buildWebKpiDivider(),
            _buildWebKpiTile(
              '61-90 Days',
              total61to90,
              kDanger,
              Icons.calendar_view_month,
            ),
            _buildWebKpiDivider(),
            _buildWebKpiTile(
              '90+ Days',
              totalOver90,
              kDanger,
              Icons.warning_amber_outlined,
            ),
            _buildWebKpiDivider(),
            _buildWebKpiTile(
              'Total Outstanding',
              totalOutstanding,
              kPrimary,
              Icons.attach_money,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiTile(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 9),
            Flexible(
              // ← yeh key fix hai
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: kSubText,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatAmount(amount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  Widget _buildWebToolbar(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: kBg,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
          top: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Search
          SizedBox(
            width: 280,
            height: 34,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              cursorColor: Colors.black54,
              decoration: InputDecoration(
                hintText: 'Search by name, email or phone…',
                hintStyle: const TextStyle(color: Colors.black45, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 16,
                  color: Colors.black45,
                ),
                filled: true,
                fillColor: kCardBg,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.black26),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: kBorder),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Age filter chips
          ..._filterOptions.map((f) {
            final isSelected = _selectedFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: () => setState(() => _selectedFilter = f),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: isSelected
                        ? Border.all(color: kPrimary.withOpacity(0.3))
                        : null,
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected ? kPrimary : kSubText,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWebFooterBar() {
    final filtered = _getFilteredCustomers();
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${filtered.length} customer${filtered.length == 1 ? '' : 's'}  •  ${_customers.length} total',
            style: TextStyle(fontSize: 12, color: kSubText),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: kDanger,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Total Outstanding: ${_formatAmount(totalOutstanding)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kDanger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SHARED: CUSTOMER LIST ====================

  Widget _buildCustomerList(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isWeb = ResponsiveUtils.isWeb(context);
    final filtered = _getFilteredCustomers();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: isMobile ? 64 : 80,
              color: kSubText.withOpacity(0.5),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Text(
              'No customers found',
              style: TextStyle(
                fontSize: isMobile ? 14 : 18,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isWeb ? 20 : 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: isWeb ? 12 : 8),
        child: _buildCustomerCard(context, filtered[index]),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, AgedCustomer customer) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isWeb = ResponsiveUtils.isWeb(context);

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(isWeb ? 12 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCustomerDetails(customer),
          borderRadius: BorderRadius.circular(12),
          hoverColor: kPrimary.withOpacity(0.02),
          child: Padding(
            padding: EdgeInsets.all(isWeb ? 16 : 12),
            child: Column(
              children: [
                // ---- Customer Header ----
                Row(
                  children: [
                    Container(
                      width: isWeb ? 46 : 42,
                      height: isWeb ? 46 : 42,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: isWeb ? 18 : 16,
                            fontWeight: FontWeight.w800,
                            color: kPrimary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isWeb ? 14 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: TextStyle(
                              fontSize: isWeb ? 14 : 13,
                              fontWeight: FontWeight.w700,
                              color: kText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer.email,
                            style: TextStyle(
                              fontSize: isWeb ? 12 : 11,
                              color: kSubText,
                            ),
                          ),
                          Text(
                            customer.phone,
                            style: TextStyle(
                              fontSize: isWeb ? 12 : 11,
                              color: kSubText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Outstanding',
                          style: TextStyle(fontSize: 10, color: kSubText),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: kDanger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatAmount(customer.totalOutstanding),
                            style: TextStyle(
                              fontSize: isWeb ? 14 : 13,
                              fontWeight: FontWeight.w800,
                              color: kDanger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: isWeb ? 14 : 10),
                Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                SizedBox(height: isWeb ? 12 : 8),

                // ---- Aging Buckets ----
                if (!isMobile)
                  Row(
                    children: [
                      _buildAgingBucket(
                        'Current',
                        customer.current,
                        customer.current > 0 ? kSuccess : kSubText,
                      ),
                      _buildAgingBucket(
                        '1-30 Days',
                        customer.days1to30,
                        customer.days1to30 > 0 ? kWarning : kSubText,
                      ),
                      _buildAgingBucket(
                        '31-60 Days',
                        customer.days31to60,
                        customer.days31to60 > 0 ? kWarning : kSubText,
                      ),
                      _buildAgingBucket(
                        '61-90 Days',
                        customer.days61to90,
                        customer.days61to90 > 0 ? kDanger : kSubText,
                      ),
                      _buildAgingBucket(
                        '90+ Days',
                        customer.daysOver90,
                        customer.daysOver90 > 0 ? kDanger : kSubText,
                      ),
                      _buildAgingBucket(
                        'Total',
                        customer.totalOutstanding,
                        kPrimary,
                        isBold: true,
                      ),
                    ],
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMobileAgingBucket(
                        'Current',
                        customer.current,
                        customer.current > 0 ? kSuccess : kSubText,
                      ),
                      _buildMobileAgingBucket(
                        '1-30',
                        customer.days1to30,
                        customer.days1to30 > 0 ? kWarning : kSubText,
                      ),
                      _buildMobileAgingBucket(
                        '31-60',
                        customer.days31to60,
                        customer.days31to60 > 0 ? kWarning : kSubText,
                      ),
                      _buildMobileAgingBucket(
                        '61-90',
                        customer.days61to90,
                        customer.days61to90 > 0 ? kDanger : kSubText,
                      ),
                      _buildMobileAgingBucket(
                        '90+',
                        customer.daysOver90,
                        customer.daysOver90 > 0 ? kDanger : kSubText,
                      ),
                      _buildMobileAgingBucket(
                        'Total',
                        customer.totalOutstanding,
                        kPrimary,
                        isBold: true,
                      ),
                    ],
                  ),

                SizedBox(height: isWeb ? 12 : 10),
                Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                const SizedBox(height: 6),

                // ---- Action Buttons ----
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _viewInvoices(customer),
                        icon: Icon(Icons.receipt, size: isWeb ? 16 : 14),
                        label: Text(
                          'View Invoices',
                          style: TextStyle(fontSize: isWeb ? 12 : 10),
                        ),
                        style: TextButton.styleFrom(foregroundColor: kPrimary),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _sendReminder(customer),
                        icon: Icon(Icons.email, size: isWeb ? 16 : 14),
                        label: Text(
                          'Send Reminder',
                          style: TextStyle(fontSize: isWeb ? 12 : 10),
                        ),
                        style: TextButton.styleFrom(foregroundColor: kPrimary),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _recordPayment(customer),
                        icon: Icon(
                          Icons.payment,
                          size: isWeb ? 16 : 14,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Record Payment',
                          style: TextStyle(fontSize: isWeb ? 12 : 10),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccess,
                          padding: EdgeInsets.symmetric(
                            vertical: isWeb ? 8 : 6,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgingBucket(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: isBold
                  ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                  : EdgeInsets.zero,
              decoration: isBold
                  ? BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Text(
                _formatAmount(amount),
                style: TextStyle(
                  fontSize: isBold ? 12 : 11,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileAgingBucket(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              fontSize: isBold ? 11 : 10,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== DIALOGS ====================

  void _showCustomerDetails(AgedCustomer customer) {
    final isWeb = ResponsiveUtils.isWeb(context);
    if (isWeb) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: _buildCustomerDetailsContent(customer),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: _buildCustomerDetailsContent(customer),
          ),
        ),
      );
    }
  }

  Widget _buildCustomerDetailsContent(AgedCustomer customer) {
    final isWeb = ResponsiveUtils.isWeb(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: isWeb ? 56 : 48,
              height: isWeb ? 56 : 48,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: isWeb ? 22 : 18,
                    fontWeight: FontWeight.w800,
                    color: kPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(width: isWeb ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: TextStyle(
                      fontSize: isWeb ? 17 : 15,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                  ),
                  Text(
                    customer.email,
                    style: TextStyle(
                      fontSize: isWeb ? 12 : 11,
                      color: kSubText,
                    ),
                  ),
                  Text(
                    customer.phone,
                    style: TextStyle(
                      fontSize: isWeb ? 12 : 11,
                      color: kSubText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kDanger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatAmount(customer.totalOutstanding),
                style: TextStyle(
                  fontSize: isWeb ? 14 : 13,
                  fontWeight: FontWeight.w800,
                  color: kDanger,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isWeb ? 20 : 16),
        // Aging breakdown
        Container(
          padding: EdgeInsets.all(isWeb ? 14 : 12),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                'Current',
                _formatAmount(customer.current),
                isWeb,
              ),
              _buildDetailRow(
                '1-30 Days',
                _formatAmount(customer.days1to30),
                isWeb,
              ),
              _buildDetailRow(
                '31-60 Days',
                _formatAmount(customer.days31to60),
                isWeb,
              ),
              _buildDetailRow(
                '61-90 Days',
                _formatAmount(customer.days61to90),
                isWeb,
              ),
              _buildDetailRow(
                '90+ Days',
                _formatAmount(customer.daysOver90),
                isWeb,
              ),
              Divider(color: Colors.grey.withOpacity(0.15), height: 16),
              _buildDetailRow(
                'Total Outstanding',
                _formatAmount(customer.totalOutstanding),
                isWeb,
                isBold: true,
              ),
            ],
          ),
        ),
        SizedBox(height: isWeb ? 20 : 16),
        Text(
          'Invoices',
          style: TextStyle(
            fontSize: isWeb ? 15 : 14,
            fontWeight: FontWeight.w700,
            color: kText,
          ),
        ),
        SizedBox(height: isWeb ? 10 : 8),
        ...customer.invoices.map((inv) => _buildInvoiceItem(inv, isWeb)),
        SizedBox(height: isWeb ? 20 : 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _viewInvoices(customer);
                },
                icon: Icon(Icons.receipt, size: isWeb ? 16 : 14),
                label: Text(
                  'View All',
                  style: TextStyle(fontSize: isWeb ? 13 : 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  side: BorderSide(color: kPrimary),
                ),
              ),
            ),
            SizedBox(width: isWeb ? 12 : 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _recordPayment(customer);
                },
                icon: Icon(
                  Icons.payment,
                  size: isWeb ? 16 : 14,
                  color: Colors.white,
                ),
                label: Text(
                  'Record Payment',
                  style: TextStyle(
                    fontSize: isWeb ? 13 : 12,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSuccess,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isWeb, {
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isWeb ? 10 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isWeb ? 12 : 11,
              color: kSubText,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isWeb ? 12 : 11,
              color: kText,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(AgedInvoice invoice, bool isWeb) {
    final outstanding = invoice.amount - invoice.paidAmount;
    final daysOverdue = _asAtDate.difference(invoice.dueDate).inDays;
    final statusColor = daysOverdue <= 0
        ? kSuccess
        : daysOverdue <= 30
        ? kWarning
        : kDanger;
    final isPaid = outstanding <= 0;

    return Container(
      margin: EdgeInsets.only(bottom: isWeb ? 10 : 8),
      padding: EdgeInsets.all(isWeb ? 12 : 10),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(isWeb ? 10 : 8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.id,
                  style: TextStyle(
                    fontSize: isWeb ? 13 : 12,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
                Text(
                  'Due: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}',
                  style: TextStyle(fontSize: isWeb ? 11 : 10, color: kSubText),
                ),
              ],
            ),
          ),
          if (!isPaid) ...[
            Text(
              _formatAmount(outstanding),
              style: TextStyle(
                fontSize: isWeb ? 13 : 12,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                daysOverdue <= 0 ? 'Current' : '$daysOverdue days',
                style: TextStyle(
                  fontSize: isWeb ? 10 : 9,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Paid',
                style: TextStyle(
                  fontSize: isWeb ? 10 : 9,
                  color: kSuccess,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== PDF GENERATION ====================

  Future<void> _generateAndPrintPDF() async {
    try {
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.waveDots(color: kPrimary, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Generating PDF...',
                  style: TextStyle(fontSize: 13, color: kText),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
      final pdf = _buildPdfDocument();
      Get.back();
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'Aged_Receivables_${DateFormat('yyyyMMdd').format(_asAtDate)}.pdf',
      );
      AppSnackbar.success(
        Colors.green,
        'Success',
        'PDF generated successfully',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.back();
      AppSnackbar.error(
        Colors.red,
        'Error',
        'Failed to generate PDF: $e',
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _printReport() async {
    try {
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.waveDots(color: kPrimary, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Preparing print...',
                  style: TextStyle(fontSize: 13, color: kText),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
      final pdf = _buildPdfDocument();
      Get.back();
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
      AppSnackbar.success(
        Colors.green,
        'Success',
        'Print job sent successfully',
      );
    } catch (e) {
      Get.back();
      AppSnackbar.error(
        Colors.red,
        'Error',
        'Failed to print: $e',
        duration: const Duration(seconds: 2),
      );
    }
  }

  pw.Document _buildPdfDocument() {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => [
          _buildPdfHeader(),
          pw.SizedBox(height: 20),
          _buildPdfSummaryRow(),
          pw.SizedBox(height: 20),
          _buildPdfTableHeader(),
          ..._customers.map(_buildPdfCustomerRow),
          pw.SizedBox(height: 20),
          _buildPdfTotalRow(),
          pw.SizedBox(height: 30),
          _buildPdfFooter(),
        ],
      ),
    );
    return pdf;
  }

  pw.Widget _buildPdfHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'Aged Receivables Report',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'As at ${DateFormat('dd MMM yyyy').format(_asAtDate)}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Generated on: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildPdfSummaryRow() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildPdfSummaryCard('Current', totalCurrent, PdfColors.green),
        _buildPdfSummaryCard('1-30 Days', total1to30, PdfColors.orange),
        _buildPdfSummaryCard('31-60 Days', total31to60, PdfColors.orange),
        _buildPdfSummaryCard('61-90 Days', total61to90, PdfColors.red),
        _buildPdfSummaryCard('90+ Days', totalOver90, PdfColors.red),
        _buildPdfSummaryCard('Total', totalOutstanding, PdfColors.blue),
      ],
    );
  }

  pw.Widget _buildPdfSummaryCard(String title, double amount, PdfColor color) {
    return pw.Container(
      width: 90,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            _formatAmountForPdf(amount),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTableHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              'Customer',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              'Current',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              '1-30',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              '31-60',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              '61-90',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              '90+',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              'Total',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfCustomerRow(AgedCustomer customer) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(customer.name, style: pw.TextStyle(fontSize: 10)),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatAmountForPdf(customer.current),
              style: pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatAmountForPdf(customer.days1to30),
              style: pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatAmountForPdf(customer.days31to60),
              style: pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatAmountForPdf(customer.days61to90),
              style: pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatAmountForPdf(customer.daysOver90),
              style: pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatAmountForPdf(customer.totalOutstanding),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTotalRow() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              'TOTAL',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatAmountForPdf(totalCurrent),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatAmountForPdf(total1to30),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatAmountForPdf(total31to60),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatAmountForPdf(total61to90),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatAmountForPdf(totalOver90),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatAmountForPdf(totalOutstanding),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'This is a computer-generated document and does not require a signature.',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // ==================== HELPER ACTIONS ====================

  void _exportToExcel() {
    AppSnackbar.success(
      Colors.blue,
      'Export',
      'Exporting to Excel...',
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _selectAsAtDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asAtDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null)
      setState(() {
        _asAtDate = picked;
        _calculateAging();
      });
  }

  List<AgedCustomer> _getFilteredCustomers() {
    List<AgedCustomer> filtered = List.from(_customers);
    if (_selectedFilter != 'All') {
      filtered = filtered.where((c) {
        switch (_selectedFilter) {
          case 'Current':
            return c.current > 0;
          case '1-30 Days':
            return c.days1to30 > 0;
          case '31-60 Days':
            return c.days31to60 > 0;
          case '61-90 Days':
            return c.days61to90 > 0;
          case '90+ Days':
            return c.daysOver90 > 0;
          default:
            return true;
        }
      }).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.email.toLowerCase().contains(q) ||
                c.phone.contains(q),
          )
          .toList();
    }
    return filtered;
  }

  void _viewInvoices(AgedCustomer customer) => AppSnackbar.success(
    Colors.blue,
    'Invoices',
    'Viewing invoices for ${customer.name}',
    duration: const Duration(seconds: 2),
  );

  void _sendReminder(AgedCustomer customer) => AppSnackbar.success(
    Colors.blue,
    'Reminder',
    'Sending reminder to ${customer.name}',
    duration: const Duration(seconds: 2),
  );

  void _recordPayment(AgedCustomer customer) => AppSnackbar.success(
    Colors.green,
    'Record Payment',
    'Recording payment from ${customer.name}',
    duration: const Duration(seconds: 2),
  );

  String _formatAmount(double amount) => CurrencyUtils.format(amount);

  String _formatAmountForPdf(double amount) => _formatAmount(amount);
}

// ==================== DATA MODELS ====================

class AgedCustomer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final double totalOutstanding;
  final List<AgedInvoice> invoices;

  double current = 0;
  double days1to30 = 0;
  double days31to60 = 0;
  double days61to90 = 0;
  double daysOver90 = 0;

  AgedCustomer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.totalOutstanding,
    required this.invoices,
  });
}

class AgedInvoice {
  final String id;
  final DateTime date;
  final DateTime dueDate;
  final double amount;
  final double paidAmount;

  AgedInvoice({
    required this.id,
    required this.date,
    required this.dueDate,
    required this.amount,
    required this.paidAmount,
  });
}
