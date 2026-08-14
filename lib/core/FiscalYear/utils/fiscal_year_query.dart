import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:BisonsTechs_app/core/FiscalYear/models/fiscal_year_model.dart';
import 'package:get/get.dart';

FiscalYearController? ensureFiscalYearController() {
  if (Get.isRegistered<FiscalYearController>()) {
    return Get.find<FiscalYearController>();
  }
  return Get.put(FiscalYearController(), permanent: true);
}

String? currentFiscalYearId() {
  try {
    if (!Get.isRegistered<FiscalYearController>()) return null;
    final id = Get.find<FiscalYearController>().selectedFiscalYearId;
    if (id == null || id.isEmpty) return null;
    return id;
  } catch (_) {
    return null;
  }
}

void putFiscalYearId(Map<String, dynamic> params) {
  final id = currentFiscalYearId();
  if (id != null) params['fiscalYearId'] = id;
}

/// Wait until FY is ready for API calls (loaded + selection when available).
Future<void> waitForFiscalYearReady({
  Duration timeout = const Duration(seconds: 10),
}) async {
  final c = ensureFiscalYearController();
  if (c == null) return;

  await c.ensureFiscalYearsLoaded();

  // First paint sometimes races auth/token — retry once if still empty.
  if (c.fiscalYears.isEmpty &&
      (c.selectedFiscalYearId == null || c.selectedFiscalYearId!.isEmpty)) {
    await c.ensureFiscalYearsLoaded(force: true);
  }

  final deadline = DateTime.now().add(timeout);
  while (c.isLoading.value && DateTime.now().isBefore(deadline)) {
    await Future.delayed(const Duration(milliseconds: 40));
  }
}

/// Reloads when the selected FY *id* changes (ignores object refresh).
Worker? listenFiscalYearChanges(void Function() reload) {
  if (!Get.isRegistered<FiscalYearController>()) return null;
  String? lastId = currentFiscalYearId();
  return ever<FiscalYear?>(
    Get.find<FiscalYearController>().selectedFiscalYear,
    (year) {
      final id = year?.id;
      if (id == lastId) return;
      lastId = id;
      reload();
    },
  );
}
