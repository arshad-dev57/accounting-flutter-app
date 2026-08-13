// core/FiscalYear/screen/fiscal_year_list_screen.dart

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:BisonsTechs_app/core/FiscalYear/models/fiscal_year_model.dart';
import 'package:BisonsTechs_app/core/FiscalYear/utils/fiscal_year_dates.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sizer/sizer.dart';

class FiscalYearListScreen extends StatelessWidget {
  const FiscalYearListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<FiscalYearController>()
        ? Get.find<FiscalYearController>()
        : Get.put(FiscalYearController(), permanent: true);
    return _FiscalYearListBody(controller: controller);
  }
}

class _FiscalYearListBody extends StatefulWidget {
  final FiscalYearController controller;
  const _FiscalYearListBody({required this.controller});

  @override
  State<_FiscalYearListBody> createState() => _FiscalYearListBodyState();
}

class _FiscalYearListBodyState extends State<_FiscalYearListBody> {
  @override
  void initState() {
    super.initState();
    // Always refresh on open; shares in-flight request if splash/dashboard already loading.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.ensureFiscalYearsLoaded(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildMobileLayout(context, widget.controller);
  }

  Widget _buildMobileLayout(
    BuildContext context,
    FiscalYearController controller,
  ) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.fiscalYears.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 40,
            ),
          );
        }

        if (controller.fiscalYears.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 80, color: kSubText),
                SizedBox(height: 2.h),
                Text(
                  controller.error.value.isNotEmpty
                      ? 'Could not load fiscal years'
                      : 'No Fiscal Years Found',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  controller.error.value.isNotEmpty
                      ? controller.error.value
                      : 'Create your first fiscal year to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, color: kSubText),
                ),
                SizedBox(height: 3.h),
                if (controller.error.value.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () =>
                        controller.ensureFiscalYearsLoaded(force: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.black87,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showAddFiscalYearDialog(controller, context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Fiscal Year'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.black87,
                    ),
                  ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.ensureFiscalYearsLoaded(force: true),
          child: ListView.builder(
            padding: EdgeInsets.all(2.w),
            itemCount: controller.fiscalYears.length,
            itemBuilder: (context, index) {
              final fiscalYear = controller.fiscalYears[index];
              return _buildFiscalYearCard(fiscalYear, controller, context);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFiscalYearDialog(controller, context),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    FiscalYearController controller,
  ) {
    return AppBar(
      title: const Text(
        'Fiscal Years',
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
          icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
          onPressed: () {
            controller.ensureFiscalYearsLoaded(force: true);
          },
        ),
      ],
    );
  }

  Widget _buildFiscalYearCard(
    FiscalYear fiscalYear,
    FiscalYearController controller,
    BuildContext context,
  ) {
    final formatter = DateFormat('dd MMM yyyy');
    final isSelected = controller.selectedFiscalYear.value?.id == fiscalYear.id;

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: kPrimary, width: 2) : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: fiscalYear.isOpen
                                ? kSuccess.withOpacity(0.1)
                                : kDanger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            fiscalYear.statusDisplay,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: fiscalYear.isOpen ? kSuccess : kDanger,
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            fiscalYear.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: kText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: kPrimary, size: 20),
                ],
              ),
              SizedBox(height: 1.5.h),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: kSubText),
                  SizedBox(width: 1.w),
                  Text(
                    '${formatter.format(fiscalYear.startDate)} - ${formatter.format(fiscalYear.endDate)}',
                    style: TextStyle(fontSize: 11.sp, color: kSubText),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: kSubText),
                  SizedBox(width: 1.w),
                  Text(
                    'Created: ${formatter.format(fiscalYear.createdAt)}',
                    style: TextStyle(fontSize: 11.sp, color: kSubText),
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isSelected)
                    TextButton.icon(
                      onPressed: () async {
                        await controller.selectFiscalYear(fiscalYear);
                        AppSnackbar.success(
                          kSuccess,
                          'Selected',
                          'Fiscal year selected: ${fiscalYear.name}',
                        );
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Use'),
                      style: TextButton.styleFrom(foregroundColor: kPrimary),
                    ),
                  if (fiscalYear.isOpen)
                    TextButton.icon(
                      onPressed: () => _showCloseConfirmationDialog(
                        fiscalYear,
                        controller,
                        context,
                      ),
                      icon: const Icon(Icons.lock, size: 16),
                      label: const Text('Close'),
                      style: TextButton.styleFrom(foregroundColor: kWarning),
                    ),
                  if (fiscalYear.isClosed)
                    TextButton.icon(
                      onPressed: () =>
                          controller.reopenFiscalYear(fiscalYear.id),
                      icon: const Icon(Icons.lock_open, size: 16),
                      label: const Text('Reopen'),
                      style: TextButton.styleFrom(foregroundColor: kSuccess),
                    ),
                  IconButton(
                    onPressed: () => _showEditFiscalYearDialog(
                      fiscalYear,
                      controller,
                      context,
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    color: kSubText,
                  ),
                  IconButton(
                    onPressed: () => _showDeleteConfirmationDialog(
                      fiscalYear,
                      controller,
                      context,
                    ),
                    icon: const Icon(Icons.delete, size: 18),
                    color: kDanger,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddFiscalYearDialog(
    FiscalYearController controller,
    BuildContext context,
  ) {
    Get.dialog(
      _CreateFiscalYearDialog(controller: controller),
    );
  }

  void _showEditFiscalYearDialog(
    FiscalYear fiscalYear,
    FiscalYearController controller,
    BuildContext context,
  ) {
    final nameController = TextEditingController(text: fiscalYear.name);
    final startDateController = TextEditingController(
      text: DateFormat('dd MMM yyyy').format(fiscalYear.startDate),
    );
    final endDateController = TextEditingController(
      text: DateFormat('dd MMM yyyy').format(fiscalYear.endDate),
    );
    DateTime startDate = fiscalYear.startDate;
    DateTime endDate = fiscalYear.endDate;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Fiscal Year'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Fiscal Year Name',
                  prefixIcon: Icon(Icons.label),
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: startDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    startDate = picked;
                    startDateController.text = DateFormat(
                      'dd MMM yyyy',
                    ).format(picked);
                  }
                },
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: endDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'End Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: startDate,
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    endDate = picked;
                    endDateController.text = DateFormat(
                      'dd MMM yyyy',
                    ).format(picked);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                AppSnackbar.error(kDanger, 'Error', 'Please enter a name');
                return;
              }

              if (endDate.isBefore(startDate)) {
                AppSnackbar.error(
                  kDanger,
                  'Error',
                  'End date must be after start date',
                );
                return;
              }

              controller
                  .updateFiscalYear(
                    id: fiscalYear.id,
                    name: nameController.text,
                    startDate: startDate,
                    endDate: endDate,
                  )
                  .then((success) {
                    if (success) Get.back();
                  });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showCloseConfirmationDialog(
    FiscalYear fiscalYear,
    FiscalYearController controller,
    BuildContext context,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kWarning),
            SizedBox(width: 2.w),
            const Text('Close Fiscal Year'),
          ],
        ),
        content: Text(
          'Are you sure you want to close "${fiscalYear.name}"?\n\n'
          'Once closed, you will not be able to create or modify transactions '
          'in this fiscal year.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.closeFiscalYear(fiscalYear.id).then((success) {
                if (success) Get.back();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kWarning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    FiscalYear fiscalYear,
    FiscalYearController controller,
    BuildContext context,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: kDanger),
            SizedBox(width: 2.w),
            const Text('Delete Fiscal Year'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${fiscalYear.name}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.deleteFiscalYear(fiscalYear.id).then((success) {
                if (success) Get.back();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CreateFiscalYearDialog extends StatefulWidget {
  final FiscalYearController controller;
  const _CreateFiscalYearDialog({required this.controller});

  @override
  State<_CreateFiscalYearDialog> createState() =>
      _CreateFiscalYearDialogState();
}

class _CreateFiscalYearDialogState extends State<_CreateFiscalYearDialog> {
  late final TextEditingController nameController;
  late final TextEditingController startDateController;
  late final TextEditingController endDateController;
  String periodKey = 'Calendar';
  DateTime? startDate;
  DateTime? endDate;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    startDateController = TextEditingController();
    endDateController = TextEditingController();
    _applySuggested('Calendar');
  }

  @override
  void dispose() {
    nameController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  void _applySuggested(String key) {
    final suggested = widget.controller.suggestNextRange(key);
    periodKey = key;
    startDate = suggested.startDate;
    endDate = suggested.endDate;
    nameController.text = suggested.name;
    startDateController.text =
        DateFormat('dd MMM yyyy').format(suggested.startDate);
    endDateController.text =
        DateFormat('dd MMM yyyy').format(suggested.endDate);
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        startDateController.text = DateFormat('dd MMM yyyy').format(picked);
        periodKey = 'Custom';
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
        endDateController.text = DateFormat('dd MMM yyyy').format(picked);
        periodKey = 'Custom';
      });
    }
  }

  Future<void> _submit() async {
    if (nameController.text.trim().isEmpty ||
        startDate == null ||
        endDate == null) {
      AppSnackbar.error(kDanger, 'Error', 'Please fill all fields');
      return;
    }
    if (!endDate!.isAfter(startDate!)) {
      AppSnackbar.error(
        kDanger,
        'Error',
        'Start date must be before end date',
      );
      return;
    }

    setState(() => saving = true);
    final ok = await widget.controller.createFiscalYear(
      name: nameController.text.trim(),
      startDate: startDate!,
      endDate: endDate!,
      periodType: kFiscalPeriodPref[periodKey] ?? 'Custom',
    );
    if (mounted) setState(() => saving = false);
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Create Fiscal Year'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Fiscal Year Name',
                hintText: 'e.g., FY 2027',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            SizedBox(height: 1.5.h),
            DropdownButtonFormField<String>(
              value: periodKey,
              decoration: const InputDecoration(
                labelText: 'Period type',
                prefixIcon: Icon(Icons.date_range),
              ),
              items: const [
                DropdownMenuItem(value: 'Calendar', child: Text('Calendar (Jan–Dec)')),
                DropdownMenuItem(value: 'April', child: Text('April–March')),
                DropdownMenuItem(value: 'July', child: Text('July–June')),
                DropdownMenuItem(value: 'Custom', child: Text('Custom')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  if (v == 'Custom') {
                    periodKey = 'Custom';
                  } else {
                    _applySuggested(v);
                  }
                });
              },
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: startDateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Start Date',
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              onTap: _pickStart,
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: endDateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'End Date',
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              onTap: _pickEnd,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
          ),
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
