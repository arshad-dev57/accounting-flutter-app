import 'dart:convert';
import 'dart:io';

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/signature_dialog.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PDF report branding — stored separately from company profile.
/// API: /api/pdf-report-settings
/// Local: SharedPreferences key [prefsKey] only (does NOT write profile businessDetails).
class PdfReportSettingsController extends GetxController {
  static const String prefsKey = 'pdf_report_settings';

  /// Persist PDF settings from login / API payload into local prefs.
  /// Call after logout clears prefs so exports work immediately after login.
  static Future<void> persistFromLogin(dynamic raw) async {
    if (raw == null) return;
    try {
      final Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = Map<String, dynamic>.from(raw);
      } else if (raw is Map) {
        map = Map<String, dynamic>.from(raw);
      } else {
        return;
      }
      if (map.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        prefsKey,
        json.encode({
          ...map,
          'updatedAt':
              map['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
        }),
      );
      debugPrint('✅ PDF report settings cached from login');
    } catch (e) {
      debugPrint('PDF settings login cache error: $e');
    }
  }

  final ApiClient _api = Get.find<ApiClient>();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final syncedFromPrefs = false.obs;

  final companyName = ''.obs;
  final companyAddress = ''.obs;
  final logoPath = ''.obs;
  final signaturePath = ''.obs;

  final showLogo = true.obs;
  final showSignature = true.obs;
  final showCompanyName = true.obs;
  final showAddress = true.obs;
  final showPageNumbers = true.obs;

  final layout = 'classic'.obs;
  final logoPosition = 'left'.obs;
  final accentColor = '#014582'.obs;

  late final TextEditingController headerSubtitleController;
  late final TextEditingController footerTextController;
  late final TextEditingController signatureLabelController;
  late final TextEditingController companyNameController;
  late final TextEditingController companyAddressController;

  final List<String> layouts = const ['classic', 'modern', 'minimal'];
  final List<String> logoPositions = const ['left', 'center', 'right'];
  final List<String> accentPresets = const [
    '#014582',
    '#0FA3E0',
    '#1B4332',
    '#7F1D1D',
    '#4A044E',
    '#0F172A',
  ];

  @override
  void onInit() {
    super.onInit();
    headerSubtitleController = TextEditingController();
    footerTextController = TextEditingController(
      text: 'Confidential - For Internal Use Only',
    );
    signatureLabelController = TextEditingController(
      text: 'Authorized Signature',
    );
    companyNameController = TextEditingController();
    companyAddressController = TextEditingController();
    bootstrap();
  }

  @override
  void onClose() {
    headerSubtitleController.dispose();
    footerTextController.dispose();
    signatureLabelController.dispose();
    companyNameController.dispose();
    companyAddressController.dispose();
    super.onClose();
  }

  Future<void> bootstrap() async {
    await loadFromLocal();
    await refreshFromApi();
  }

  /// Prefill from local PDF cache only. Profile logo is used only as a
  /// one-time suggestion when PDF settings have never been saved.
  Future<void> loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pdfRaw = prefs.getString(prefsKey);

      if (pdfRaw != null && pdfRaw.isNotEmpty) {
        final local = json.decode(pdfRaw) as Map<String, dynamic>;
        _applyPayload(local);
        syncedFromPrefs.value = true;
        _syncTextControllers();
        return;
      }

      // First-time UX: suggest company name/address/logo/signature from profile
      // but these are NOT written back to profile on save.
      final userRaw = prefs.getString('user_data');
      if (userRaw != null && userRaw.isNotEmpty) {
        final user = json.decode(userRaw) as Map<String, dynamic>;
        final bd =
            (user['businessDetails'] as Map<String, dynamic>?) ??
            <String, dynamic>{};
        companyName.value =
            (user['organizationName'] as String?) ??
            prefs.getString('company_name') ??
            '';
        companyAddress.value =
            (user['address'] as String?) ??
            prefs.getString('company_address') ??
            '';
        logoPath.value = (bd['logo'] as String?) ?? '';
        signaturePath.value = (bd['signature'] as String?) ?? '';
        syncedFromPrefs.value = true;
      } else {
        companyName.value = prefs.getString('company_name') ?? '';
        companyAddress.value = prefs.getString('company_address') ?? '';
      }
      _syncTextControllers();
    } catch (e) {
      debugPrint('PDF settings local load error: $e');
    }
  }

  Future<void> refreshFromApi() async {
    try {
      isLoading.value = true;
      final response = await _api.get('/api/pdf-report-settings');
      if (!response.success) return;

      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) return;

      // Empty API row → keep local/suggested values until user saves
      final hasSaved =
          (data['id'] != null) ||
          ((data['logo'] as String?)?.isNotEmpty == true) ||
          ((data['signature'] as String?)?.isNotEmpty == true) ||
          ((data['companyName'] as String?)?.isNotEmpty == true) ||
          ((data['footerText'] as String?) != null &&
              data['footerText'] != 'Confidential - For Internal Use Only');

      if (hasSaved || data['id'] != null) {
        _applyPayload(data);
        _syncTextControllers();
        await _persistLocalOnly();
      }
    } catch (e) {
      debugPrint('PDF settings API load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _applyPayload(Map<String, dynamic> data) {
    if (data['companyName'] != null) {
      companyName.value = data['companyName'].toString();
    }
    if (data['companyAddress'] != null) {
      companyAddress.value = data['companyAddress'].toString();
    }
    if (data['logo'] != null) {
      logoPath.value = data['logo'].toString();
    }
    if (data['signature'] != null) {
      signaturePath.value = data['signature'].toString();
    }

    final pdf = data['pdfReport'] is Map
        ? Map<String, dynamic>.from(data['pdfReport'] as Map)
        : data;

    showLogo.value = pdf['showLogo'] != false;
    showSignature.value = pdf['showSignature'] != false;
    showCompanyName.value = pdf['showCompanyName'] != false;
    showAddress.value = pdf['showAddress'] != false;
    showPageNumbers.value = pdf['showPageNumbers'] != false;
    layout.value = _oneOf(pdf['layout']?.toString(), layouts, 'classic');
    logoPosition.value = _oneOf(
      pdf['logoPosition']?.toString(),
      logoPositions,
      'left',
    );
    accentColor.value = (pdf['accentColor'] as String?)?.startsWith('#') == true
        ? pdf['accentColor'] as String
        : '#014582';
    headerSubtitleController.text = (pdf['headerSubtitle'] as String?) ?? '';
    footerTextController.text =
        (pdf['footerText'] as String?)?.trim().isNotEmpty == true
        ? pdf['footerText'] as String
        : 'Confidential - For Internal Use Only';
    signatureLabelController.text =
        (pdf['signatureLabel'] as String?)?.trim().isNotEmpty == true
        ? pdf['signatureLabel'] as String
        : 'Authorized Signature';
  }

  void _syncTextControllers() {
    companyNameController.text = companyName.value;
    companyAddressController.text = companyAddress.value;
  }

  String _oneOf(String? value, List<String> options, String fallback) {
    if (value != null && options.contains(value)) return value;
    return fallback;
  }

  Map<String, dynamic> toPayload() {
    return {
      'companyName': companyName.value,
      'companyAddress': companyAddress.value,
      'logo': logoPath.value,
      'signature': signaturePath.value,
      'showLogo': showLogo.value,
      'showSignature': showSignature.value,
      'showCompanyName': showCompanyName.value,
      'showAddress': showAddress.value,
      'showPageNumbers': showPageNumbers.value,
      'layout': layout.value,
      'logoPosition': logoPosition.value,
      'headerSubtitle': headerSubtitleController.text.trim(),
      'footerText': footerTextController.text.trim().isEmpty
          ? 'Confidential - For Internal Use Only'
          : footerTextController.text.trim(),
      'accentColor': accentColor.value,
      'signatureLabel': signatureLabelController.text.trim().isEmpty
          ? 'Authorized Signature'
          : signatureLabelController.text.trim(),
    };
  }

  /// Local cache only — never mutates profile `user_data.businessDetails`.
  Future<void> _persistLocalOnly() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      ...toPayload(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(prefsKey, json.encode(payload));
  }

  Future<void> pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      logoPath.value = image.path;
    }
  }

  Future<void> pickSignature() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      signaturePath.value = image.path;
    }
  }

  Future<void> drawSignature(BuildContext context) async {
    final path = await showSignatureDialog(context);
    if (path != null && path.isNotEmpty) {
      signaturePath.value = path;
    }
  }

  void clearLogo() => logoPath.value = '';
  void clearSignature() => signaturePath.value = '';

  bool get logoIsNetwork => logoPath.value.startsWith('http');
  bool get signatureIsNetwork => signaturePath.value.startsWith('http');

  Color get accent => _hexToColor(accentColor.value);

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return kPrimary;
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  Future<void> saveSettings() async {
    try {
      isSaving.value = true;
      companyName.value = companyNameController.text.trim();
      companyAddress.value = companyAddressController.text.trim();

      final fields = toPayload().map((k, v) => MapEntry(k, v.toString()));

      final filePaths = <String, String>{};
      if (logoPath.value.isNotEmpty &&
          !logoIsNetwork &&
          (kIsWeb || File(logoPath.value).existsSync())) {
        filePaths['logo'] = logoPath.value;
      }
      if (signaturePath.value.isNotEmpty &&
          !signatureIsNetwork &&
          (kIsWeb || File(signaturePath.value).existsSync())) {
        filePaths['signature'] = signaturePath.value;
      }

      final response = await _api.putMultipart(
        '/api/pdf-report-settings',
        fields: fields,
        filePaths: filePaths.isEmpty ? null : filePaths,
      );

      if (response.success) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          _applyPayload(data);
          _syncTextControllers();
        }
        await _persistLocalOnly();
        AppSnackbar.success(
          Colors.green,
          'Saved',
          'PDF report settings saved (separate from profile)',
        );
      } else {
        await _persistLocalOnly();
        AppSnackbar.error(
          kDanger,
          'Partial save',
          response.message.isNotEmpty
              ? response.message
              : 'Saved locally; server sync failed',
        );
      }
    } catch (e) {
      await _persistLocalOnly();
      AppSnackbar.error(kDanger, 'Error', 'Could not sync settings: $e');
    } finally {
      isSaving.value = false;
    }
  }
}
