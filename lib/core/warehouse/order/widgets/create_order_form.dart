import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehouse/order/controller/sales_order_controller.dart';
import 'package:LedgerPro_app/core/warehouse/order/model/order_model.dart';
import 'package:LedgerPro_app/core/warehouse/order/widgets/customer_picker_sheet.dart';
import 'package:LedgerPro_app/core/warehouse/order/widgets/product_search_field.dart';
import 'package:LedgerPro_app/core/warehouse/order/widgets/setting_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateOrderForm extends StatefulWidget {
  final SalesOrderController controller;
  final VoidCallback onCancel;


  const CreateOrderForm({
    super.key,
    required this.controller,
    required this.onCancel,
  });

  @override
  State<CreateOrderForm> createState() => _CreateOrderFormState();
}

class _CreateOrderFormState extends State<CreateOrderForm> {
  Map<String, dynamic>? _selectedProduct;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Obx(() {
      return Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.formError.value.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kDanger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDanger.withOpacity(0.2)),
                      ),
                      child: Text(c.formError.value, style: TextStyle(color: kDanger)),
                    ),
                  _section('Customer Information', Icons.person_outline, [
                    _customerPicker(),
                    const SizedBox(height: 12),
                    _textField('Email', c.customerEmail.value,
                        (v) => c.customerEmail.value = v, keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _textField('Phone', c.customerPhone.value, (v) => c.customerPhone.value = v),
                    const SizedBox(height: 12),
                    SettingDropdownField(
                      label: 'Customer Type',
                      category: 'customerType',
                      value: c.customerType.value,
                      options: c.customerTypes,
                      onChanged: (v) => c.customerType.value = v,
                      onManage: () => openSettingsManageSheet(
                          context, c, 'customerType', 'Customer Types'),
                    ),
                    const SizedBox(height: 12),
                    _textField('Company Name', c.customerCompany.value,
                        (v) => c.customerCompany.value = v),
                    const SizedBox(height: 12),
                    _textField('Tax ID / NTN', c.customerTaxId.value,
                        (v) => c.customerTaxId.value = v),
                  ]),
                  _section('Shipping Address', Icons.local_shipping_outlined, [
                    ..._addressFields(c.shippingAddress.value, (addr) {
                      c.shippingAddress.value = addr;
                      if (c.sameAsShipping.value) c.billingAddress.value = addr;
                    }),
                  ]),
                  _section('Billing Address', Icons.receipt_long_outlined, [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: c.sameAsShipping.value,
                      onChanged: (v) => c.toggleSameAsShipping(v ?? true),
                      title: const Text('Same as shipping address'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (!c.sameAsShipping.value)
                      ..._addressFields(c.billingAddress.value, (addr) {
                        c.billingAddress.value = addr;
                      }),
                  ]),
                  _section('Order Items', Icons.inventory_2_outlined, [
                    ProductSearchField(
                      controller: c,
                      onSelected: (product) => setState(() => _selectedProduct = product),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: '1',
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (v) => _quantity = int.tryParse(v) ?? 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _selectedProduct == null
                              ? null
                              : () {
                                  c.addProductToOrder(_selectedProduct!, _quantity);
                                  setState(() {
                                    _selectedProduct = null;
                                    _quantity = 1;
                                  });
                                },
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                          child: const Text('Add Item', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...c.createItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item.productName),
                          subtitle: Text('${item.sku} • Qty ${item.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(c.formatCurrency(item.totalPrice)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: kDanger),
                                onPressed: () => c.removeCreateItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ]),
                  _section('Order Details', Icons.list_alt_outlined, [
                    SettingDropdownField(
                      label: 'Order Type',
                      category: 'orderType',
                      value: c.orderType.value,
                      options: c.orderTypes,
                      onChanged: (v) => c.orderType.value = v,
                      onManage: () =>
                          openSettingsManageSheet(context, c, 'orderType', 'Order Types'),
                    ),
                    const SizedBox(height: 12),
                    SettingDropdownField(
                      label: 'Priority',
                      category: 'priority',
                      value: c.priority.value,
                      options: c.priorities,
                      onChanged: (v) => c.priority.value = v,
                      onManage: () =>
                          openSettingsManageSheet(context, c, 'priority', 'Priorities'),
                    ),
                    const SizedBox(height: 12),
                    SettingDropdownField(
                      label: 'Source',
                      category: 'orderSource',
                      value: c.source.value,
                      options: c.sources,
                      onChanged: (v) => c.source.value = v,
                      onManage: () =>
                          openSettingsManageSheet(context, c, 'orderSource', 'Order Sources'),
                    ),
                    const SizedBox(height: 12),
                    _textField('Sales Person', c.salesPerson.value,
                        (v) => c.salesPerson.value = v),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Expected Delivery Date'),
                      subtitle: Text(
                        c.expectedDeliveryDate.value == null
                            ? 'Not set'
                            : c.formatDate(c.expectedDeliveryDate.value!),
                      ),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) c.expectedDeliveryDate.value = picked;
                      },
                    ),
                  ]),
                  _section('Shipping & Payment', Icons.payments_outlined, [
                    SettingDropdownField(
                      label: 'Shipping Method',
                      category: 'shippingMethod',
                      value: c.shippingMethod.value,
                      options: c.shippingMethods,
                      onChanged: (v) => c.shippingMethod.value = v,
                      onManage: () => openSettingsManageSheet(
                          context, c, 'shippingMethod', 'Shipping Methods'),
                    ),
                    const SizedBox(height: 12),
                    _textField('Shipping Carrier', c.shippingCarrier.value,
                        (v) => c.shippingCarrier.value = v),
                    const SizedBox(height: 12),
                    _textField('Shipping Cost', c.shippingCost.value.toString(),
                        (v) => c.shippingCost.value = double.tryParse(v) ?? 0,
                        keyboard: TextInputType.number),
                    const SizedBox(height: 12),
                    SettingDropdownField(
                      label: 'Payment Method',
                      category: 'paymentMethod',
                      value: c.paymentMethod.value,
                      options: c.paymentMethods,
                      onChanged: (v) => c.paymentMethod.value = v,
                      onManage: () => openSettingsManageSheet(
                          context, c, 'paymentMethod', 'Payment Methods'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: c.paymentStatus.value,
                      decoration: InputDecoration(
                        labelText: 'Payment Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: SalesOrderController.paymentStatusCreateOptions
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) c.paymentStatus.value = v;
                      },
                    ),
                  ]),
                  _section('Discounts', Icons.discount_outlined, [
                    _textField('Coupon Code', c.couponCode.value,
                        (v) => c.couponCode.value = v),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: c.discountType.value,
                      decoration: InputDecoration(
                        labelText: 'Discount Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Percentage', child: Text('Percentage')),
                        DropdownMenuItem(value: 'Fixed', child: Text('Fixed Amount')),
                      ],
                      onChanged: (v) {
                        if (v != null) c.discountType.value = v;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (c.discountType.value == 'Percentage')
                      _textField(
                        'Discount %',
                        c.discountPercentage.value.toString(),
                        (v) => c.discountPercentage.value = double.tryParse(v) ?? 0,
                        keyboard: TextInputType.number,
                      )
                    else
                      _textField(
                        'Discount Amount',
                        c.discountAmount.value.toString(),
                        (v) => c.discountAmount.value = double.tryParse(v) ?? 0,
                        keyboard: TextInputType.number,
                      ),
                  ]),
                  _section('Notes', Icons.note_alt_outlined, [
                    _textField('Customer Notes', c.customerNotes.value,
                        (v) => c.customerNotes.value = v, maxLines: 2),
                    const SizedBox(height: 12),
                    _textField('Internal Notes', c.internalNotes.value,
                        (v) => c.internalNotes.value = v, maxLines: 2),
                    const SizedBox(height: 12),
                    _textField('Tags (comma separated)', c.tagsInput.value,
                        (v) => c.tagsInput.value = v),
                  ]),
                  _section('Summary', Icons.summarize_outlined, [
                    _summaryRow('Subtotal', c.formatCurrency(c.subtotal)),
                    _summaryRow('Shipping', c.formatCurrency(c.shippingCost.value)),
                    _summaryRow('Discount', '- ${c.formatCurrency(c.calculatedDiscount)}'),
                    const Divider(),
                    _summaryRow('Grand Total', c.formatCurrency(c.grandTotal), bold: true),
                  ]),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _footer(),
        ],
      );
    });
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_shopping_cart, color: kPrimary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Create New Order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          IconButton(onPressed: widget.onCancel, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              return ElevatedButton(
                onPressed: widget.controller.isSubmitting.value
                    ? null
                    : () async {
                        final ok = await widget.controller.submitCreateOrder();
                        if (ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order created successfully')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                child: widget.controller.isSubmitting.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Create Order', style: TextStyle(color: Colors.black)),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: kPrimary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _customerPicker() {
    final c = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer Name *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) => CustomerPickerSheet(onSelect: c.applyCustomer),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
              color: kBg,
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: kSubText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.customerName.value.isEmpty
                        ? 'Select customer...'
                        : c.customerName.value,
                    style: TextStyle(
                      color: c.customerName.value.isEmpty ? kSubText : Colors.black87,
                      fontWeight: c.customerName.value.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ),
                if (c.selectedCustomer.value != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => c.applyCustomer(null),
                  ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Or enter customer name manually',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => c.customerName.value = v,
          controller: TextEditingController(text: c.customerName.value)
            ..selection = TextSelection.collapsed(offset: c.customerName.value.length),
        ),
      ],
    );
  }

  List<Widget> _addressFields(
    OrderAddress address,
    ValueChanged<OrderAddress> onChanged,
  ) {
    Widget field(String label, String value, void Function(String) setter) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
          onChanged: (v) {
            setter(v);
            onChanged(address);
          },
        ),
      );
    }

    return [
      field('Street', address.street, (v) => address.street = v),
      field('City', address.city, (v) => address.city = v),
      field('State', address.state, (v) => address.state = v),
      field('Postal Code', address.postalCode, (v) => address.postalCode = v),
      DropdownButtonFormField<String>(
        value: SalesOrderController.countryOptions.contains(address.country)
            ? address.country
            : 'Pakistan',
        decoration: InputDecoration(
          labelText: 'Country',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: SalesOrderController.countryOptions
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            address.country = v;
            onChanged(address);
          }
        },
      ),
    ];
  }

  Widget _textField(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      keyboardType: keyboard,
      maxLines: maxLines,
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      onChanged: onChanged,
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: kSubText)),
          ),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold ? kPrimary : kText)),
        ],
      ),
    );
  }
}
