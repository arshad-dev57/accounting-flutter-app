import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehouse/Stock_in/controller/stock_in_controller.dart';
import 'package:LedgerPro_app/core/warehouse/Stock_in/model/stock_movement_model.dart';
import 'package:LedgerPro_app/core/warehouse/Stock_in/widgets/stock_history_list.dart';
import 'package:LedgerPro_app/core/warehouse/Stock_in/widgets/stock_in_form.dart';
import 'package:LedgerPro_app/core/warehouse/Stock_in/widgets/stock_movement_detail_sheet.dart';
import 'package:LedgerPro_app/core/warehouse/Stock_in/widgets/stock_out_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StockController());

    return Scaffold(
      backgroundColor: kBgLight,
      body: Obx(() {
        return Column(
          children: [
            _buildTopHeader(controller),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildTabBar(controller),
                    const SizedBox(height: 16),
                    if (controller.activeTab.value == 'in')
                      StockInForm(
                        controller: controller,
                        onSuccess: controller.refreshMovements,
                      )
                    else
                      StockOutForm(
                        controller: controller,
                        onSuccess: controller.refreshMovements,
                      ),
                    const SizedBox(height: 20),
                    StockHistoryList(
                      controller: controller,
                      onView: (m) => _showDetail(context, controller, m),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTopHeader(StockController controller) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock Movement',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Obx(() => Text(
                          '${controller.totalRecords.value} movements',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                      ],
                    ),
                  ),
                  Obx(() => Row(
                    children: [
                      _compactKpi('In', controller.totalInCount.value.toString(), Colors.green.shade800),
                      const SizedBox(width: 10),
                      _compactKpi('Out', controller.totalOutCount.value.toString(), Colors.red.shade800),
                      const SizedBox(width: 10),
                      _compactKpi('Today', controller.todayCount.value.toString(), Colors.blue.shade800),
                    ],
                  )),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: controller.refreshMovements,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(Icons.refresh_rounded, size: 17, color: Colors.black.withOpacity(0.65)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _SearchField(controller: controller),
              ),
            ),
            Obx(() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  _filterChip('All', controller.typeFilter.value == 'all', () => controller.applyTypeFilter('all')),
                  _filterChip('Stock In', controller.typeFilter.value == 'in', () => controller.applyTypeFilter('in')),
                  _filterChip('Stock Out', controller.typeFilter.value == 'out', () => controller.applyTypeFilter('out')),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _compactKpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.black.withOpacity(0.5), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? Colors.black : Colors.white.withOpacity(0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(StockController controller) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              label: 'Stock In',
              icon: Icons.trending_up,
              selected: controller.activeTab.value == 'in',
              selectedColor: Colors.green.shade600,
              onTap: () => controller.setActiveTab('in'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _tabButton(
              label: 'Stock Out',
              icon: Icons.trending_down,
              selected: controller.activeTab.value == 'out',
              selectedColor: Colors.red.shade600,
              onTap: () => controller.setActiveTab('out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required IconData icon,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? selectedColor : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : kSubText),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? Colors.white : kSubText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, StockController controller, StockMovementModel movement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.93,
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: StockMovementDetailSheet(
                    controller: controller,
                    movement: movement,
                    onClose: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final StockController controller;
  const _SearchField({required this.controller});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) {
        setState(() {});
        v.isEmpty ? widget.controller.clearSearch() : widget.controller.searchMovements(v);
      },
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Search movements...',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  widget.controller.clearSearch();
                  setState(() {});
                },
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        isDense: true,
      ),
    );
  }
}
