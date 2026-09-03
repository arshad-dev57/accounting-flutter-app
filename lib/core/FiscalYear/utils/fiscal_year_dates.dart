// core/FiscalYear/utils/fiscal_year_dates.dart
// Period-type date helpers (mirrors Next.js lib/business-options.ts)

class FiscalYearDateRange {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String periodType;

  const FiscalYearDateRange({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.periodType,
  });
}

/// Local calendar date as YYYY-MM-DD (no UTC shift).
String fiscalDateOnly(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime fiscalDateOnlyParse(String iso) {
  final parts = iso.split('-');
  if (parts.length >= 3) {
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
  return DateTime.parse(iso);
}

/// UI period key → backend periodType label.
const Map<String, String> kFiscalPeriodPref = {
  'Calendar': 'January - December',
  'April': 'April - March',
  'July': 'July - June',
  'Custom': 'Custom',
};

FiscalYearDateRange calculateFiscalYearDates(
  String periodPref, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final y = n.year;
  final m = n.month;

  late DateTime start;
  late DateTime end;

  switch (periodPref) {
    case 'July - June':
      if (m >= 7) {
        start = DateTime(y, 7, 1);
        end = DateTime(y + 1, 6, 30);
      } else {
        start = DateTime(y - 1, 7, 1);
        end = DateTime(y, 6, 30);
      }
      break;
    case 'April - March':
      if (m >= 4) {
        start = DateTime(y, 4, 1);
        end = DateTime(y + 1, 3, 31);
      } else {
        start = DateTime(y - 1, 4, 1);
        end = DateTime(y, 3, 31);
      }
      break;
    case 'October - September':
      if (m >= 10) {
        start = DateTime(y, 10, 1);
        end = DateTime(y + 1, 9, 30);
      } else {
        start = DateTime(y - 1, 10, 1);
        end = DateTime(y, 9, 30);
      }
      break;
    case 'January - December':
    case 'Custom':
    default:
      start = DateTime(y, 1, 1);
      end = DateTime(y, 12, 31);
      break;
  }

  final name = start.year == end.year
      ? 'FY ${start.year}'
      : 'FY ${start.year}-${end.year}';

  return FiscalYearDateRange(
    name: name,
    startDate: start,
    endDate: end,
    periodType: periodPref,
  );
}

/// Suggest next non-overlapping range after [existingEndDates].
FiscalYearDateRange suggestNextFiscalRange({
  required String periodKey,
  required List<DateTime> existingEndDates,
}) {
  final pref = kFiscalPeriodPref[periodKey] ?? 'Custom';
  var anchor = DateTime.now();
  if (existingEndDates.isNotEmpty) {
    existingEndDates.sort();
    final maxEnd = existingEndDates.last;
    anchor = maxEnd.add(const Duration(days: 1));
  }

  if (periodKey == 'Custom') {
    final y = anchor.year;
    return FiscalYearDateRange(
      name: 'FY $y',
      startDate: DateTime(y, 1, 1),
      endDate: DateTime(y, 12, 31),
      periodType: 'Custom',
    );
  }

  var calc = calculateFiscalYearDates(pref, now: anchor);
  if (existingEndDates.isNotEmpty) {
    final latestEnd = existingEndDates.reduce(
      (a, b) => a.isAfter(b) ? a : b,
    );
    if (calc.startDate.isBefore(latestEnd) ||
        calc.startDate.isAtSameMomentAs(latestEnd)) {
      final bumped = DateTime(anchor.year + 1, anchor.month, anchor.day);
      calc = calculateFiscalYearDates(pref, now: bumped);
    }
  }

  return FiscalYearDateRange(
    name: calc.name,
    startDate: calc.startDate,
    endDate: calc.endDate,
    periodType: pref,
  );
}

/// Paths that accept fiscalYearId filtering (mirrors Next.js whitelist).
const List<String> kFiscalYearQueryPaths = [
  '/api/balance-sheet',
  '/api/reports/profit-loss',
  '/api/reports/cash-flow',
  '/api/trial-balance',
  '/api/general-ledger',
  '/api/accounts-payable',
  '/api/accounts-receivable',
  '/api/aged-receivables',
  '/api/expenses',
  '/api/income',
  '/api/journal-entries',
  '/api/payments-made',
  '/api/payments-received',
  '/api/credit-notes',
  '/api/fixed-assets',
  '/api/loans',
  '/api/warehouse/invoices',
  '/api/warehouse/purchase-invoices',
  '/api/warehouse/dashboard',
  '/api/dashboard',
  '/api/bills',
  '/api/sales/dashboard',
  '/api/sales/invoices',
  '/api/purchases/dashboard',
  '/api/warehouse/sales/dashboard',
  '/api/warehouse/sales/reports',
  '/api/purchase/dashboard',
  '/api/purchase/reports',
  '/api/purchase/invoices',
];

bool shouldAttachFiscalYear(String endpoint) {
  final path = endpoint.split('?').first;
  return kFiscalYearQueryPaths.any((p) => path.contains(p));
}
