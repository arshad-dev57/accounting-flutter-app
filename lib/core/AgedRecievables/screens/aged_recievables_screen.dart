// screens/aged_receivables_screen.dart - COMPLETE PROFESSIONAL MOBILE DESIGN

import 'dart:convert';
import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/config/apiconfig.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

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

  // ─── BUILD ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context),
          Expanded(
            child: _isLoading
                ? Center(
                    child: LoadingAnimationWidget.discreteCircle(
                      color: kPrimary,
                      size: 40,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: Column(
                      children: [
                        _buildDateBar(),
                        _buildSummaryCards(),
                        _buildFilterBar(),
                        const SizedBox(height: 8),
                        Expanded(child: _buildCustomerList(context)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _exportToExcel,
          backgroundColor: kPrimary,
          elevation: 0,
          child: const Icon(
            Icons.download_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aged Receivables',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_customers.length} customers',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadAgedReceivablesData,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _exportToExcel,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.download_outlined,
                        size: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
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

  // ═══════════════════════════════════════════════════════════════
  // DATE BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDateBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 14, color: kPrimary),
          const SizedBox(width: 8),
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
                color: kPrimary.withOpacity(0.08),
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

  // ═══════════════════════════════════════════════════════════════
  // PROFESSIONAL SUMMARY CARDS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _buildProfessionalCard(
            title: 'Current',
            amount: _formatAmount(totalCurrent),
            color: kSuccess,
            icon: Icons.access_time,
            bgColor: kSuccess.withOpacity(0.08),
            borderColor: kSuccess.withOpacity(0.2),
          ),
          const SizedBox(width: 8),
          _buildProfessionalCard(
            title: '1-30 Days',
            amount: _formatAmount(total1to30),
            color: kWarning,
            icon: Icons.calendar_view_month,
            bgColor: kWarning.withOpacity(0.08),
            borderColor: kWarning.withOpacity(0.2),
          ),
          const SizedBox(width: 8),
          _buildProfessionalCard(
            title: '90+ Days',
            amount: _formatAmount(totalOver90),
            color: kDanger,
            icon: Icons.warning_amber_rounded,
            bgColor: kDanger.withOpacity(0.08),
            borderColor: kDanger.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    bool isNumber = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      color: kSubText,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.3)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  isExpanded: true,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  dropdownColor: kCardBg,
                  items: _filterOptions
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedFilter = v!),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(fontSize: 12, color: kSubText),
                  prefixIcon: Icon(Icons.search, size: 18, color: kSubText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CUSTOMER LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCustomerList(BuildContext context) {
    final filtered = _getFilteredCustomers();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: kSubText.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No customers found',
              style: TextStyle(
                fontSize: 16,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(4),
      itemCount: filtered.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildCustomerCard(context, filtered[index]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFESSIONAL CUSTOMER CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCustomerCard(BuildContext context, AgedCustomer customer) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: customer.totalOutstanding > 0
              ? kDanger.withOpacity(0.2)
              : kSuccess.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCustomerDetails(customer),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kPrimary.withOpacity(0.15),
                            kPrimary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kPrimary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kText,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customer.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: kSubText,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _badge(customer.phone, kSubText),
                              _badge(
                                '${customer.invoices.length} invoices',
                                kPrimary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatAmount(customer.totalOutstanding),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kDanger,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: kDanger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Outstanding',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: kDanger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                const SizedBox(height: 12),
                // Aging Buckets
                Row(
                  children: [
                    _buildAgingBucket(
                      'Current',
                      customer.current,
                      customer.current > 0 ? kSuccess : kSubText,
                    ),
                    _buildAgingBucket(
                      '1-30',
                      customer.days1to30,
                      customer.days1to30 > 0 ? kWarning : kSubText,
                    ),
                    _buildAgingBucket(
                      '31-60',
                      customer.days31to60,
                      customer.days31to60 > 0 ? kWarning : kSubText,
                    ),
                    _buildAgingBucket(
                      '61-90',
                      customer.days61to90,
                      customer.days61to90 > 0 ? kDanger : kSubText,
                    ),
                    _buildAgingBucket(
                      '90+',
                      customer.daysOver90,
                      customer.daysOver90 > 0 ? kDanger : kSubText,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewInvoices(customer),
                        icon: Icon(Icons.receipt, size: 14, color: kSubText),
                        label: Text(
                          'Invoices',
                          style: TextStyle(
                            fontSize: 11,
                            color: kText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _sendReminder(customer),
                        icon: Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: kPrimary,
                        ),
                        label: Text(
                          'Reminder',
                          style: TextStyle(
                            fontSize: 11,
                            color: kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: kPrimary.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _recordPayment(customer),
                        icon: const Icon(
                          Icons.payment,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Pay',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccess,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
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

  Widget _buildAgingBucket(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
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
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatAmount(amount),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CUSTOMER DETAILS DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showCustomerDetails(AgedCustomer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                customer.name[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: kPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  customer.email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kSubText,
                                  ),
                                ),
                                Text(
                                  customer.phone,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kSubText,
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
                              color: kDanger.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatAmount(customer.totalOutstanding),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: kDanger,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // KPI Cards
                      Row(
                        children: [
                          _miniKpi(
                            'Current',
                            _formatAmount(customer.current),
                            kSuccess,
                            Icons.access_time,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            '1-30',
                            _formatAmount(customer.days1to30),
                            kWarning,
                            Icons.calendar_view_month,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            '90+',
                            _formatAmount(customer.daysOver90),
                            kDanger,
                            Icons.warning_amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Aging Breakdown
                      Text(
                        'Aging Breakdown',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kBgLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            _detailRow(
                              'Current',
                              _formatAmount(customer.current),
                            ),
                            _detailRow(
                              '1-30 Days',
                              _formatAmount(customer.days1to30),
                            ),
                            _detailRow(
                              '31-60 Days',
                              _formatAmount(customer.days31to60),
                            ),
                            _detailRow(
                              '61-90 Days',
                              _formatAmount(customer.days61to90),
                            ),
                            _detailRow(
                              '90+ Days',
                              _formatAmount(customer.daysOver90),
                            ),
                            Divider(
                              height: 16,
                              color: Colors.grey.withOpacity(0.15),
                            ),
                            _detailRow(
                              'Total Outstanding',
                              _formatAmount(customer.totalOutstanding),
                              isBold: true,
                              valueColor: kDanger,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Invoices
                      Text(
                        'Invoices (${customer.invoices.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...customer.invoices.map((inv) => _buildInvoiceItem(inv)),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Footer Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _viewInvoices(customer);
                                },
                                icon: Icon(
                                  Icons.receipt,
                                  size: 16,
                                  color: kPrimary,
                                ),
                                label: Text(
                                  'All Invoices',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: kPrimary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _recordPayment(customer);
                                },
                                icon: const Icon(
                                  Icons.payment,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Record Payment',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kSuccess,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniKpi(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.black.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: kSubText,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? kText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(AgedInvoice invoice) {
    final outstanding = invoice.amount - invoice.paidAmount;
    final daysOverdue = _asAtDate.difference(invoice.dueDate).inDays;
    final statusColor = daysOverdue <= 0
        ? kSuccess
        : daysOverdue <= 30
        ? kWarning
        : kDanger;
    final isPaid = outstanding <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPaid
              ? kSuccess.withOpacity(0.2)
              : statusColor.withOpacity(0.2),
        ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
                Text(
                  'Due: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}',
                  style: TextStyle(fontSize: 11, color: kSubText),
                ),
              ],
            ),
          ),
          if (!isPaid) ...[
            Text(
              _formatAmount(outstanding),
              style: TextStyle(
                fontSize: 13,
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
                daysOverdue <= 0 ? 'Current' : '$daysOverdue d',
                style: TextStyle(
                  fontSize: 9,
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
                  fontSize: 9,
                  color: kSuccess,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

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

  void _viewInvoices(AgedCustomer customer) {
    AppSnackbar.info('Invoices', 'Viewing invoices for ${customer.name}');
  }

  void _sendReminder(AgedCustomer customer) {
    AppSnackbar.info('Reminder', 'Sending reminder to ${customer.name}');
  }

  void _recordPayment(AgedCustomer customer) {
    AppSnackbar.info(
      'Record Payment',
      'Recording payment from ${customer.name}',
    );
  }

  Future<void> _selectAsAtDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asAtDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _asAtDate = picked;
        _calculateAging();
      });
    }
  }

  void _exportToExcel() {
    AppSnackbar.info('Export', 'Exporting to Excel...');
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}

// ─── DATA MODELS ────────────────────────────────────────────────────

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
