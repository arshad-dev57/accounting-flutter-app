import 'package:get/get.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';

class CurrencyUtils {
  static CurrencyController get _ctrl => Get.find<CurrencyController>();

  static String format(double amount) => _ctrl.formatAmount(amount);

  static String formatCompact(double amount) => _ctrl.formatAmountCompact(amount);

  static String get prefix => _ctrl.prefixText;

  static String get symbol => _ctrl.currencySymbol.value;

  static String get code => _ctrl.currencyCode.value;
}
