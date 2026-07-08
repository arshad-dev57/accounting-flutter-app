import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:flutter/material.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final List<Map<String, dynamic>> _items = [];
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  String _taxType = 'Tax exclusive';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ════════════════════════════════════════════
  //  APP BAR
  // ════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: kText),
        onPressed: () => Navigator.pop(context),
      ),
      title:Text(
        'Quote',
        style: TextStyle(
          color: kText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: kText),
          onPressed: () {},
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
          // Customer selection
          _buildCustomerSection(),
          const SizedBox(height: 12),
          
          // Date and expiry section
          _buildDateAndExpirySection(),
          const SizedBox(height: 12),
          
          // Tax section
          _buildTaxSection(),
          const SizedBox(height: 12),
          
          // Items section
          _buildItemsSection(),
          const SizedBox(height: 12),
          
          // Total section
          _buildTotalSection(),
          const SizedBox(height: 12),
          
          // Attach files button
          _buildAttachFilesButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  CUSTOMER SECTION
  // ════════════════════════════════════════════
  Widget _buildCustomerSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Text(
            'Who is it for?',
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
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search or select a customer',
                hintStyle: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: kSubText, size: 20),
                suffixIcon: Icon(Icons.arrow_drop_down, color: kSubText),
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
  //  DATE AND EXPIRY SECTION
  // ════════════════════════════════════════════
  Widget _buildDateAndExpirySection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, isExpiry: false),
                  child: _buildInfoRow(
                    label: 'Dated today',
                    value: _formatDate(_selectedDate),
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: kBorder,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, isExpiry: true),
                  child: _buildInfoRow(
                    label: 'When does it expire?',
                    value: _formatDate(_expiryDate),
                    icon: Icons.event_outlined,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  TAX SECTION
  // ════════════════════════════════════════════
  Widget _buildTaxSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _showTaxTypeDialog,
        child: _buildInfoRow(
          label: 'Tax reculsive',
          value: _taxType,
          icon: Icons.receipt_outlined,
          showIcon: false,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    IconData? icon,
    bool showIcon = true,
  }) {
    return Row(
      children: [
        if (showIcon && icon != null) ...[
          Icon(icon, size: 18, color: kSubText),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: kSubText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style:  TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kText,
                ),
              ),
            ],
          ),
        ),
        if (!showIcon)
          Icon(Icons.arrow_drop_down, color: kSubText),
      ],
    );
  }

  // ════════════════════════════════════════════
  //  ITEMS SECTION
  // ════════════════════════════════════════════
  Widget _buildItemsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Text(
            'Items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          
          // Items list
          if (_items.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                border: Border.all(color: kBorder, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: kSubText.withOpacity(0.3)),
                    const SizedBox(height: 8),
                    Text(
                      'No items added',
                      style: TextStyle(color: kSubText, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) =>  Divider(color: kBorder),
              itemBuilder: (context, index) {
                return _buildItemTile(_items[index], index);
              },
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Add item button
          OutlinedButton.icon(
            onPressed: _showAddItemDialog,
            icon: Icon(Icons.add, size: 18),
            label:Text(
              'ADD AN ITEM',
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
        ],
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style:  TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['quantity']} x ${item['rate']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: kSubText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item['amount']}',
            style:  TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: kSubText),
            onPressed: () {
              setState(() {
                _items.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Item name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: rateController,
                    decoration: InputDecoration(
                      labelText: 'Rate',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: kSubText)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty &&
                  rateController.text.isNotEmpty) {
                final quantity = double.parse(quantityController.text);
                final rate = double.parse(rateController.text);
                final amount = quantity * rate;
                
                setState(() {
                  _items.add({
                    'name': nameController.text,
                    'quantity': quantity.toString(),
                    'rate': '\$${rate.toStringAsFixed(2)}',
                    'amount': '\$${amount.toStringAsFixed(2)}',
                  });
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
            ),
            child:Text('Add'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  TOTAL SECTION
  // ════════════════════════════════════════════
  Widget _buildTotalSection() {
    double total = 0;
    for (var item in _items) {
      final amountStr = item['amount']?.toString().replaceAll('\$', '') ?? '0';
      total += double.tryParse(amountStr) ?? 0;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         Text(
            'Total',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style:  TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  ATTACH FILES BUTTON (BOTTOMSHEET)
  // ════════════════════════════════════════════
  Widget _buildAttachFilesButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: _showAttachFilesBottomSheet,
        icon: Icon(Icons.attach_file, size: 18, color: kPrimary),
        label:Text(
          '+ ATTACH FILES',
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

  void _showAttachFilesBottomSheet() {
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
                'Attach Files',
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
                  // Handle gallery attachment
                },
              ),
              _buildAttachmentOption(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () {
                  Navigator.pop(context);
                  // Handle camera
                },
              ),
              _buildAttachmentOption(
                icon: Icons.insert_drive_file_outlined,
                label: 'Document',
                onTap: () {
                  Navigator.pop(context);
                  // Handle document picker
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
        style:  TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: kText,
        ),
      ),
      onTap: onTap,
    );
  }

  // ════════════════════════════════════════════
  //  BOTTOM BAR
  // ════════════════════════════════════════════
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Save as draft
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: kText,
                  side: BorderSide(color: kBorder, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:Text(
                  'Save as draft',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Email quote
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  HELPER METHODS
  // ════════════════════════════════════════════
  Future<void> _selectDate(BuildContext context, {required bool isExpiry}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isExpiry ? _expiryDate : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  void _showTaxTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:Text('Select Tax Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title:Text('Tax exclusive'),
              onTap: () {
                setState(() => _taxType = 'Tax exclusive');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title:Text('Tax inclusive'),
              onTap: () {
                setState(() => _taxType = 'Tax inclusive');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title:Text('No tax'),
              onTap: () {
                setState(() => _taxType = 'No tax');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getMonth(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
