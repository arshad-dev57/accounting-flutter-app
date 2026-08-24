import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/dashboard/Screens/dashbaord_screen.dart';
import 'package:BisonsTechs_app/core/tax/tax_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _whereController = TextEditingController();
  final TextEditingController _whatController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  DateTime _spentDate = DateTime.now();
  String? _selectedPaymentMethod;
  Map<String, dynamic>? _selectedCategory;

  // Tax related variables
  late TabController _tabController;
  String _selectedTaxTab = 'Inclusive';
  String? _selectedTaxRate;
  bool _isTaxExempt = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Cash', 'icon': Icons.money},
    {'name': 'Credit Card', 'icon': Icons.credit_card},
    {'name': 'Debit Card', 'icon': Icons.credit_card},
    {'name': 'Bank Transfer', 'icon': Icons.account_balance},
    {'name': 'Check', 'icon': Icons.receipt},
    {'name': 'Mobile Payment', 'icon': Icons.phone_android},
    {'name': 'PayPal', 'icon': Icons.payment},
  ];

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Cost of Goods Sold',
      'code': 'COGS-500',
      'icon': Icons.inventory,
      'color': Colors.blue,
    },
    {
      'name': 'Advertising',
      'code': 'ADV-400',
      'icon': Icons.campaign,
      'color': Colors.purple,
    },
    {
      'name': 'Bank Fees',
      'code': 'BNK-200',
      'icon': Icons.account_balance,
      'color': Colors.red,
    },
    {
      'name': 'Office Supplies',
      'code': 'OFC-600',
      'icon': Icons.business_center,
      'color': Colors.orange,
    },
    {
      'name': 'Travel Expenses',
      'code': 'TRV-700',
      'icon': Icons.flight,
      'color': Colors.teal,
    },
    {
      'name': 'Utilities',
      'code': 'UTL-800',
      'icon': Icons.electrical_services,
      'color': Colors.brown,
    },
    {
      'name': 'Rent',
      'code': 'RNT-900',
      'icon': Icons.home,
      'color': Colors.indigo,
    },
    {
      'name': 'Insurance',
      'code': 'INS-100',
      'icon': Icons.security,
      'color': Colors.green,
    },
    {
      'name': 'Professional Fees',
      'code': 'PRF-300',
      'icon': Icons.work,
      'color': Colors.cyan,
    },
    {
      'name': 'Meals & Entertainment',
      'code': 'MNL-1000',
      'icon': Icons.restaurant,
      'color': Colors.pink,
    },
  ];

  late final TaxController _tax;

  @override
  void initState() {
    super.initState();
    _tax = ensureTaxController();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _selectedTaxTab = 'Inclusive';
          break;
        case 1:
          _selectedTaxTab = 'Exclusive';
          break;
        case 2:
          _selectedTaxTab = 'No Tax';
          break;
      }
      _selectedTaxRate = null;
      _isTaxExempt = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _whereController.dispose();
    _whatController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ════════════════════════════════════════════
  //  APP BAR WITH SAVE BUTTON
  // ════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: kText),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Receipt',
        style: TextStyle(
          color: kText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _saveReceipt,
          style: TextButton.styleFrom(
            foregroundColor: kPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Text(
            'Save',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════
  //  BODY
  // ════════════════════════════════════════════
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Where was it spent?
          _buildWhereSection(),
          const SizedBox(height: 12),

          // What was it for?
          _buildWhatSection(),
          const SizedBox(height: 12),

          // Spent today
          _buildSpentDateSection(),
          const SizedBox(height: 12),

          // How did you pay?
          _buildPaymentSection(),
          const SizedBox(height: 12),

          // Categorise to an account
          _buildCategorySection(),
          const SizedBox(height: 12),

          // Tax Section with Tabs
          _buildTaxSection(),
          const SizedBox(height: 12),

          // Total
          _buildTotalSection(),
          const SizedBox(height: 12),

          // Attach File
          _buildAttachFileSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  WHERE SECTION
  // ════════════════════════════════════════════
  Widget _buildWhereSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where was it spent?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: TextField(
              controller: _whereController,
              decoration: InputDecoration(
                hintText: 'Store name or location',
                hintStyle: TextStyle(
                  color: kSubText.withOpacity(0.5),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.store_outlined,
                  color: kSubText,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  WHAT SECTION
  // ════════════════════════════════════════════
  Widget _buildWhatSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What was it for?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: TextField(
              controller: _whatController,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'Description of the expense',
                hintStyle: TextStyle(
                  color: kSubText.withOpacity(0.5),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  SPENT DATE SECTION
  // ════════════════════════════════════════════
  Widget _buildSpentDateSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => _selectDate(context),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: kSubText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent today',
                    style: TextStyle(fontSize: 12, color: kSubText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(_spentDate),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: kSubText),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  PAYMENT SECTION
  // ════════════════════════════════════════════
  Widget _buildPaymentSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How did you pay?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showPaymentBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment_outlined, size: 20, color: kSubText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedPaymentMethod ?? 'Select payment method',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedPaymentMethod != null
                            ? kText
                            : kSubText,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: kSubText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Bank Connected',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please connect a bank account to use payment methods',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: kSubText),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance, color: kPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Connect Bank Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ..._paymentMethods.map(
                (method) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(method['icon'], color: kPrimary),
                  ),
                  title: Text(
                    method['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: kText,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method['name'];
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: kSubText, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════
  //  CATEGORY SECTION
  // ════════════════════════════════════════════
  Widget _buildCategorySection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categorise to an account',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showCategoryBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.category_outlined, size: 20, color: kSubText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedCategory != null
                          ? '${_selectedCategory!['code']} - ${_selectedCategory!['name']}'
                          : 'Select a category',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedCategory != null ? kText : kSubText,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: kSubText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: Icon(Icons.search, color: kSubText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return _buildCategoryTile(category);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryTile(Map<String, dynamic> category) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: category['color'].withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(category['icon'], color: category['color']),
      ),
      title: Text(
        category['name'],
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: kText,
        ),
      ),
      subtitle: Text(
        'Code: ${category['code']}',
        style: TextStyle(fontSize: 12, color: kSubText),
      ),
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        Navigator.pop(context);
      },
    );
  }

  // ════════════════════════════════════════════
  //  TAX SECTION WITH TABS
  // ════════════════════════════════════════════
  Widget _buildTaxSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tax inclusive',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: kPrimary,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: kSubText,
              tabs: const [
                Tab(text: 'INCLUSIVE'),
                Tab(text: 'EXCLUSIVE'),
                Tab(text: 'NO TAX'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tax Rate Selection
          GestureDetector(
            onTap: _selectedTaxTab != 'No Tax' ? _showTaxRateBottomSheet : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_outlined, size: 20, color: kSubText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedTaxTab == 'No Tax'
                              ? 'Tax Exempt'
                              : 'Select tax rate',
                          style: TextStyle(fontSize: 12, color: kSubText),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedTaxRate ??
                              (_selectedTaxTab == 'No Tax'
                                  ? 'Tax Exempt'
                                  : 'Choose rate'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedTaxRate != null ? kText : kSubText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedTaxTab != 'No Tax')
                    Icon(Icons.arrow_drop_down, color: kSubText),
                ],
              ),
            ),
          ),

          if (_selectedTaxTab == 'No Tax') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: kSubText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No tax will be applied to this receipt',
                      style: TextStyle(fontSize: 12, color: kSubText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTaxRateBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Tax Rate',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 20),
              if (!_tax.enabled.value)
                ListTile(
                  title: const Text('Taxation is off'),
                  subtitle: const Text('Enable it in Tax Compliance'),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed('/tax');
                  },
                )
              else if (_tax.rates.isEmpty)
                const ListTile(title: Text('No rates yet. Apply a country pack.'))
              else
                ..._tax.rates.map(
                  (rate) => ListTile(
                    title: Text(
                      _tax.rateLabel(rate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: kText,
                      ),
                    ),
                    subtitle: Text(
                      rate['jurisdictionName']?.toString() ?? '',
                      style: TextStyle(fontSize: 12, color: kSubText),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${rate['rate'] ?? 0}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedTaxRate = _tax.rateLabel(rate);
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: kSubText, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════
  //  TOTAL SECTION
  // ════════════════════════════════════════════
  Widget _buildTotalSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixText: CurrencyUtils.prefix,
                  prefixStyle: TextStyle(
                    color: kText,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Total',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _amountController.text.isEmpty ? '0.00' : _amountController.text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  ATTACH FILE SECTION
  // ════════════════════════════════════════════
  Widget _buildAttachFileSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: _showAttachFileBottomSheet,
        icon: Icon(Icons.attach_file, size: 18, color: kPrimary),
        label: Text(
          'ATTACH FILE',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimary,
          side: BorderSide(color: kPrimary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  void _showAttachFileBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Attach File',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 20),
              _buildAttachmentOption(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildAttachmentOption(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildAttachmentOption(
                icon: Icons.insert_drive_file_outlined,
                label: 'Document',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: kSubText, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: kPrimary),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: kText,
        ),
      ),
      onTap: onTap,
    );
  }

  // ════════════════════════════════════════════
  //  HELPER METHODS
  // ════════════════════════════════════════════
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _spentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _spentDate = picked;
      });
    }
  }

  void _saveReceipt() {
    // Validate required fields
    if (_whereController.text.isEmpty) {
      _showErrorSnackBar('Please enter where it was spent');
      return;
    }

    if (_amountController.text.isEmpty) {
      _showErrorSnackBar('Please enter the amount');
      return;
    }

    if (_selectedPaymentMethod == null) {
      _showErrorSnackBar('Please select payment method');
      return;
    }

    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }

    // Here you would typically save the receipt
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Receipt saved successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getMonth(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
