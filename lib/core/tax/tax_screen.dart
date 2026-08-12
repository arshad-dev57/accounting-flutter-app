import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/tax/tax_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Tax Compliance'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Setup'),
            Tab(text: 'Rates'),
            Tab(text: 'Exemptions'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          Obx(() {
            if (c.isLoading.value && c.overview.value == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _OverviewTab(c: c);
          }),
          Obx(() => _SetupTab(c: c)),
          Obx(() => _RatesTab(c: c)),
          Obx(() => _ExemptionsTab(c: c)),
          _ReportsTab(c: c),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final TaxController c;
  const _OverviewTab({required this.c});

  @override
  Widget build(BuildContext context) {
    final month = Map<String, dynamic>.from(c.overview.value?['thisMonth'] ?? {});
    final counts = Map<String, dynamic>.from(c.overview.value?['counts'] ?? {});
    final profile = c.profile.value;
    return RefreshIndicator(
      onRefresh: c.loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _UseToggle(c: c),
          const SizedBox(height: 12),
          if (!c.configured.value)
            _WarnCard(
              title: 'Tax is not configured',
              body: 'Apply a country pack so POS, sales, purchases and inventory share one tax engine.',
            )
          else if (!c.enabled.value)
            const _WarnCard(
              title: 'Taxation is turned off',
              body: 'Rates stay saved, but POS, invoices, bills and products will not add tax until you switch it on.',
            ),
          if (profile != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _stat('Regime', profile['regime']?.toString() ?? '—'),
                _stat('Pricing', profile['pricingModel'] == 'inclusive' ? 'Tax inclusive' : 'Tax exclusive'),
                _stat('Country', profile['countryCode']?.toString() ?? '—'),
                _stat('Filing', profile['filingFrequency']?.toString() ?? '—'),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _stat('This month tax', '${month['taxAmount'] ?? 0}'),
              _stat('Taxable amount', '${month['taxableAmount'] ?? 0}'),
              _stat('Exemptions', '${month['exemptionAmount'] ?? 0}'),
              _stat('Taxed documents', '${month['transactions'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _stat('Rates', '${counts['taxRates'] ?? c.rates.length}'),
              _stat('Types', '${counts['taxTypes'] ?? c.types.length}'),
              _stat('Jurisdictions', '${counts['jurisdictions'] ?? c.jurisdictions.length}'),
              _stat('Exemptions', '${counts['exemptions'] ?? c.exemptions.length}'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Active rates', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          if (c.rates.isEmpty)
            const Text('No rates yet. Apply a country pack in Setup.'),
          ...c.rates.map(
            (r) => Card(
              child: ListTile(
                title: Text(c.rateLabel(r)),
                subtitle: Text(r['jurisdictionName']?.toString() ?? ''),
                trailing: r['isDefault'] == true
                    ? const Chip(label: Text('Default'), visualDensity: VisualDensity.compact)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupTab extends StatelessWidget {
  final TaxController c;
  const _SetupTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _UseToggle(c: c),
        const SizedBox(height: 8),
        const Text(
          'Pick the country you operate in. We load VAT/GST/sales-tax rates as a starting point — you can edit them afterwards.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Obx(() => DropdownButtonFormField<String>(
              value: c.countryPacks.any((p) => p['countryCode'] == c.selectedCountry.value)
                  ? c.selectedCountry.value
                  : (c.countryPacks.isEmpty ? null : c.countryPacks.first['countryCode']?.toString()),
              decoration: const InputDecoration(labelText: 'Country pack', border: OutlineInputBorder()),
              items: c.countryPacks
                  .map(
                    (p) => DropdownMenuItem(
                      value: p['countryCode']?.toString(),
                      child: Text('${p['name']} · ${p['regime']}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) c.selectedCountry.value = v;
              },
            )),
        const SizedBox(height: 12),
        TextField(
          controller: c.registrationCtrl,
          decoration: const InputDecoration(
            labelText: 'Tax registration number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => DropdownButtonFormField<String>(
              value: c.pricingModel.value,
              decoration: const InputDecoration(labelText: 'Pricing model', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'exclusive', child: Text('Tax exclusive')),
                DropdownMenuItem(value: 'inclusive', child: Text('Tax inclusive')),
              ],
              onChanged: (v) {
                if (v != null) c.pricingModel.value = v;
              },
            )),
        const SizedBox(height: 12),
        Obx(() => DropdownButtonFormField<String>(
              value: c.regime.value,
              decoration: const InputDecoration(labelText: 'Regime', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'VAT', child: Text('VAT')),
                DropdownMenuItem(value: 'GST', child: Text('GST')),
                DropdownMenuItem(value: 'SALES_TAX', child: Text('Sales tax')),
                DropdownMenuItem(value: 'SST', child: Text('SST')),
              ],
              onChanged: (v) {
                if (v != null) c.regime.value = v;
              },
            )),
        const SizedBox(height: 12),
        Obx(() => DropdownButtonFormField<String>(
              value: c.filingFrequency.value,
              decoration: const InputDecoration(labelText: 'Filing frequency', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                DropdownMenuItem(value: 'annually', child: Text('Annually')),
              ],
              onChanged: (v) {
                if (v != null) c.filingFrequency.value = v;
              },
            )),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kPrimary),
          onPressed: c.isLoading.value ? null : () => c.applyCountryPack(),
          child: const Text('Apply country pack'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: c.isLoading.value ? null : c.saveProfile,
          child: const Text('Save profile (inclusive / exclusive)'),
        ),
        TextButton(
          onPressed: c.isLoading.value ? null : () => c.applyCountryPack(replace: true),
          child: const Text('Replace existing rates with this pack'),
        ),
      ],
    );
  }
}

class _RatesTab extends StatelessWidget {
  final TaxController c;
  const _RatesTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'These rates drive POS, sales invoices, purchase bills and inventory tax — not hardcoded percentages.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _addType(context, c),
                child: const Text('Add type'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _addJurisdiction(context, c),
                child: const Text('Add jurisdiction'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kPrimary),
                onPressed: () => _addRate(context, c),
                child: const Text('Add rate'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Rates', style: TextStyle(fontWeight: FontWeight.w700)),
        if (c.rates.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No rates yet.')),
        ...c.rates.map(
          (r) => Card(
            child: ListTile(
              title: Text(c.rateLabel(r)),
              subtitle: Text(r['jurisdictionName']?.toString() ?? r['jurisdiction']?['name']?.toString() ?? ''),
              trailing: r['isDefault'] == true
                  ? const Chip(label: Text('Default'), visualDensity: VisualDensity.compact)
                  : TextButton(
                      onPressed: () => c.makeDefault(r['id'].toString()),
                      child: const Text('Make default'),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Types', style: TextStyle(fontWeight: FontWeight.w700)),
        ...c.types.map(
          (t) => ListTile(
            dense: true,
            title: Text('${t['code']} — ${t['name']}'),
            subtitle: Text(t['isCompound'] == true ? 'Compound' : 'Standard'),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Jurisdictions', style: TextStyle(fontWeight: FontWeight.w700)),
        ...c.jurisdictions.map(
          (j) => ListTile(
            dense: true,
            title: Text('${j['code']} — ${j['name']}'),
            subtitle: Text('${j['level'] ?? ''} ${j['countryCode'] ?? ''}'),
          ),
        ),
      ],
    );
  }

  Future<void> _addType(BuildContext context, TaxController c) async {
    final code = TextEditingController();
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add tax type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: code, decoration: const InputDecoration(labelText: 'Code (VAT_STD)')),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && code.text.isNotEmpty && name.text.isNotEmpty) {
      await c.addType(code.text.trim(), name.text.trim());
    }
  }

  Future<void> _addJurisdiction(BuildContext context, TaxController c) async {
    final code = TextEditingController(text: c.selectedCountry.value);
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add jurisdiction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: code, decoration: const InputDecoration(labelText: 'Code')),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && code.text.isNotEmpty && name.text.isNotEmpty) {
      await c.addJurisdiction(code.text.trim(), name.text.trim(), c.selectedCountry.value);
    }
  }

  Future<void> _addRate(BuildContext context, TaxController c) async {
    String? jurisdictionId = c.jurisdictions.isNotEmpty ? c.jurisdictions.first['id']?.toString() : null;
    String? taxTypeId = c.types.isNotEmpty ? c.types.first['id']?.toString() : null;
    final rateCtrl = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add tax rate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: jurisdictionId,
                decoration: const InputDecoration(labelText: 'Jurisdiction'),
                items: c.jurisdictions
                    .map((j) => DropdownMenuItem(value: j['id']?.toString(), child: Text(j['name']?.toString() ?? '')))
                    .toList(),
                onChanged: (v) => setState(() => jurisdictionId = v),
              ),
              DropdownButtonFormField<String>(
                value: taxTypeId,
                decoration: const InputDecoration(labelText: 'Tax type'),
                items: c.types
                    .map((t) => DropdownMenuItem(value: t['id']?.toString(), child: Text(t['name']?.toString() ?? '')))
                    .toList(),
                onChanged: (v) => setState(() => taxTypeId = v),
              ),
              TextField(
                controller: rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Rate %'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Resale certificates, exports, charities and diplomatic relief. Applied automatically on POS and invoices when the customer matches.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _addType(context, c),
                child: const Text('Add exemption type'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kPrimary),
                onPressed: () => _grant(context, c),
                child: const Text('Grant exemption'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Types', style: TextStyle(fontWeight: FontWeight.w700)),
        ...c.exemptionTypes.map(
          (t) => ListTile(
            dense: true,
            title: Text('${t['code']} — ${t['name']}'),
            trailing: Text('${t['percentage'] ?? 100}%'),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Granted', style: TextStyle(fontWeight: FontWeight.w700)),
        if (c.exemptions.isEmpty) const Text('None yet.'),
        ...c.exemptions.map(
          (e) => Card(
            child: ListTile(
              title: Text(e['exemptionType']?['name']?.toString() ?? 'Exemption'),
              subtitle: Text(
                '${e['customer']?['name'] ?? e['product']?['name'] ?? e['customerId'] ?? '—'}'
                '${e['certificateNumber'] != null ? ' · ${e['certificateNumber']}' : ''}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addType(BuildContext context, TaxController c) async {
    final code = TextEditingController();
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exemption type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: code, decoration: const InputDecoration(labelText: 'Code')),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && code.text.isNotEmpty && name.text.isNotEmpty) {
      await c.addExemptionType(code.text.trim(), name.text.trim());
    }
  }

  Future<void> _grant(BuildContext context, TaxController c) async {
    String? typeId = c.exemptionTypes.isNotEmpty ? c.exemptionTypes.first['id']?.toString() : null;
    final customer = TextEditingController();
    final cert = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Grant exemption'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: typeId,
                decoration: const InputDecoration(labelText: 'Type'),
                items: c.exemptionTypes
                    .map((t) => DropdownMenuItem(value: t['id']?.toString(), child: Text(t['name']?.toString() ?? '')))
                    .toList(),
                onChanged: (v) => setState(() => typeId = v),
              ),
              TextField(controller: customer, decoration: const InputDecoration(labelText: 'Customer ID')),
              TextField(controller: cert, decoration: const InputDecoration(labelText: 'Certificate #')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Grant')),
          ],
        ),
      ),
    );
    if (ok == true && typeId != null && customer.text.isNotEmpty) {
      await c.grantExemption(typeId: typeId!, customerId: customer.text.trim(), cert: cert.text.trim());
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
    return Obx(() => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Output VAT/GST collected vs period — ready for filing packs.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: from,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => from = d);
                },
                child: Text('From ${_iso(from)}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: to,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => to = d);
                },
                child: Text('To ${_iso(to)}'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kPrimary),
              onPressed: () => c.loadLiability(_iso(from), _iso(to)),
              child: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (c.liability.isEmpty) const Text('No tax transactions in this period.'),
        ...c.liability.map(
          (row) => Card(
            child: ListTile(
              title: Text('${row['taxType'] ?? 'Tax'} · ${row['jurisdiction'] ?? ''}'),
              subtitle: Text('Taxable ${row['taxableAmount'] ?? 0} · Docs ${row['transactionCount'] ?? 0}'),
              trailing: Text(
                '${row['taxAmount'] ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: kPrimary),
              ),
            ),
          ),
        ),
      ],
    ));
  }
}

class _UseToggle extends StatelessWidget {
  final TaxController c;
  const _UseToggle({required this.c});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: const Text('Use taxation in this company', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          c.enabled.value
              ? 'ON — tax applies in POS, sales, purchases, inventory and accounting'
              : 'OFF — no tax is calculated or shown in any flow',
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
    return Card(
      color: const Color(0xFFFFF8E1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(body),
          ],
        ),
      ),
    );
  }
}

Widget _stat(String label, String value) {
  return SizedBox(
    width: 150,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
      ),
    ),
  );
}
