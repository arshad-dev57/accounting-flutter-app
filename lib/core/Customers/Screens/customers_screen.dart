import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/core/Invoice/Screens/Invoice_Screen.dart';
import 'package:BisonsTechs_app/core/paymentRecieved/Screens/payment_recieved_screen.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/core/Customers/controllers/customer_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CustomerController());

    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileLayout(context, controller);
    }
    return _buildWebLayout(context, controller);
  }

  // ==================== MOBILE LAYOUT ====================

  Widget _buildMobileLayout(
    BuildContext context,
    CustomerController controller,
  ) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.customers.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 40,
            ),
          );
        }

        return Column(
          children: [
            _buildMobileFilterBar(controller, context),
            _buildMobileSummaryCards(controller, context),
            Expanded(child: _buildMobileCustomersList(controller, context)),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(controller, context),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(
    BuildContext context,
    CustomerController controller,
  ) {
    return AppBar(
      title: const Text(
        'Customers',
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
          icon: const Icon(Icons.search, color: Colors.black87),
          onPressed: () => _showMobileSearch(context, controller),
        ),
        IconButton(
          icon: const Icon(Icons.filter_alt_outlined, color: Colors.black87),
          onPressed: () => _showFilterDialog(controller, context),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black87),
          onPressed: () => controller.exportCustomers(),
        ),
      ],
    );
  }

  Widget _buildMobileFilterBar(
    CustomerController controller,
    BuildContext context,
  ) {
    final filters = ['All', 'Active', 'Inactive', 'With Balance'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: kCardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: filters.map((f) {
              final isSelected = controller.selectedFilter.value == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (_) =>
                      controller.changeFilter(isSelected ? 'All' : f),
                  backgroundColor: kBg,
                  selectedColor: kPrimary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? kPrimary : kSubText,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSummaryCards(
    CustomerController controller,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: [
              _buildMobileSummaryCard(
                'Total Customers',
                controller.totalCustomers.value.toString(),
                kPrimary,
                Icons.people,
                isNumber: true,
              ),
              const SizedBox(width: 12),
              _buildMobileSummaryCard(
                'Active',
                controller.activeCustomers.value.toString(),
                kSuccess,
                Icons.check_circle,
                isNumber: true,
              ),
              const SizedBox(width: 12),
              _buildMobileSummaryCard(
                'Outstanding',
                _formatAmount(controller.totalOutstanding.value),
                kDanger,
                Icons.payment,
              ),
              const SizedBox(width: 12),
              _buildMobileSummaryCard(
                'Total Sales',
                _formatAmount(controller.totalSales.value),
                kPrimary,
                Icons.trending_up,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
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
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCustomersList(
    CustomerController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final customers = controller.getFilteredCustomers();

      if (controller.isLoading.value && customers.isEmpty) {
        return const SizedBox.shrink();
      }

      if (customers.isEmpty) {
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
                style: TextStyle(fontSize: 16, color: kSubText),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showAddCustomerDialog(controller, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add Customer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMobileCustomerCard(
            customers[index],
            controller,
            context,
          ),
        ),
      );
    });
  }

  Widget _buildMobileCustomerCard(
    Customer customer,
    CustomerController controller,
    BuildContext context,
  ) {
    final hasOutstanding = customer.outstandingAmount > 0;
    final statusColor = customer.isActive ? kSuccess : kDanger;

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCustomerDetails(customer, controller, context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 16,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer.email.isNotEmpty
                                ? customer.email
                                : customer.phone,
                            style: TextStyle(fontSize: 11, color: kSubText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  customer.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: kBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  customer.paymentTerms,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: kSubText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hasOutstanding) ...[
                          Text(
                            'Outstanding',
                            style: TextStyle(fontSize: 9, color: kSubText),
                          ),
                          Text(
                            _formatAmount(customer.outstandingAmount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: kDanger,
                            ),
                          ),
                        ] else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kSuccess.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: kSuccess,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'Paid',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: kSuccess,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showCustomerDetails(customer, controller, context),
                        icon: Icon(Icons.visibility, size: 14, color: kSubText),
                        label: Text(
                          'Details',
                          style: TextStyle(fontSize: 11, color: kText),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (hasOutstanding)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _recordPayment(customer, controller, context),
                          icon: const Icon(
                            Icons.payment,
                            size: 14,
                            color: Colors.black87,
                          ),
                          label: const Text(
                            'Pay',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _editCustomer(customer, controller, context),
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
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

  // ==================== WEB LAYOUT ====================

  Widget _buildWebLayout(BuildContext context, CustomerController controller) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildWebTopBar(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.customers.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: 32,
                  ),
                );
              }
              return Column(
                children: [
                  _buildWebKpiStrip(controller),
                  _buildWebToolbar(controller, context),
                  Expanded(child: _buildWebCustomersTable(controller, context)),
                  _buildWebPaginationBar(controller),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(BuildContext context, CustomerController controller) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Customers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const Expanded(child: SizedBox()),
          SizedBox(
            width: 220,
            height: 34,
            child: TextField(
              onChanged: (v) => controller.searchCustomers(v),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              cursorColor: Colors.black54,
              decoration: InputDecoration(
                hintText: 'Search customers…',
                hintStyle: const TextStyle(color: Colors.black45, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 16,
                  color: Colors.black45,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.35),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.black26),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showFilterDialog(controller, context),
            icon: const Icon(Icons.tune, size: 15, color: Colors.black87),
            label: const Text(
              'Filter',
              style: TextStyle(fontSize: 13, color: Colors.black87),
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
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => controller.exportCustomers(),
            icon: const Icon(
              Icons.download_outlined,
              size: 15,
              color: Colors.black87,
            ),
            label: const Text(
              'Export',
              style: TextStyle(fontSize: 13, color: Colors.black87),
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
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddCustomerDialog(controller, context),
            icon: const Icon(Icons.add, size: 16, color: Colors.black87),
            label: const Text(
              'Add Customer',
              style: TextStyle(fontSize: 13, color: Colors.black87),
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
          ),
        ],
      ),
    );
  }

  Widget _buildWebKpiStrip(CustomerController controller) {
    return Obx(
      () => Container(
        color: kCardBg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Row(
          children: [
            _buildWebKpiTile(
              'Total Customers',
              controller.totalCustomers.value.toString(),
              kPrimary,
              Icons.people,
            ),
            _buildWebKpiDivider(),
            _buildWebKpiTile(
              'Active',
              controller.activeCustomers.value.toString(),
              kSuccess,
              Icons.check_circle_outline,
            ),
            _buildWebKpiDivider(),
            _buildWebKpiTile(
              'Outstanding',
              _formatAmount(controller.totalOutstanding.value),
              kDanger,
              Icons.payment,
            ),
            _buildWebKpiDivider(),
            _buildWebKpiTile(
              'Total Sales',
              _formatAmount(controller.totalSales.value),
              kPrimary,
              Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiTile(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  Widget _buildWebToolbar(CustomerController controller, BuildContext context) {
    final filters = ['All', 'Active', 'Inactive', 'With Balance'];
    return Container(
      height: 44,
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
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: filters.map((f) {
                  final isSelected = controller.selectedFilter.value == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () => controller.changeFilter(f),
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
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WEB TABLE ====================

  Widget _buildWebCustomersTable(
    CustomerController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final customers = controller.getFilteredCustomers();

      if (customers.isEmpty && !controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: kSubText.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No customers found',
                style: TextStyle(fontSize: 15, color: kSubText),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: () => _showAddCustomerDialog(controller, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '+ Add Customer',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Header row
          Container(
            height: 36,
            color: kBg,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(flex: 4, child: _tableHeaderCell('Customer')),
                Expanded(flex: 3, child: _tableHeaderCell('Contact')),
                Expanded(flex: 2, child: _tableHeaderCell('Terms')),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Invoices', align: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell(
                    'Total Sales',
                    align: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Paid', align: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell(
                    'Outstanding',
                    align: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _tableHeaderCell('Status', align: TextAlign.center),
                ),
                const SizedBox(width: 68),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: ListView.separated(
              itemCount: customers.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) =>
                  _buildWebTableRow(customers[index], controller, context),
            ),
          ),
          if (customers.isNotEmpty) _buildWebTableFooter(customers),
        ],
      );
    });
  }

  Widget _tableHeaderCell(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text.toUpperCase(),
      textAlign: align,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: kSubText,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildWebTableRow(
    Customer customer,
    CustomerController controller,
    BuildContext context,
  ) {
    final statusColor = customer.isActive ? kSuccess : kDanger;
    final hasOutstanding = customer.outstandingAmount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCustomerDetails(customer, controller, context),
        hoverColor: kPrimary.withOpacity(0.03),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: kPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Name + Email
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        customer.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (customer.email.isNotEmpty)
                        Text(
                          customer.email,
                          style: TextStyle(fontSize: 11, color: kSubText),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              // Phone
              Expanded(
                flex: 3,
                child: Text(
                  customer.phone.isNotEmpty ? customer.phone : '—',
                  style: TextStyle(fontSize: 12, color: kSubText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Payment Terms
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    customer.paymentTerms,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: kPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Invoice count
              Expanded(
                flex: 2,
                child: Text(
                  customer.invoiceCount.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: kSubText),
                ),
              ),
              // Total Sales
              Expanded(
                flex: 2,
                child: Text(
                  _formatAmount(customer.totalAmount),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
              ),
              // Paid
              Expanded(
                flex: 2,
                child: Text(
                  _formatAmount(customer.paidAmount),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kSuccess,
                  ),
                ),
              ),
              // Outstanding
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: hasOutstanding
                          ? kDanger.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatAmount(customer.outstandingAmount),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: hasOutstanding ? kDanger : kSuccess,
                      ),
                    ),
                  ),
                ),
              ),
              // Status
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      customer.isActive ? 'ACT' : 'INA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ),
              // Actions
              SizedBox(
                width: 68,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _webIconBtn(
                      Icons.remove_red_eye_outlined,
                      kSubText,
                      () => _showCustomerDetails(customer, controller, context),
                    ),
                    const SizedBox(width: 4),
                    if (hasOutstanding)
                      _webIconBtn(
                        Icons.payment,
                        kSuccess,
                        () => _recordPayment(customer, controller, context),
                      )
                    else
                      _webIconBtn(
                        Icons.edit_outlined,
                        kSubText,
                        () => _editCustomer(customer, controller, context),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _webIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  Widget _buildWebTableFooter(List<Customer> customers) {
    final activeCount = customers.where((c) => c.isActive).length;
    final withBalanceCount = customers
        .where((c) => c.outstandingAmount > 0)
        .length;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.04),
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32),
          const Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                'TOTALS',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const Expanded(flex: 3, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$activeCount ACTIVE',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: kSuccess,
                    ),
                  ),
                  if (withBalanceCount > 0)
                    Text(
                      '$withBalanceCount OWED',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: kWarning,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(customers.fold(0.0, (s, c) => s + c.totalAmount)),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(customers.fold(0.0, (s, c) => s + c.paidAmount)),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: kSuccess,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: kDanger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatAmount(
                    customers.fold(0.0, (s, c) => s + c.outstandingAmount),
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: kDanger,
                  ),
                ),
              ),
            ),
          ),
          const Expanded(flex: 1, child: SizedBox()),
          const SizedBox(width: 68),
        ],
      ),
    );
  }

  // ==================== WEB PAGINATION BAR ====================

  Widget _buildWebPaginationBar(CustomerController controller) {
    return Obx(
      () => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: kCardBg,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${controller.getFilteredCustomers().length} of ${controller.totalCustomers.value} customers',
              style: TextStyle(fontSize: 13, color: kSubText),
            ),
            Row(
              children: [
                _paginationBtn(Icons.chevron_left, 'Previous', false, null),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Page 1',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _paginationBtn(Icons.chevron_right, 'Next', false, null),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginationBtn(
    IconData icon,
    String label,
    bool enabled,
    VoidCallback? onTap,
  ) {
    final color = enabled ? kPrimary : Colors.grey;
    final isNext = label == 'Next';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled ? kPrimary : Colors.grey.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (!isNext) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
              ],
              Text(label, style: TextStyle(fontSize: 12, color: color)),
              if (isNext) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 18, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== DIALOGS ====================

  void _showMobileSearch(BuildContext context, CustomerController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Search Customers',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Name, email, or phone…',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => controller.searchCustomers(v),
          onSubmitted: (_) => Navigator.pop(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.searchCustomers('');
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(CustomerController controller, BuildContext ctx) {
    final isWeb = ResponsiveUtils.isWeb(ctx);
    final formKey = GlobalKey<FormState>();
    String name = '',
        email = '',
        phone = '',
        address = '',
        taxId = '',
        paymentTerms = 'Net 30';

    showDialog(
      context: ctx,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isWeb ? 12 : 16),
        ),
        child: Container(
          width: isWeb ? 480 : double.infinity,
          constraints: BoxConstraints(maxHeight: isWeb ? 620 : 560),
          padding: EdgeInsets.all(isWeb ? 24 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Add Customer',
                    style: TextStyle(
                      fontSize: isWeb ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Divider(
                height: isWeb ? 20 : 16,
                color: Colors.grey.withOpacity(0.2),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        _formField(
                          'Customer Name *',
                          '',
                          (v) => name = v,
                          isWeb: isWeb,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Name required' : null,
                        ),
                        const SizedBox(height: 12),
                        if (isWeb)
                          Row(
                            children: [
                              Expanded(
                                child: _formField(
                                  'Email',
                                  '',
                                  (v) => email = v,
                                  isWeb: isWeb,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _formField(
                                  'Phone *',
                                  '',
                                  (v) => phone = v,
                                  isWeb: isWeb,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Phone required'
                                      : null,
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _formField(
                            'Email',
                            '',
                            (v) => email = v,
                            isWeb: isWeb,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _formField(
                            'Phone *',
                            '',
                            (v) => phone = v,
                            isWeb: isWeb,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Phone required'
                                : null,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _formField(
                          'Address',
                          '',
                          (v) => address = v,
                          isWeb: isWeb,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        if (isWeb)
                          Row(
                            children: [
                              Expanded(
                                child: _formField(
                                  'Tax ID',
                                  '',
                                  (v) => taxId = v,
                                  isWeb: isWeb,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPaymentTermsDropdown(
                                  paymentTerms,
                                  (v) => paymentTerms = v!,
                                  isWeb,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _formField(
                            'Tax ID',
                            '',
                            (v) => taxId = v,
                            isWeb: isWeb,
                          ),
                          const SizedBox(height: 12),
                          _buildPaymentTermsDropdown(
                            paymentTerms,
                            (v) => paymentTerms = v!,
                            isWeb,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: isWeb ? 20 : 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isWeb ? 10 : 12,
                        ),
                        side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: isWeb ? 13 : 14,
                          color: kSubText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isProcessing.value
                            ? null
                            : () {
                                if (formKey.currentState!.validate()) {
                                  Navigator.pop(context);
                                  controller.createCustomer({
                                    'name': name,
                                    'email': email,
                                    'phone': phone,
                                    'address': address,
                                    'taxId': taxId,
                                    'paymentTerms': paymentTerms,
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          padding: EdgeInsets.symmetric(
                            vertical: isWeb ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isProcessing.value
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: LoadingAnimationWidget.waveDots(
                                  color: Colors.black87,
                                  size: 20,
                                ),
                              )
                            : Text(
                                'Add Customer',
                                style: TextStyle(
                                  fontSize: isWeb ? 13 : 14,
                                  color: Colors.black87,
                                ),
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
    );
  }

  void _editCustomer(
    Customer customer,
    CustomerController controller,
    BuildContext ctx,
  ) {
    final isWeb = ResponsiveUtils.isWeb(ctx);
    final formKey = GlobalKey<FormState>();
    String name = customer.name;
    String email = customer.email;
    String phone = customer.phone;
    String address = customer.address;
    String taxId = customer.taxId;
    String paymentTerms = customer.paymentTerms;
    bool isActive = customer.isActive;

    showDialog(
      context: ctx,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isWeb ? 12 : 16),
          ),
          child: Container(
            width: isWeb ? 480 : double.infinity,
            constraints: BoxConstraints(maxHeight: isWeb ? 640 : 580),
            padding: EdgeInsets.all(isWeb ? 24 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Edit Customer',
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: kText,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Divider(
                  height: isWeb ? 20 : 16,
                  color: Colors.grey.withOpacity(0.2),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          _formField(
                            'Customer Name *',
                            '',
                            (v) => name = v,
                            initialValue: name,
                            isWeb: isWeb,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Name required' : null,
                          ),
                          const SizedBox(height: 12),
                          if (isWeb)
                            Row(
                              children: [
                                Expanded(
                                  child: _formField(
                                    'Email',
                                    '',
                                    (v) => email = v,
                                    initialValue: email,
                                    isWeb: isWeb,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _formField(
                                    'Phone *',
                                    '',
                                    (v) => phone = v,
                                    initialValue: phone,
                                    isWeb: isWeb,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Phone required'
                                        : null,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _formField(
                              'Email',
                              '',
                              (v) => email = v,
                              initialValue: email,
                              isWeb: isWeb,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            _formField(
                              'Phone *',
                              '',
                              (v) => phone = v,
                              initialValue: phone,
                              isWeb: isWeb,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Phone required'
                                  : null,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _formField(
                            'Address',
                            '',
                            (v) => address = v,
                            initialValue: address,
                            isWeb: isWeb,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          if (isWeb)
                            Row(
                              children: [
                                Expanded(
                                  child: _formField(
                                    'Tax ID',
                                    '',
                                    (v) => taxId = v,
                                    initialValue: taxId,
                                    isWeb: isWeb,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPaymentTermsDropdown(
                                    paymentTerms,
                                    (v) => paymentTerms = v!,
                                    isWeb,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _formField(
                              'Tax ID',
                              '',
                              (v) => taxId = v,
                              initialValue: taxId,
                              isWeb: isWeb,
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentTermsDropdown(
                              paymentTerms,
                              (v) => paymentTerms = v!,
                              isWeb,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: isWeb ? 13 : 12,
                                  color: kText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: isActive,
                                onChanged: (v) => setState(() => isActive = v),
                                activeColor: kSuccess,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isWeb ? 20 : 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isWeb ? 10 : 12,
                          ),
                          side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: isWeb ? 13 : 14,
                            color: kSubText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isProcessing.value
                              ? null
                              : () {
                                  if (formKey.currentState!.validate()) {
                                    Navigator.pop(context);
                                    controller.updateCustomer(customer.id, {
                                      'name': name,
                                      'email': email,
                                      'phone': phone,
                                      'address': address,
                                      'taxId': taxId,
                                      'paymentTerms': paymentTerms,
                                      'isActive': isActive,
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: EdgeInsets.symmetric(
                              vertical: isWeb ? 10 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          child: controller.isProcessing.value
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: LoadingAnimationWidget.waveDots(
                                    color: Colors.black87,
                                    size: 20,
                                  ),
                                )
                              : Text(
                                  'Update Customer',
                                  style: TextStyle(
                                    fontSize: isWeb ? 13 : 14,
                                    color: Colors.black87,
                                  ),
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

  void _showCustomerDetails(
    Customer customer,
    CustomerController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final statusColor = customer.isActive ? kSuccess : kDanger;
    final hasOutstanding = customer.outstandingAmount > 0;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isWeb ? 12 : 16),
        ),
        child: Container(
          width: isWeb ? 420 : double.infinity,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: EdgeInsets.all(isWeb ? 24 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isWeb ? 44 : 50,
                    height: isWeb ? 44 : 50,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 22,
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
                            fontSize: isWeb ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        Text(
                          customer.email.isNotEmpty
                              ? customer.email
                              : customer.phone,
                          style: TextStyle(
                            fontSize: isWeb ? 12 : 13,
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      customer.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (customer.phone.isNotEmpty)
                        _buildDetailRow('Phone', customer.phone, isWeb),
                      if (customer.address.isNotEmpty)
                        _buildDetailRow('Address', customer.address, isWeb),
                      if (customer.taxId.isNotEmpty)
                        _buildDetailRow('Tax ID', customer.taxId, isWeb),
                      _buildDetailRow(
                        'Payment Terms',
                        customer.paymentTerms,
                        isWeb,
                      ),
                      _buildDetailRow(
                        'Total Invoices',
                        customer.invoiceCount.toString(),
                        isWeb,
                      ),
                      Divider(height: 20, color: Colors.grey.withOpacity(0.15)),
                      _buildDetailRow(
                        'Total Sales',
                        _formatAmount(customer.totalAmount),
                        isWeb,
                      ),
                      _buildDetailRow(
                        'Paid Amount',
                        _formatAmount(customer.paidAmount),
                        isWeb,
                        valueColor: kSuccess,
                      ),
                      _buildDetailRow(
                        'Outstanding',
                        _formatAmount(customer.outstandingAmount),
                        isWeb,
                        valueColor: hasOutstanding ? kDanger : kSuccess,
                      ),
                      if (customer.lastPaymentDate != null)
                        _buildDetailRow(
                          'Last Payment',
                          DateFormat(
                            'dd MMM yyyy',
                          ).format(customer.lastPaymentDate!),
                          isWeb,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _viewInvoices(customer, controller, ctx);
                      },
                      icon: const Icon(Icons.receipt, size: 16),
                      label: const Text(
                        'Invoices',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isWeb ? 10 : 12,
                        ),
                        side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (hasOutstanding)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _recordPayment(customer, controller, ctx);
                        },
                        icon: const Icon(
                          Icons.payment,
                          size: 16,
                          color: Colors.black87,
                        ),
                        label: const Text(
                          'Pay Now',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccess,
                          padding: EdgeInsets.symmetric(
                            vertical: isWeb ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _editCustomer(customer, controller, ctx);
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isWeb ? 10 : 12,
                          ),
                          side: BorderSide(color: Colors.grey.withOpacity(0.4)),
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
    );
  }

  void _showFilterDialog(CustomerController controller, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Filter Options',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.people, color: kPrimary),
              title: const Text(
                'Active Customers Only',
                style: TextStyle(fontSize: 14),
              ),
              trailing: Obx(
                () => Switch(
                  value: controller.selectedFilter.value == 'Active',
                  onChanged: (v) {
                    Navigator.pop(context);
                    controller.changeFilter(v ? 'Active' : 'All');
                  },
                  activeColor: kSuccess,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.payment, color: kDanger),
              title: const Text(
                'With Outstanding Balance',
                style: TextStyle(fontSize: 14),
              ),
              trailing: Obx(
                () => Switch(
                  value: controller.selectedFilter.value == 'With Balance',
                  onChanged: (v) {
                    Navigator.pop(context);
                    controller.changeFilter(v ? 'With Balance' : 'All');
                  },
                  activeColor: kDanger,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.clear_all, color: kSubText),
              title: const Text(
                'Clear All Filters',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                controller.changeFilter('All');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ==================== FORM HELPERS ====================

  Widget _formField(
    String label,
    String hint,
    void Function(String) onChanged, {
    String initialValue = '',
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
    required bool isWeb,
  }) {
    return TextFormField(
      initialValue: initialValue.isEmpty ? null : initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint.isEmpty ? null : hint,
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: isWeb ? 12 : 11, color: kSubText),
      ),
      style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildPaymentTermsDropdown(
    String value,
    void Function(String?) onChanged,
    bool isWeb,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Payment Terms',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: isWeb ? 12 : 11, color: kSubText),
      ),
      style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText),
      items: const [
        DropdownMenuItem(
          value: 'Due on Receipt',
          child: Text('Due on Receipt'),
        ),
        DropdownMenuItem(value: 'Net 7', child: Text('Net 7 days')),
        DropdownMenuItem(value: 'Net 15', child: Text('Net 15 days')),
        DropdownMenuItem(value: 'Net 30', child: Text('Net 30 days')),
        DropdownMenuItem(value: 'Net 45', child: Text('Net 45 days')),
        DropdownMenuItem(value: 'Net 60', child: Text('Net 60 days')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isWeb, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isWeb ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isWeb ? 110 : 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isWeb ? 12 : 13,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isWeb ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? kText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _viewInvoices(
    Customer customer,
    CustomerController controller,
    BuildContext context,
  ) {
    Get.to(() => InvoicesScreen(customerId: customer.id));
  }

  void _recordPayment(
    Customer customer,
    CustomerController controller,
    BuildContext context,
  ) {
    Get.to(() => PaymentsReceivedScreen(customerId: customer.id));
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}
