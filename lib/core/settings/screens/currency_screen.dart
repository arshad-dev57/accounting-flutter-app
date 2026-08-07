import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
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

  List<AppCurrency> _filteredCurrencies = [];

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = CurrencyController.currencies;
  }

  void _filterCurrencies(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredCurrencies = CurrencyController.currencies.where((currency) {
        return currency.name.toLowerCase().contains(lowerQuery) ||
            currency.code.toLowerCase().contains(lowerQuery) ||
            currency.symbol.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  void _onCurrencySelected(AppCurrency currency) async {
    await _currencyController.setCurrency(currency.code);
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
    // Determine if we should show a back button based on whether we are on a screen with a drawer/sidebar or popped onto the stack
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
      style: TextStyle(fontSize: 15, color: kText, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Search by currency name, code, or symbol...',
        hintStyle: TextStyle(color: kSubText.withOpacity(0.7)),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Iconify(Mdi.magnify, color: kSubText, size: 20),
        ),
        filled: true,
        fillColor: kBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCurrencyList() {
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredCurrencies.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, thickness: 1, color: kBorder),
      itemBuilder: (context, index) {
        final currency = _filteredCurrencies[index];
        return Obx(() {
          final isSelected =
              _currencyController.currencyCode.value == currency.code;

          return Material(
            color: isSelected ? kPrimary.withOpacity(0.05) : Colors.transparent,
            child: InkWell(
              onTap: () => _onCurrencySelected(currency),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimary.withOpacity(0.15) : kBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? kPrimary : kBorder,
                        ),
                      ),
                      child: Text(
                        currency.symbol,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? kPrimary : kText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currency.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected ? kPrimaryDark : kText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currency.code,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: kSubText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
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
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
}
