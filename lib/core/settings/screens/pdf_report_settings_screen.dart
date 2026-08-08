import 'dart:io';

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/core/settings/controller/pdf_report_settings_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

class PdfReportSettingsScreen extends StatelessWidget {
  const PdfReportSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PdfReportSettingsController());
    final isWeb = ResponsiveUtils.isWeb(context);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(isWeb: isWeb),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.companyName.value.isEmpty &&
                    controller.logoPath.value.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  );
                }
                return isWeb
                    ? _WebBody(controller: controller)
                    : _MobileBody(controller: controller);
              }),
            ),
            _SaveBar(controller: controller, isWeb: isWeb),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isWeb});
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    final showBack = Navigator.canPop(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        isWeb ? 32 : 16,
        isWeb ? 28 : 16,
        isWeb ? 32 : 16,
        isWeb ? 20 : 14,
      ),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Iconify(Mdi.arrow_left, color: kPrimary, size: 22),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kPrimary, kPrimaryDark]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Iconify(
              Mdi.file_pdf_box,
              color: Colors.white,
              size: 26,
            ),
          ),
          SizedBox(width: isWeb ? 20 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDF Report Settings',
                  style: TextStyle(
                    fontSize: isWeb ? 26 : 20,
                    fontWeight: FontWeight.w800,
                    color: kText,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Configure logo, signature, layout & branding for all PDF reports',
                  style: TextStyle(fontSize: isWeb ? 14 : 12.5, color: kSubText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.controller, required this.isWeb});
  final PdfReportSettingsController controller;
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isWeb ? 32 : 16,
        12,
        isWeb ? 32 : 16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(top: BorderSide(color: kBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => Text(
                controller.syncedFromPrefs.value
                    ? 'PDF branding is stored separately from company profile'
                    : 'Set branding for PDF exports',
                style: TextStyle(fontSize: 12, color: kSubText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Obx(
            () => ElevatedButton.icon(
              onPressed: controller.isSaving.value
                  ? null
                  : controller.saveSettings,
              icon: controller.isSaving.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.save_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
              label: Text(
                controller.isSaving.value ? 'Saving…' : 'Save',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 20 : 14,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebBody extends StatelessWidget {
  const _WebBody({required this.controller});
  final PdfReportSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 900;
          final left = Column(
            children: [
              _BrandingCard(controller: controller),
              const SizedBox(height: 16),
              _LayoutCard(controller: controller),
              const SizedBox(height: 16),
              _ContentCard(controller: controller),
              const SizedBox(height: 16),
              _DisplayTogglesCard(controller: controller),
            ],
          );
          final right = Column(
            children: [
              _PreviewCard(controller: controller),
              const SizedBox(height: 16),
              _AccentCard(controller: controller),
            ],
          );

          if (stacked) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  right,
                  const SizedBox(height: 16),
                  left,
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: SingleChildScrollView(child: left),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: SingleChildScrollView(child: right),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MobileBody extends StatelessWidget {
  const _MobileBody({required this.controller});
  final PdfReportSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          _PreviewCard(controller: controller),
          const SizedBox(height: 14),
          _BrandingCard(controller: controller),
          const SizedBox(height: 14),
          _LayoutCard(controller: controller),
          const SizedBox(height: 14),
          _ContentCard(controller: controller),
          const SizedBox(height: 14),
          _DisplayTogglesCard(controller: controller),
          const SizedBox(height: 14),
          _AccentCard(controller: controller),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String icon;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCardBg,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Iconify(icon, size: 18, color: kPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 11.5, color: kSubText),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _BrandingCard extends StatelessWidget {
  const _BrandingCard({required this.controller});
  final PdfReportSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'PDF branding',
      subtitle: 'Saved separately — does not change company profile',
      icon: Mdi.office_building,
      child: Column(
        children: [
          Obx(
            () => controller.syncedFromPrefs.value
                ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: kSuccess.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kSuccess.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sync, size: 16, color: kSuccess),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Suggested from profile on first open — save stores PDF-only copy',
                            style: TextStyle(
                              fontSize: 12,
                              color: kSuccess,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          TextField(
            controller: controller.companyNameController,
            onChanged: (v) => controller.companyName.value = v,
            decoration: _inputDecoration('Company name on reports'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.companyAddressController,
            onChanged: (v) => controller.companyAddress.value = v,
            maxLines: 2,
            decoration: _inputDecoration('Company address'),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 360;
              final logo = _MediaBox(
                title: 'Company logo',
                path: controller.logoPath,
                onPick: controller.pickLogo,
                onClear: controller.clearLogo,
                emptyIcon: Mdi.image_outline,
              );
              final signature = _MediaBox(
                title: 'Signature',
                path: controller.signaturePath,
                onPick: controller.pickSignature,
                onClear: controller.clearSignature,
                emptyIcon: Mdi.draw,
                extraAction: () => controller.drawSignature(context),
                extraLabel: 'Draw',
              );
              if (stacked) {
                return Column(
                  children: [
                    logo,
                    const SizedBox(height: 12),
                    signature,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: logo),
                  const SizedBox(width: 12),
                  Expanded(child: signature),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MediaBox extends StatelessWidget {
  const _MediaBox({
    required this.title,
    required this.path,
    required this.onPick,
    required this.onClear,
    required this.emptyIcon,
    this.extraAction,
    this.extraLabel,
  });

  final String title;
  final RxString path;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final String emptyIcon;
  final VoidCallback? extraAction;
  final String? extraLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: kSubText,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final has = path.value.isNotEmpty;
          final network = path.value.startsWith('http');
          return Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: has
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(path.value, network),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          onTap: onClear,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Iconify(emptyIcon, size: 32, color: kSubText),
                  ),
          );
        }),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _smallBtn('Upload', Icons.upload_outlined, onPick),
            if (extraAction != null)
              _smallBtn(extraLabel ?? 'Action', Icons.edit, extraAction!),
          ],
        ),
      ],
    );
  }

  Widget _buildImage(String path, bool network) {
    if (network) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.broken_image_outlined, color: kSubText),
      );
    }
    if (kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.broken_image_outlined, color: kSubText),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.broken_image_outlined, color: kSubText),
    );
  }

  Widget _smallBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kPrimary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: kPrimary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutCard extends StatelessWidget {
  const _LayoutCard({required this.controller});
  final PdfReportSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Report layout',
      subtitle: 'Choose how headers appear on PDFs',
      icon: Mdi.view_dashboard_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Style', style: _labelStyle),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.layouts.map((l) {
                final selected = controller.layout.value == l;
                return ChoiceChip(
                  label: Text(
                    l[0].toUpperCase() + l.substring(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : kText,
                      fontSize: 12.5,
                    ),
                  ),
                  selected: selected,
                  selectedColor: kPrimary,
                  backgroundColor: kBg,
                  onSelected: (_) => controller.layout.value = l,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Text('Logo position', style: _labelStyle),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.logoPositions.map((p) {
                final selected = controller.logoPosition.value == p;
                return ChoiceChip(
                  label: Text(
                    p[0].toUpperCase() + p.substring(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : kText,
                      fontSize: 12.5,
                    ),
                  ),
                  selected: selected,
                  selectedColor: kPrimary,
                  backgroundColor: kBg,
                  onSelected: (_) => controller.logoPosition.value = p,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.controller});
  final PdfReportSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Header & footer text',
      subtitle: 'Shown on every generated PDF report',
      icon: Mdi.text_box_outline,
      child: Column(
        children: [
          TextField(
            controller: controller.headerSubtitleController,
            decoration: _inputDecoration('Header subtitle (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.footerTextController,
            decoration: _inputDecoration('Footer text'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.signatureLabelController,
            decoration: _inputDecoration('Signature label'),
          ),
        ],
      ),
    );
  }
}

class _DisplayTogglesCard extends StatelessWidget {
  const _DisplayTogglesCard({required this.controller});
  final PdfReportSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Display options',
      subtitle: 'Toggle what appears on PDF reports',
      icon: Mdi.toggle_switch_outline,
      child: Column(
        children: [
          _toggle('Show company logo', controller.showLogo),
          _toggle('Show company name', controller.showCompanyName),
          _toggle('Show company address', controller.showAddress),
          _toggle('Show signature', controller.showSignature),
          _toggle('Show page numbers', controller.showPageNumbers),
        ],
      ),
    );
  }

  Widget _toggle(String label, RxBool value) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: kText,
                ),
              ),
            ),
            Switch.adaptive(
              value: value.value,
              activeColor: kPrimary,
              onChanged: (v) => value.value = v,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentCard extends StatelessWidget {
  const _AccentCard({required this.controller});
  final PdfReportSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Accent color',
      subtitle: 'Used for PDF header bars and highlights',
      icon: Mdi.palette_outline,
      child: Obx(
        () => Wrap(
          spacing: 10,
          runSpacing: 10,
          children: controller.accentPresets.map((hex) {
            final selected = controller.accentColor.value == hex;
            final color = Color(
              int.parse('FF${hex.replaceAll('#', '')}', radix: 16),
            );
            return GestureDetector(
              onTap: () => controller.accentColor.value = hex,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? kText : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.controller});
  final PdfReportSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Live preview',
      subtitle: 'Approximate PDF header / footer appearance',
      icon: Mdi.eye_outline,
      child: Obx(() {
        final accent = controller.accent;
        final layout = controller.layout.value;
        final pos = controller.logoPosition.value;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(layout == 'minimal' ? 8 : 12),
                decoration: BoxDecoration(
                  color: layout == 'modern'
                      ? accent.withOpacity(0.08)
                      : Colors.white,
                  border: layout == 'classic'
                      ? Border(bottom: BorderSide(color: accent, width: 2.5))
                      : null,
                  borderRadius: layout == 'modern'
                      ? BorderRadius.circular(8)
                      : null,
                ),
                child: _previewHeader(accent, pos),
              ),
              const SizedBox(height: 18),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              if (controller.showSignature.value) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (controller.signaturePath.value.isNotEmpty)
                        SizedBox(
                          height: 36,
                          width: 120,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: _previewImage(
                              controller.signaturePath.value,
                              controller.signatureIsNetwork,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 100,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        controller.signatureLabelController.text.isEmpty
                            ? 'Authorized Signature'
                            : controller.signatureLabelController.text,
                        style: TextStyle(fontSize: 10, color: kSubText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Divider(height: 1, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.footerTextController.text.isEmpty
                          ? 'Confidential - For Internal Use Only'
                          : controller.footerTextController.text,
                      style: TextStyle(fontSize: 10, color: kSubText),
                    ),
                  ),
                  if (controller.showPageNumbers.value)
                    Text(
                      'Page 1',
                      style: TextStyle(fontSize: 10, color: kSubText),
                    ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _previewHeader(Color accent, String pos) {
    final logo = controller.showLogo.value && controller.logoPath.value.isNotEmpty
        ? SizedBox(
            width: 42,
            height: 42,
            child: FittedBox(
              fit: BoxFit.contain,
              child: _previewImage(
                controller.logoPath.value,
                controller.logoIsNetwork,
              ),
            ),
          )
        : (controller.showLogo.value
              ? Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.business, color: accent, size: 22),
                )
              : const SizedBox.shrink());

    final textBlock = Column(
      crossAxisAlignment: pos == 'center'
          ? CrossAxisAlignment.center
          : (pos == 'right'
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start),
      children: [
        if (controller.showCompanyName.value)
          Text(
            controller.companyName.value.isEmpty
                ? 'Your Company'
                : controller.companyName.value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
            textAlign: pos == 'center' ? TextAlign.center : null,
          ),
        if (controller.showAddress.value &&
            controller.companyAddress.value.isNotEmpty)
          Text(
            controller.companyAddress.value,
            style: TextStyle(fontSize: 10, color: kSubText),
            textAlign: pos == 'center' ? TextAlign.center : null,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (controller.headerSubtitleController.text.trim().isNotEmpty)
          Text(
            controller.headerSubtitleController.text.trim(),
            style: TextStyle(fontSize: 10, color: kSubText),
          ),
      ],
    );

    if (pos == 'center') {
      return Column(
        children: [
          logo,
          const SizedBox(height: 8),
          textBlock,
        ],
      );
    }
    if (pos == 'right') {
      return Row(
        children: [
          Expanded(child: textBlock),
          const SizedBox(width: 10),
          logo,
        ],
      );
    }
    return Row(
      children: [
        logo,
        const SizedBox(width: 10),
        Expanded(child: textBlock),
      ],
    );
  }

  Widget _previewImage(String path, bool network) {
    if (network || kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.broken_image_outlined, color: kSubText, size: 18),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.broken_image_outlined, color: kSubText, size: 18),
    );
  }
}

TextStyle get _labelStyle => TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: kSubText,
);

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(fontSize: 13, color: kSubText),
    filled: true,
    fillColor: kBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kPrimary, width: 1.5),
    ),
  );
}
