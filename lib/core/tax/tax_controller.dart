import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/tax/tax_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

TaxController ensureTaxController() {
  if (!Get.isRegistered<TaxController>()) {
    Get.put(TaxController(), permanent: true);
  }
  return Get.find<TaxController>();
}

class TaxController extends GetxService {
  final TaxService _service = TaxService();

  final isLoading = false.obs;
  final configured = false.obs;
  final enabled = false.obs;
  final profile = Rxn<Map<String, dynamic>>();
  final countryPacks = <Map<String, dynamic>>[].obs;
  final rates = <Map<String, dynamic>>[].obs;
  final types = <Map<String, dynamic>>[].obs;
  final jurisdictions = <Map<String, dynamic>>[].obs;
  final exemptionTypes = <Map<String, dynamic>>[].obs;
  final exemptions = <Map<String, dynamic>>[].obs;
  final overview = Rxn<Map<String, dynamic>>();
  final liability = <Map<String, dynamic>>[].obs;

  final selectedCountry = 'AE'.obs;
  final pricingModel = 'exclusive'.obs;
  final regime = 'VAT'.obs;
  final filingFrequency = 'quarterly'.obs;
  final registrationCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      final ctx = await _service.context();
      if (ctx.success && ctx.data is Map) {
        final data = Map<String, dynamic>.from(ctx.data['data'] ?? ctx.data ?? {});
        configured.value = data['configured'] == true;
        enabled.value = data['enabled'] == true;
        profile.value = data['profile'] is Map
            ? Map<String, dynamic>.from(data['profile'])
            : null;
        countryPacks.assignAll(
          List.from(data['countryPacks'] ?? []).map((e) => Map<String, dynamic>.from(e)),
        );
        rates.assignAll(
          List.from(data['rates'] ?? []).map((e) => Map<String, dynamic>.from(e)),
        );
        final p = profile.value;
        if (p?['countryCode'] != null) selectedCountry.value = p!['countryCode'];
        if (p?['pricingModel'] != null) pricingModel.value = p!['pricingModel'];
        if (p?['regime'] != null) regime.value = p!['regime'];
        if (p?['filingFrequency'] != null) filingFrequency.value = p!['filingFrequency'];
        registrationCtrl.text = p?['taxRegistrationNumber']?.toString() ?? '';
      }

      final results = await Future.wait([
        _service.overview(),
        _service.types(),
        _service.jurisdictions(),
        _service.exemptionTypes(),
        _service.exemptions(),
      ]);

      final ov = results[0];
      if (ov.success && ov.data is Map) {
        overview.value = Map<String, dynamic>.from(ov.data['data'] ?? ov.data ?? {});
        if (overview.value?['enabled'] == true) enabled.value = true;
      }
      _assignList(types, results[1]);
      _assignList(jurisdictions, results[2]);
      _assignList(exemptionTypes, results[3]);
      _assignList(exemptions, results[4]);
    } finally {
      isLoading.value = false;
    }
  }

  void _assignList(RxList<Map<String, dynamic>> target, dynamic res) {
    if (res.success && res.data is Map) {
      final raw = res.data['data'] ?? [];
      target.assignAll(List.from(raw).map((e) => Map<String, dynamic>.from(e)));
    }
  }

  String rateLabel(Map<String, dynamic> r) {
    final name = r['taxTypeName'] ?? r['taxType']?['name'] ?? 'Tax';
    final rate = r['rate'] ?? 0;
    return '$name · $rate%';
  }

  String deriveProductTaxType(Map<String, dynamic>? rate) {
    final code = '${rate?['taxTypeCode'] ?? ''} ${rate?['taxTypeName'] ?? ''}'.toUpperCase();
    if (code.contains('ZERO')) return 'Zero Rated';
    if (code.contains('EXEMPT')) return 'Exempt';
    return pricingModel.value == 'inclusive' ? 'Inclusive' : 'Exclusive';
  }

  Future<void> setEnabled(bool value) async {
    final res = await _service.setEnabled(value);
    if (res.success) {
      enabled.value = value;
      AppSnackbar.success(
        Colors.green,
        value ? 'Taxation ON' : 'Taxation OFF',
        value
            ? 'Tax now applies across POS, sales, purchases and accounting'
            : 'Tax will not be calculated in any document flow',
      );
      await loadAll();
    } else {
      AppSnackbar.error(Colors.red, 'Could not update tax', res.message);
    }
  }

  Future<void> applyCountryPack({bool replace = false}) async {
    isLoading.value = true;
    final res = await _service.setup({
      'countryCode': selectedCountry.value,
      'taxRegistrationNumber': registrationCtrl.text,
      'replaceExisting': replace,
    });
    isLoading.value = false;
    if (res.success) {
      AppSnackbar.success(Colors.green, 'Tax setup', 'Country pack applied across the ERP');
      await loadAll();
    } else {
      AppSnackbar.error(Colors.red, 'Tax setup failed', res.message);
    }
  }

  Future<void> saveProfile() async {
    final res = await _service.saveProfile({
      'countryCode': selectedCountry.value,
      'regime': regime.value,
      'pricingModel': pricingModel.value,
      'taxRegistrationNumber': registrationCtrl.text,
      'filingFrequency': filingFrequency.value,
      'recoverInputTax': regime.value != 'SALES_TAX',
    });
    if (res.success) {
      AppSnackbar.success(Colors.green, 'Saved', 'Tax profile updated company-wide');
      await loadAll();
    } else {
      AppSnackbar.error(Colors.red, 'Save failed', res.message);
    }
  }

  Future<void> addType(String code, String name) async {
    final res = await _service.createType({'code': code, 'name': name, 'calculationType': 'percentage'});
    if (res.success) {
      await loadAll();
    } else {
      AppSnackbar.error(Colors.red, 'Could not add type', res.message);
    }
  }

  Future<void> addJurisdiction(String code, String name, String countryCode) async {
    final res = await _service.createJurisdiction({
      'code': code,
      'name': name,
      'level': 'Country',
      'countryCode': countryCode,
    });
    if (res.success) {
      await loadAll();
    } else {
      AppSnackbar.error(Colors.red, 'Could not add jurisdiction', res.message);
    }
  }

  Future<void> addRate({required String jurisdictionId, required String taxTypeId, required double rate}) async {
    final res = await _service.createRate({
      'jurisdictionId': jurisdictionId,
      'taxTypeId': taxTypeId,
      'rate': rate,
      'effectiveFrom': DateTime.now().toIso8601String(),
      'isDefault': rates.isEmpty,
    });
    if (res.success) {
      AppSnackbar.success(Colors.green, 'Rate added', 'Now available on products and invoices');
      await loadAll();
    } else {
      AppSnackbar.error(Colors.red, 'Could not add rate', res.message);
    }
  }

  Future<void> makeDefault(String id) async {
    final res = await _service.updateRate(id, {'isDefault': true});
    if (res.success) await loadAll();
  }

  Future<void> addExemptionType(String code, String name) async {
    final res = await _service.createExemptionType({
      'code': code,
      'name': name,
      'percentage': 100,
      'requiresCertificate': true,
    });
    if (res.success) await loadAll();
  }

  Future<void> grantExemption({required String typeId, required String customerId, String? cert}) async {
    final res = await _service.createExemption({
      'exemptionTypeId': typeId,
      'customerId': customerId,
      'certificateNumber': cert,
    });
    if (res.success) {
      AppSnackbar.success(Colors.green, 'Exemption granted', 'Applied on matching invoices and POS sales');
      await loadAll();
    } else {
      AppSnackbar.error(Colors.red, 'Could not grant', res.message);
    }
  }

  Future<void> loadLiability(String from, String to) async {
    final res = await _service.liability(startDate: from, endDate: to);
    if (res.success && res.data is Map) {
      final data = Map<String, dynamic>.from(res.data['data'] ?? res.data ?? {});
      liability.assignAll(
        List.from(data['summary'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      );
    }
  }

}
