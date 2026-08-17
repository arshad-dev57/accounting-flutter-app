import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/tax/tax_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

const _kPageBg = Color(0xFFF5F6FA);
const _kCardBg = Color(0xFFFFFFFF);
const _kCardBorder = Color(0xFFEEEFF4);
const _kTextPrimary = Color(0xFF1A1D2E);
const _kTextSub = Color(0xFF8A8FA8);

class TaxComplianceScreen extends StatefulWidget {
  const TaxComplianceScreen({super.key});

  @override
  State<TaxComplianceScreen> createState() => _TaxComplianceScreenState();
}

class _TaxComplianceScreenState extends State<TaxComplianceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TaxController c;

  @override
  void initState() {
    super.initState();
    c = ensureTaxController();
    _tabs = TabController(length: 5, vsync: this);
    c.loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _OverviewTab(c: c),
                _SetupTab(c: c),
                _RatesTab(c: c),
                _ExemptionsTab(c: c),
                _ReportsTab(c: c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Material(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tax Compliance',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'VAT, GST & sales tax for the company',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: c.loadAll,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Setup'),
                Tab(text: 'Rates'),
                Tab(text: 'Exemptions'),
                Tab(text: 'Reports'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDec(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    labelStyle: const TextStyle(color: _kTextSub, fontSize: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kCardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kCardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

class _OverviewTab extends StatelessWidget {
  final TaxController c;
  const _OverviewTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.isLoading.value && c.overview.value == null) {
        return const Center(child: CircularProgressIndicator(color: kPrimary));
      }

      final month = Map<String, dynamic>.from(
        c.overview.value?['thisMonth'] ?? {},
      );
      final counts = Map<String, dynamic>.from(
        c.overview.value?['counts'] ?? {},
      );
      final profile = c.profile.value;

      return RefreshIndicator(
        color: kPrimary,
        onRefresh: c.loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _UseToggle(c: c),
            const SizedBox(height: 12),
            if (!c.configured.value)
              const _WarnCard(
                title: 'Tax is not configured',
                body:
                    'Apply a country pack in Setup so POS, sales, purchases and inventory share one tax engine.',
              )
            else if (!c.enabled.value)
              const _WarnCard(
                title: 'Taxation is turned off',
                body:
                    'Rates stay saved, but documents will not add tax until you switch it on.',
              ),
            if (profile != null) ...[
              const SizedBox(height: 12),
              _sectionTitle('Profile'),
              const SizedBox(height: 8),
              _kpiGrid(context, [
                _Kpi('Regime', profile['regime']?.toString() ?? '—', Icons.gavel_outlined, kPrimary),
                _Kpi(
                  'Pricing',
                  profile['pricingModel'] == 'inclusive'
                      ? 'Inclusive'
                      : 'Exclusive',
                  Icons.sell_outlined,
                  const Color(0xFF0891B2),
                ),
                _Kpi('Country', profile['countryCode']?.toString() ?? '—', Icons.public, const Color(0xFF22A869)),
                _Kpi('Filing', profile['filingFrequency']?.toString() ?? '—', Icons.event_outlined, const Color(0xFF7C3AED)),
              ]),
            ],
            const SizedBox(height: 16),
            _sectionTitle('This month'),
            const SizedBox(height: 8),
            _kpiGrid(context, [
              _Kpi('Tax collected', '${month['taxAmount'] ?? 0}', Icons.payments_outlined, kPrimary),
              _Kpi('Taxable amount', '${month['taxableAmount'] ?? 0}', Icons.receipt_long_outlined, const Color(0xFF22A869)),
              _Kpi('Exemptions', '${month['exemptionAmount'] ?? 0}', Icons.verified_outlined, const Color(0xFFF59E0B)),
              _Kpi('Documents', '${month['transactions'] ?? 0}', Icons.description_outlined, const Color(0xFF0891B2)),
            ]),
            const SizedBox(height: 16),
            _sectionTitle('Catalogue'),
            const SizedBox(height: 8),
            _kpiGrid(context, [
              _Kpi('Rates', '${counts['taxRates'] ?? c.rates.length}', Icons.percent, kPrimary),
              _Kpi('Types', '${counts['taxTypes'] ?? c.types.length}', Icons.category_outlined, const Color(0xFF7C3AED)),
              _Kpi('Jurisdictions', '${counts['jurisdictions'] ?? c.jurisdictions.length}', Icons.map_outlined, const Color(0xFF0891B2)),
              _Kpi('Exemptions', '${counts['exemptions'] ?? c.exemptions.length}', Icons.shield_outlined, const Color(0xFF22A869)),
            ]),
            const SizedBox(height: 16),
            _sectionTitle('Active rates'),
            const SizedBox(height: 8),
            if (c.rates.isEmpty)
              const _EmptyHint('No rates yet. Apply a country pack in Setup.')
            else
              ...c.rates.map((r) => _RateTile(c: c, rate: r)),
          ],
        ),
      );
    });
  }
}

class _SetupTab extends StatelessWidget {
  final TaxController c;
  const _SetupTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final packs = c.countryPacks;
      final codes = packs
          .map((p) => p['countryCode']?.toString())
          .whereType<String>()
          .toList();
      final countryValue = codes.contains(c.selectedCountry.value)
          ? c.selectedCountry.value
          : (codes.isEmpty ? null : codes.first);

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _UseToggle(c: c),
          const SizedBox(height: 12),
          _CardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Country pack',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Load VAT / GST / sales-tax rates as a starting point. You can edit them afterwards.',
                  style: TextStyle(color: _kTextSub, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: countryValue,
                  isExpanded: true,
                  decoration: _fieldDec('Country'),
                  items: packs
                      .map(
                        (p) => DropdownMenuItem(
                          value: p['countryCode']?.toString(),
                          child: Text(
                            '${p['name']} · ${p['regime']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: packs.isEmpty
                      ? null
                      : (v) {
                          if (v != null) c.selectedCountry.value = v;
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: c.registrationCtrl,
                  decoration: _fieldDec('Tax registration number'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: c.pricingModel.value,
                  isExpanded: true,
                  decoration: _fieldDec('Pricing model'),
                  items: const [
                    DropdownMenuItem(value: 'exclusive', child: Text('Tax exclusive')),
                    DropdownMenuItem(value: 'inclusive', child: Text('Tax inclusive')),
                  ],
                  onChanged: (v) {
                    if (v != null) c.pricingModel.value = v;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: const ['VAT', 'GST', 'SALES_TAX', 'SST'].contains(c.regime.value)
                      ? c.regime.value
                      : 'VAT',
                  isExpanded: true,
                  decoration: _fieldDec('Regime'),
                  items: const [
                    DropdownMenuItem(value: 'VAT', child: Text('VAT')),
                    DropdownMenuItem(value: 'GST', child: Text('GST')),
                    DropdownMenuItem(value: 'SALES_TAX', child: Text('Sales tax')),
                    DropdownMenuItem(value: 'SST', child: Text('SST')),
                  ],
                  onChanged: (v) {
                    if (v != null) c.regime.value = v;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: const ['monthly', 'quarterly', 'annually']
                          .contains(c.filingFrequency.value)
                      ? c.filingFrequency.value
                      : 'quarterly',
                  isExpanded: true,
                  decoration: _fieldDec('Filing frequency'),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                    DropdownMenuItem(value: 'annually', child: Text('Annually')),
                  ],
                  onChanged: (v) {
                    if (v != null) c.filingFrequency.value = v;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: c.isLoading.value ? null : () => c.applyCountryPack(),
                    child: const Text('Apply country pack'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimary,
                      side: const BorderSide(color: kPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: c.isLoading.value ? null : c.saveProfile,
                    child: const Text('Save profile'),
                  ),
                ),
                TextButton(
                  onPressed: c.isLoading.value
                      ? null
                      : () => c.applyCountryPack(replace: true),
                  child: const Text('Replace existing rates with this pack'),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _RatesTab extends StatelessWidget {
  final TaxController c;
  const _RatesTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const Text(
            'These rates drive POS, sales invoices, purchase bills and inventory — not hardcoded percentages.',
            style: TextStyle(color: _kTextSub, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chipBtn('Add type', Icons.add, () => _addType(context, c)),
              _chipBtn('Add jurisdiction', Icons.public, () => _addJurisdiction(context, c)),
              _chipBtn('Add rate', Icons.percent, () => _addRate(context, c), filled: true),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Rates'),
          const SizedBox(height: 8),
          if (c.rates.isEmpty)
            const _EmptyHint('No rates yet.')
          else
            ...c.rates.map((r) => _RateTile(c: c, rate: r, showDefaultAction: true)),
          const SizedBox(height: 16),
          _sectionTitle('Types'),
          const SizedBox(height: 8),
          if (c.types.isEmpty)
            const _EmptyHint('No tax types yet.')
          else
            ...c.types.map(
              (t) => _InfoTile(
                title: '${t['code']} — ${t['name']}',
                subtitle: t['isCompound'] == true ? 'Compound' : 'Standard',
              ),
            ),
          const SizedBox(height: 16),
          _sectionTitle('Jurisdictions'),
          const SizedBox(height: 8),
          if (c.jurisdictions.isEmpty)
            const _EmptyHint('No jurisdictions yet.')
          else
            ...c.jurisdictions.map(
              (j) => _InfoTile(
                title: '${j['code']} — ${j['name']}',
                subtitle: '${j['level'] ?? ''} ${j['countryCode'] ?? ''}'.trim(),
              ),
            ),
        ],
      );
    });
  }

  Future<void> _addType(BuildContext context, TaxController c) async {
    final code = TextEditingController();
    final name = TextEditingController();
    final ok = await _formDialog(
      context,
      dialogContext: context,
      title: 'Add tax type',
      fields: [
        TextField(controller: code, decoration: _fieldDec('Code (VAT_STD)')),
        const SizedBox(height: 12),
        TextField(controller: name, decoration: _fieldDec('Name')),
      ],
    );
    if (ok == true && code.text.isNotEmpty && name.text.isNotEmpty) {
      await c.addType(code.text.trim(), name.text.trim());
    }
  }

  Future<void> _addJurisdiction(BuildContext context, TaxController c) async {
    final code = TextEditingController(text: c.selectedCountry.value);
    final name = TextEditingController();
    final ok = await _formDialog(
      context,
      dialogContext: context,
      title: 'Add jurisdiction',
      fields: [
        TextField(controller: code, decoration: _fieldDec('Code')),
        const SizedBox(height: 12),
        TextField(controller: name, decoration: _fieldDec('Name')),
      ],
    );
    if (ok == true && code.text.isNotEmpty && name.text.isNotEmpty) {
      await c.addJurisdiction(code.text.trim(), name.text.trim(), c.selectedCountry.value);
    }
  }

  Future<void> _addRate(BuildContext context, TaxController c) async {
    if (c.jurisdictions.isEmpty || c.types.isEmpty) {
      Get.snackbar(
        'Missing setup',
        'Add a jurisdiction and tax type first, or apply a country pack.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    String? jurisdictionId = c.jurisdictions.first['id']?.toString();
    String? taxTypeId = c.types.first['id']?.toString();
    final rateCtrl = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add tax rate', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: jurisdictionId,
                isExpanded: true,
                decoration: _fieldDec('Jurisdiction'),
                items: c.jurisdictions
                    .map(
                      (j) => DropdownMenuItem(
                        value: j['id']?.toString(),
                        child: Text(j['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => jurisdictionId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: taxTypeId,
                isExpanded: true,
                decoration: _fieldDec('Tax type'),
                items: c.types
                    .map(
                      (t) => DropdownMenuItem(
                        value: t['id']?.toString(),
                        child: Text(t['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => taxTypeId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _fieldDec('Rate %'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kPrimary),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && jurisdictionId != null && taxTypeId != null) {
      await c.addRate(
        jurisdictionId: jurisdictionId!,
        taxTypeId: taxTypeId!,
        rate: double.tryParse(rateCtrl.text) ?? 0,
      );
    }
  }
}

class _ExemptionsTab extends StatelessWidget {
  final TaxController c;
  const _ExemptionsTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const Text(
            'Resale certificates, exports, charities and diplomatic relief. Applied when the customer matches.',
            style: TextStyle(color: _kTextSub, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chipBtn('Add type', Icons.add, () => _addType(context, c)),
              _chipBtn('Grant exemption', Icons.verified_outlined, () => _grant(context, c), filled: true),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Types'),
          const SizedBox(height: 8),
          if (c.exemptionTypes.isEmpty)
            const _EmptyHint('No exemption types yet.')
          else
            ...c.exemptionTypes.map(
              (t) => _InfoTile(
                title: '${t['code']} — ${t['name']}',
                subtitle: '${t['percentage'] ?? 100}% relief',
              ),
            ),
          const SizedBox(height: 16),
          _sectionTitle('Granted'),
          const SizedBox(height: 8),
          if (c.exemptions.isEmpty)
            const _EmptyHint('None yet.')
          else
            ...c.exemptions.map(
              (e) => _InfoTile(
                title: e['exemptionType']?['name']?.toString() ?? 'Exemption',
                subtitle:
                    '${e['customer']?['name'] ?? e['product']?['name'] ?? e['customerId'] ?? '—'}'
                    '${e['certificateNumber'] != null ? ' · ${e['certificateNumber']}' : ''}',
              ),
            ),
        ],
      );
    });
  }

  Future<void> _addType(BuildContext context, TaxController c) async {
    final code = TextEditingController();
    final name = TextEditingController();
    final ok = await _formDialog(
      context,
      dialogContext: context,
      title: 'Exemption type',
      fields: [
        TextField(controller: code, decoration: _fieldDec('Code')),
        const SizedBox(height: 12),
        TextField(controller: name, decoration: _fieldDec('Name')),
      ],
    );
    if (ok == true && code.text.isNotEmpty && name.text.isNotEmpty) {
      await c.addExemptionType(code.text.trim(), name.text.trim());
    }
  }

  Future<void> _grant(BuildContext context, TaxController c) async {
    if (c.exemptionTypes.isEmpty) {
      Get.snackbar(
        'Missing setup',
        'Add an exemption type first.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    String? typeId = c.exemptionTypes.first['id']?.toString();
    final customer = TextEditingController();
    final cert = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Grant exemption', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: typeId,
                isExpanded: true,
                decoration: _fieldDec('Type'),
                items: c.exemptionTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t['id']?.toString(),
                        child: Text(t['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => typeId = v),
              ),
              const SizedBox(height: 12),
              TextField(controller: customer, decoration: _fieldDec('Customer ID')),
              const SizedBox(height: 12),
              TextField(controller: cert, decoration: _fieldDec('Certificate #')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kPrimary),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Grant'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && typeId != null && customer.text.isNotEmpty) {
      await c.grantExemption(
        typeId: typeId!,
        customerId: customer.text.trim(),
        cert: cert.text.trim(),
      );
    }
  }
}

class _ReportsTab extends StatefulWidget {
  final TaxController c;
  const _ReportsTab({required this.c});

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  late DateTime from;
  late DateTime to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    from = DateTime(now.year, now.month, 1);
    to = now;
    widget.c.loadLiability(_iso(from), _iso(to));
  }

  String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Obx(() {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const Text(
            'Output VAT/GST collected in this period — ready for filing.',
            style: TextStyle(color: _kTextSub, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _dateChip(
                'From ${_iso(from)}',
                () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: from,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => from = d);
                },
              ),
              _dateChip(
                'To ${_iso(to)}',
                () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: to,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => to = d);
                },
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => c.loadLiability(_iso(from), _iso(to)),
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (c.liability.isEmpty)
            const _EmptyHint('No tax transactions in this period.')
          else
            ...c.liability.map(
              (row) => _InfoTile(
                title: '${row['taxType'] ?? 'Tax'} · ${row['jurisdiction'] ?? ''}',
                subtitle: 'Taxable ${row['taxableAmount'] ?? 0} · Docs ${row['transactionCount'] ?? 0}',
                trailing: Text(
                  '${row['taxAmount'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: kPrimary),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _dateChip(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kTextPrimary,
        side: const BorderSide(color: _kCardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }
}

class _UseToggle extends StatelessWidget {
  final TaxController c;
  const _UseToggle({required this.c});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Use taxation in this company',
          style: TextStyle(fontWeight: FontWeight.w800, color: _kTextPrimary),
        ),
        subtitle: Text(
          c.enabled.value
              ? 'ON — tax applies in POS, sales, purchases and accounting'
              : 'OFF — no tax is calculated in any flow',
          style: const TextStyle(color: _kTextSub, fontSize: 12),
        ),
        value: c.enabled.value,
        activeThumbColor: kPrimary,
        onChanged: c.setEnabled,
      ),
    );
  }
}

class _WarnCard extends StatelessWidget {
  final String title;
  final String body;
  const _WarnCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5E0B0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: _kTextPrimary)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: Color(0xFF8A6A2A), fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

class _Kpi {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Kpi(this.label, this.value, this.icon, this.color);
}

Widget _kpiGrid(BuildContext context, List<_Kpi> items) {
  final w = MediaQuery.of(context).size.width;
  final cols = w >= 720 ? 4 : 2;
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: cols,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: cols == 4 ? 1.6 : 1.35,
    children: items
        .map(
          (k) => _CardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(k.icon, size: 18, color: k.color),
                const Spacer(),
                Text(
                  k.label,
                  style: const TextStyle(fontSize: 11, color: _kTextSub, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  k.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _kTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class _RateTile extends StatelessWidget {
  final TaxController c;
  final Map<String, dynamic> rate;
  final bool showDefaultAction;
  const _RateTile({required this.c, required this.rate, this.showDefaultAction = false});

  @override
  Widget build(BuildContext context) {
    final isDefault = rate['isDefault'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _CardShell(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.percent, color: kPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.rateLabel(rate),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: _kTextPrimary),
                  ),
                  Text(
                    rate['jurisdictionName']?.toString() ??
                        rate['jurisdiction']?['name']?.toString() ??
                        '',
                    style: const TextStyle(fontSize: 12, color: _kTextSub),
                  ),
                ],
              ),
            ),
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF22A869),
                  ),
                ),
              )
            else if (showDefaultAction)
              TextButton(
                onPressed: () => c.makeDefault(rate['id'].toString()),
                child: const Text('Make default'),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  const _InfoTile({required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _CardShell(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: _kTextPrimary)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: _kTextSub)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      child: child,
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(color: _kTextSub, fontSize: 13)),
    );
  }
}

Widget _sectionTitle(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 15,
      color: _kTextPrimary,
    ),
  );
}

Widget _chipBtn(String label, IconData icon, VoidCallback onTap, {bool filled = false}) {
  if (filled) {
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
  return OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: kPrimary,
      side: const BorderSide(color: kPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    icon: Icon(icon, size: 16),
    label: Text(label),
  );
}

Future<bool?> _formDialog(BuildContext context, {
  required BuildContext dialogContext,
  required String title,
  required List<Widget> fields,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: fields),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kPrimary),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
