import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final CurrencyController _currencyController = Get.find<CurrencyController>();
  final TextEditingController _searchController = TextEditingController();
  final CurrencyService _currencyService = CurrencyService();

  static const List<String> _favoriteCodes = [
    'USD',
    'EUR',
    'GBP',
    'PKR',
    'SAR',
    'AED',
  ];

  late final List<Currency> _allCurrencies;
  late final List<Currency> _favoriteCurrencies;
  List<Currency> _filteredCurrencies = [];

  @override
  void initState() {
    super.initState();
    _allCurrencies = _currencyService.getAll();
    _favoriteCurrencies = _currencyService.findCurrenciesByCode(_favoriteCodes);
    _filteredCurrencies = List<Currency>.from(_allCurrencies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCurrencies(String query) {
    final lowerQuery = query.toLowerCase().trim();
    setState(() {
      if (lowerQuery.isEmpty) {
        _filteredCurrencies = List<Currency>.from(_allCurrencies);
      } else {
        _filteredCurrencies = _allCurrencies.where((currency) {
          return currency.name.toLowerCase().contains(lowerQuery) ||
              currency.code.toLowerCase().contains(lowerQuery) ||
              currency.symbol.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  void _onCurrencySelected(Currency currency) async {
    await _currencyController.setCurrency(
      currency.code,
      symbol: currency.symbol,
    );
    AppSnackbar.success(
      Colors.green,
      'Currency Updated',
      'Default currency changed to ${currency.name} (${currency.symbol})',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: isWeb ? _buildWebLayout(context) : _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(isWeb: true),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildCurrencyList()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(isWeb: false),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _buildCurrencyList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({required bool isWeb}) {
    final showBackBtn = Navigator.canPop(context) && !isWeb;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isWeb ? 32 : 16,
        isWeb ? 32 : 16,
        isWeb ? 32 : 16,
        isWeb ? 24 : 16,
      ),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          if (showBackBtn) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Iconify(Mdi.arrow_left, color: kPrimary, size: 24),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kPrimary, kPrimaryDark]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Iconify(
              Mdi.currency_usd,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: isWeb ? 24 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currency Settings',
                  style: TextStyle(
                    fontSize: isWeb ? 28 : 22,
                    fontWeight: FontWeight.w800,
                    color: kText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set your default currency for reports and transactions',
                  style: TextStyle(fontSize: isWeb ? 15 : 14, color: kSubText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _filterCurrencies,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF2D3748),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Search currency',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
      ),
    );
  }

  Widget _buildCurrencyList() {
    final isSearching = _searchController.text.trim().isNotEmpty;

    if (_filteredCurrencies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Iconify(
              Mdi.magnify_close,
              size: 64,
              color: kSubText.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No currencies found',
              style: TextStyle(
                fontSize: 16,
                color: kSubText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (!isSearching && _favoriteCurrencies.isNotEmpty) ...[
          ..._favoriteCurrencies.map(_buildCurrencyRow),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(thickness: 1),
          ),
        ],
        ..._filteredCurrencies.map(_buildCurrencyRow),
      ],
    );
  }

  /// Matches register `showCurrencyPicker` list row:
  /// flag | CODE + name | symbol
  Widget _buildCurrencyRow(Currency currency) {
    return Obx(() {
      final isSelected =
          _currencyController.currencyCode.value == currency.code;

      return Material(
        color: isSelected ? kPrimary.withOpacity(0.05) : Colors.transparent,
        child: InkWell(
          onTap: () => _onCurrencySelected(currency),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(width: 15),
                      _flagWidget(currency),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currency.code,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? kPrimaryDark
                                    : const Color(0xFF2D3748),
                              ),
                            ),
                            Text(
                              currency.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    currency.symbol,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? kPrimary : const Color(0xFF2D3748),
                    ),
                  ),
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Iconify(
                        Mdi.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _flagWidget(Currency currency) {
    try {
      if (currency.flag != null && !currency.isFlagImage) {
        return Text(
          CurrencyUtils.currencyToEmoji(currency),
          style: const TextStyle(fontSize: 26),
        );
      }
    } catch (_) {}

    return Icon(Icons.flag_outlined, size: 24, color: Colors.grey.shade400);
  }
}
