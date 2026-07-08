import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppCurrency {
  final String code;
  final String symbol;
  final String name;

  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  String get displayLabel => '$code — $symbol $name';
}

class CurrencyController extends GetxController {
  static const String prefsCodeKey = 'app_currency_code';
  static const String prefsSymbolKey = 'app_currency_symbol';
  static const String defaultCode = 'USD';

  var currencyCode = defaultCode.obs;
  var currencySymbol = r'$'.obs;

  static const List<AppCurrency> currencies = [
    AppCurrency(code: 'USD', symbol: r'$', name: 'US Dollar'),
    AppCurrency(code: 'EUR', symbol: '€', name: 'Euro'),
    AppCurrency(code: 'GBP', symbol: '£', name: 'British Pound'),
    AppCurrency(code: 'PKR', symbol: 'Rs', name: 'Pakistani Rupee'),
    AppCurrency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    AppCurrency(code: 'AED', symbol: 'AED', name: 'UAE Dirham'),
    AppCurrency(code: 'SAR', symbol: 'SAR', name: 'Saudi Riyal'),
    AppCurrency(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar'),
    AppCurrency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    AppCurrency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    AppCurrency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    AppCurrency(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc'),
    AppCurrency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
    AppCurrency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
    AppCurrency(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
    AppCurrency(code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee'),
    AppCurrency(code: 'NPR', symbol: 'Rs', name: 'Nepalese Rupee'),
    AppCurrency(code: 'QAR', symbol: 'QR', name: 'Qatari Riyal'),
    AppCurrency(code: 'KWD', symbol: 'KD', name: 'Kuwaiti Dinar'),
    AppCurrency(code: 'OMR', symbol: 'OMR', name: 'Omani Rial'),
    AppCurrency(code: 'BHD', symbol: 'BD', name: 'Bahraini Dinar'),
    AppCurrency(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
    AppCurrency(code: 'EGP', symbol: 'E£', name: 'Egyptian Pound'),
    AppCurrency(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
    AppCurrency(code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
    AppCurrency(code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling'),
    AppCurrency(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah'),
    AppCurrency(code: 'THB', symbol: '฿', name: 'Thai Baht'),
    AppCurrency(code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
    AppCurrency(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar'),
    AppCurrency(code: 'SEK', symbol: 'kr', name: 'Swedish Krona'),
    AppCurrency(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone'),
    AppCurrency(code: 'DKK', symbol: 'kr', name: 'Danish Krone'),
    AppCurrency(code: 'PLN', symbol: 'zł', name: 'Polish Zloty'),
    AppCurrency(code: 'RUB', symbol: '₽', name: 'Russian Ruble'),
    AppCurrency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
    AppCurrency(code: 'MXN', symbol: 'MX\$', name: 'Mexican Peso'),
    AppCurrency(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar'),
    AppCurrency(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
  ];

  @override
  void onInit() {
    super.onInit();
    loadFromPrefs();
  }

  AppCurrency? findByCode(String code) {
    for (final currency in currencies) {
      if (currency.code == code) return currency;
    }
    return null;
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(prefsCodeKey);
    if (savedCode != null && savedCode.isNotEmpty) {
      final currency = findByCode(savedCode);
      if (currency != null) {
        currencyCode.value = currency.code;
        currencySymbol.value = currency.symbol;
        return;
      }
    }
    final defaultCurrency = findByCode(defaultCode)!;
    currencyCode.value = defaultCurrency.code;
    currencySymbol.value = defaultCurrency.symbol;
  }

  Future<void> setCurrency(String code) async {
    final currency = findByCode(code);
    if (currency == null) return;

    currencyCode.value = currency.code;
    currencySymbol.value = currency.symbol;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsCodeKey, currency.code);
    await prefs.setString(prefsSymbolKey, currency.symbol);
    update();
  }

  String formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '${currencySymbol.value} ${formatter.format(amount)}';
  }

  String formatAmountCompact(double amount) {
    if (amount.abs() >= 10000000) {
      return '${currencySymbol.value} ${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
    if (amount.abs() >= 100000) {
      return '${currencySymbol.value} ${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount.abs() >= 1000) {
      return '${currencySymbol.value} ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '${currencySymbol.value} ${amount.toStringAsFixed(0)}';
  }

  String get prefixText => '${currencySymbol.value} ';
}
