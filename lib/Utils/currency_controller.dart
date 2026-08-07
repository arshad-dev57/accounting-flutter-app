import 'package:BisonsTechs_app/Services/api_client.dart';
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
    print('🟢 [CurrencyController] onInit called');
    loadFromPrefs();
  }

  AppCurrency? findByCode(String code) {
    for (final currency in currencies) {
      if (currency.code == code) return currency;
    }
    return null;
  }

  Future<void> loadFromPrefs() async {
    print('🔄 [CurrencyController] loadFromPrefs called');
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(prefsCodeKey);
    final savedSymbol = prefs.getString(prefsSymbolKey);

    print('📦 [CurrencyController] Saved Code: $savedCode');
    print('📦 [CurrencyController] Saved Symbol: $savedSymbol');

    if (savedCode != null && savedCode.isNotEmpty) {
      final currency = findByCode(savedCode);
      if (currency != null) {
        currencyCode.value = currency.code;
        currencySymbol.value = currency.symbol;
        print(
          '✅ [CurrencyController] Loaded from Prefs: ${currency.code} (${currency.symbol})',
        );
        return;
      }
    }

    final defaultCurrency = findByCode(defaultCode)!;
    currencyCode.value = defaultCurrency.code;
    currencySymbol.value = defaultCurrency.symbol;
    print(
      '✅ [CurrencyController] Using Default: ${defaultCurrency.code} (${defaultCurrency.symbol})',
    );
  }

  Future<void> updateFromUserData(Map<String, dynamic>? userData) async {
    print('🔄 [CurrencyController] updateFromUserData called');
    print('📦 [CurrencyController] User Data: $userData');

    if (userData == null) {
      print('⚠️ [CurrencyController] User data is null');
      return;
    }

    final businessDetails =
        userData['businessDetails'] as Map<String, dynamic>?;
    print('📦 [CurrencyController] Business Details: $businessDetails');

    if (businessDetails == null) {
      print('⚠️ [CurrencyController] Business details is null');
      return;
    }

    final code = businessDetails['currencyCode'] as String?;
    final symbol = businessDetails['currencySymbol'] as String?;

    print('📦 [CurrencyController] Currency Code from API: $code');
    print('📦 [CurrencyController] Currency Symbol from API: $symbol');

    if (code != null &&
        code.isNotEmpty &&
        symbol != null &&
        symbol.isNotEmpty) {
      currencyCode.value = code;
      currencySymbol.value = symbol;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsCodeKey, code);
      await prefs.setString(prefsSymbolKey, symbol);

      print('✅ [CurrencyController] Updated from User Data: $code ($symbol)');
      update();
    } else {
      print(
        '⚠️ [CurrencyController] No currency found in user data, keeping default',
      );
    }
  }

  Future<void> setCurrency(String code) async {
    print('🔄 [CurrencyController] setCurrency called with: $code');

    final currency = findByCode(code);
    if (currency == null) {
      print('❌ [CurrencyController] Currency not found: $code');
      return;
    }

    print(
      '📦 [CurrencyController] Found Currency: ${currency.code} (${currency.symbol})',
    );

    currencyCode.value = currency.code;
    currencySymbol.value = currency.symbol;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsCodeKey, currency.code);
    await prefs.setString(prefsSymbolKey, currency.symbol);
    update();

    try {
      print('📤 [CurrencyController] Sending to API: /api/users/currency');
      final ApiClient api = Get.find<ApiClient>();

      final response = await api.put(
        '/api/users/currency',
        body: {
          'currencyCode': currency.code,
          'currencySymbol': currency.symbol,
        },
      );

      print(
        '📥 [CurrencyController] API Response Status: ${response.statusCode}',
      );
      print(
        '📥 [CurrencyController] API Response Success: ${response.success}',
      );
      print('📥 [CurrencyController] API Response Data: ${response.data}');

      if (response.success) {
        print(
          '✅ [CurrencyController] Currency synced with server successfully',
        );
      } else {
        print(
          '❌ [CurrencyController] Failed to sync currency with server: ${response.message}',
        );
      }
    } catch (e) {
      print('❌ [CurrencyController] Failed to sync currency with server: $e');
    }
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
