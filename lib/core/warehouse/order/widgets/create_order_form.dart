import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehouse/order/controller/sales_order_controller.dart';
import 'package:LedgerPro_app/core/warehouse/order/model/order_model.dart';
import 'package:LedgerPro_app/core/warehouse/order/widgets/customer_picker_sheet.dart';
import 'package:LedgerPro_app/core/warehouse/order/widgets/product_search_field.dart';
import 'package:LedgerPro_app/core/warehouse/order/widgets/setting_dropdown_field.dart';
import 'package:LedgerPro_app/core/warehousesettings/warehouse_settings_screen.dart' hide kBg;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateOrderForm extends StatelessWidget {
  final SalesOrderController controller;
  final VoidCallback onCancel;

  const CreateOrderForm({
    super.key,
    required this.controller,
    required this.onCancel,
  });

  // Helper method to navigate to Settings screen
  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final screenHeight = MediaQuery.of(context).size.height;

    return Obx(() {
      return Column(
        children: [
          _header(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.formError.value.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kDanger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: kDanger.withOpacity(0.2)),
                      ),
                      child: Text(
                        c.formError.value,
                        style:
                            TextStyle(color: kDanger, fontSize: 12),
                      ),
                    ),

                  _section(
                      'Customer Information', Icons.person_outline, [
                    _customerPicker(context),
                    const SizedBox(height: 10),
                    _textField('Email', c.customerEmail.value,
                        (v) => c.customerEmail.value = v,
                        keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _textField('Phone', c.customerPhone.value,
                        (v) => c.customerPhone.value = v),
                    const SizedBox(height: 10),
                    SettingDropdownField(
                      label: 'Customer Type',
                      category: 'customerType',
                      value: c.customerType.value,
                      options: c.customerTypes,
                      onChanged: (v) => c.customerType.value = v,
                      onManage: () => _navigateToSettings(context),
                    ),
                    const SizedBox(height: 10),
                    _textField('Company Name', c.customerCompany.value,
                        (v) => c.customerCompany.value = v),
                    const SizedBox(height: 10),
                    _textField('Tax ID / NTN', c.customerTaxId.value,
                        (v) => c.customerTaxId.value = v),
                  ]),

                  _section('Shipping Address',
                      Icons.local_shipping_outlined, [
                    ..._addressFields(c.shippingAddress.value, (addr) {
                      c.shippingAddress.value = addr;
                      if (c.sameAsShipping.value)
                        c.billingAddress.value = addr;
                    }),
                  ]),

                  _section('Billing Address',
                      Icons.receipt_long_outlined, [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: c.sameAsShipping.value,
                      onChanged: (v) =>
                          c.toggleSameAsShipping(v ?? true),
                      title: const Text('Same as shipping address',
                          style: TextStyle(fontSize: 13)),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (!c.sameAsShipping.value)
                      ..._addressFields(c.billingAddress.value,
                          (addr) {
                        c.billingAddress.value = addr;
                      }),
                  ]),

                  _buildOrderItemsSection(c, screenHeight, context),

                  _section('Order Details', Icons.list_alt_outlined, [
                    SettingDropdownField(
                      label: 'Order Type',
                      category: 'orderType',
                      value: c.orderType.value,
                      options: c.orderTypes,
                      onChanged: (v) => c.orderType.value = v,
                      onManage: () => _navigateToSettings(context),
                    ),
                    const SizedBox(height: 10),
                    SettingDropdownField(
                      label: 'Priority',
                      category: 'priority',
                      value: c.priority.value,
                      options: c.priorities,
                      onChanged: (v) => c.priority.value = v,
                      onManage: () => _navigateToSettings(context),
                    ),
                    const SizedBox(height: 10),
                    SettingDropdownField(
                      label: 'Source',
                      category: 'orderSource',
                      value: c.source.value,
                      options: c.sources,
                      onChanged: (v) => c.source.value = v,
                      onManage: () => _navigateToSettings(context),
                    ),
                    const SizedBox(height: 10),
                    _textField('Sales Person', c.salesPerson.value,
                        (v) => c.salesPerson.value = v),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Expected Delivery Date',
                          style: TextStyle(fontSize: 13)),
                      subtitle: Text(
                        c.expectedDeliveryDate.value == null
                            ? 'Not set'
                            : c.formatDate(
                                c.expectedDeliveryDate.value!),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                          Icons.calendar_today_outlined,
                          size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now()
                              .add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (picked != null)
                          c.expectedDeliveryDate.value = picked;
                      },
                    ),
                  ]),

                  _section('Shipping & Payment',
                      Icons.payments_outlined, [
                    SettingDropdownField(
                      label: 'Shipping Method',
                      category: 'shippingMethod',
                      value: c.shippingMethod.value,
                      options: c.shippingMethods,
                      onChanged: (v) => c.shippingMethod.value = v,
                      onManage: () => _navigateToSettings(context),
                    ),
                    const SizedBox(height: 10),
                    _textField('Shipping Carrier',
                        c.shippingCarrier.value,
                        (v) => c.shippingCarrier.value = v),
                    const SizedBox(height: 10),
                    _textField(
                        'Shipping Cost',
                        c.shippingCost.value.toString(),
                        (v) => c.shippingCost.value =
                            double.tryParse(v) ?? 0,
                        keyboard: TextInputType.number),
                    const SizedBox(height: 10),
                    SettingDropdownField(
                      label: 'Payment Method',
                      category: 'paymentMethod',
                      value: c.paymentMethod.value,
                      options: c.paymentMethods,
                      onChanged: (v) => c.paymentMethod.value = v,
                      onManage: () => _navigateToSettings(context),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: c.paymentStatus.value,
                      decoration: InputDecoration(
                        labelText: 'Payment Status',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: SalesOrderController
                          .paymentStatusCreateOptions
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) c.paymentStatus.value = v;
                      },
                    ),
                  ]),

                  _section('Discounts', Icons.discount_outlined, [
                    _textField('Coupon Code', c.couponCode.value,
                        (v) => c.couponCode.value = v),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: c.discountType.value,
                      decoration: InputDecoration(
                        labelText: 'Discount Type',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Percentage',
                            child: Text('Percentage')),
                        DropdownMenuItem(
                            value: 'Fixed',
                            child: Text('Fixed Amount')),
                      ],
                      onChanged: (v) {
                        if (v != null) c.discountType.value = v;
                      },
                    ),
                    const SizedBox(height: 10),
                    if (c.discountType.value == 'Percentage')
                      _textField(
                        'Discount %',
                        c.discountPercentage.value.toString(),
                        (v) => c.discountPercentage.value =
                            double.tryParse(v) ?? 0,
                        keyboard: TextInputType.number,
                      )
                    else
                      _textField(
                        'Discount Amount',
                        c.discountAmount.value.toString(),
                        (v) => c.discountAmount.value =
                            double.tryParse(v) ?? 0,
                        keyboard: TextInputType.number,
                      ),
                  ]),

                  _section('Notes', Icons.note_alt_outlined, [
                    _textField('Customer Notes', c.customerNotes.value,
                        (v) => c.customerNotes.value = v,
                        maxLines: 2),
                    const SizedBox(height: 10),
                    _textField('Internal Notes', c.internalNotes.value,
                        (v) => c.internalNotes.value = v,
                        maxLines: 2),
                    const SizedBox(height: 10),
                    _textField(
                        'Tags (comma separated)', c.tagsInput.value,
                        (v) => c.tagsInput.value = v),
                  ]),

                  _section('Summary', Icons.summarize_outlined, [
                    _summaryRow(
                        'Subtotal', c.formatCurrency(c.subtotal)),
                    _summaryRow('Shipping',
                        c.formatCurrency(c.shippingCost.value)),
                    _summaryRow('Discount',
                        '- ${c.formatCurrency(c.calculatedDiscount)}'),
                    const Divider(),
                    _summaryRow(
                        'Grand Total', c.formatCurrency(c.grandTotal),
                        bold: true),
                  ]),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _footer(context),
        ],
      );
    });
  }

  Widget _buildOrderItemsSection(
      SalesOrderController c, double screenHeight, BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Plus icon that navigates to Settings
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 18, color: kPrimary),
              const SizedBox(width: 8),
              const Text('Order Items',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              // Plus icon to navigate to Settings
              GestureDetector(
                onTap: () => _navigateToSettings(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 20,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Product Search Field
          ProductSearchField(
            controller: c,
            onSelected: (product) {
              if (product != null) {
                c.selectProduct(product);
              }
            },
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 38,
                  child: TextFormField(
                    controller: c.qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      labelStyle: const TextStyle(fontSize: 11),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 18),
                    ),
                    onChanged: (v) => c.updateQuantity(int.tryParse(v) ?? 1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 38,
                  child: Obx(() => ElevatedButton(
                    onPressed: c.selectedProduct.value == null
                        ? null
                        : () {
                            c.addProductToOrder(
                                c.selectedProduct.value!, c.quantity.value);
                            c.clearProductSelection();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Add Item',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  )),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),

          // Items List - Fixed with conditional rendering
          if (c.createItems.isEmpty)
            Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                'No items added yet',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 12),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.18,
              ),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: c.createItems.length,
                itemBuilder: (context, index) {
                  final item = c.createItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(
                          color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      title: Text(
                        item.productName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${item.sku} • Qty ${item.quantity}',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.formatCurrency(item.totalPrice),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: kDanger, size: 16),
                            onPressed: () =>
                                c.removeCreateItem(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                      minVerticalPadding: 0,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(
            bottom:
                BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_shopping_cart, color: kPrimary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Create New Order',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close, size: 22)),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Cancel',
                  style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(() {
              return ElevatedButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : () async {
                        final ok = await controller.submitCreateOrder();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Order created successfully')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text(
                        'Create Order',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _section(
      String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
              Icon(icon, size: 17, color: kPrimary),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _customerPicker(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer Name *',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) =>
                  CustomerPickerSheet(onSelect: c.applyCustomer),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border:
                  Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
              color: kBg,
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline,
                    size: 16, color: kSubText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.customerName.value.isEmpty
                        ? 'Select customer...'
                        : c.customerName.value,
                    style: TextStyle(
                      color: c.customerName.value.isEmpty
                          ? kSubText
                          : Colors.black87,
                      fontWeight: c.customerName.value.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (c.selectedCustomer.value != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => c.applyCustomer(null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Or enter customer name manually',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (v) => c.customerName.value = v,
          controller:
              TextEditingController(text: c.customerName.value)
                ..selection = TextSelection.collapsed(
                    offset: c.customerName.value.length),
        ),
      ],
    );
  }

  List<Widget> _addressFields(
    OrderAddress address,
    ValueChanged<OrderAddress> onChanged,
  ) {
    Widget field(
        String label, String value, void Function(String) setter) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13),
          controller: TextEditingController(text: value)
            ..selection =
                TextSelection.collapsed(offset: value.length),
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
      field('Postal Code', address.postalCode,
          (v) => address.postalCode = v),
      DropdownButtonFormField<String>(
        value:
            SalesOrderController.countryOptions.contains(address.country)
                ? address.country
                : 'Pakistan',
        decoration: InputDecoration(
          labelText: 'Country',
          labelStyle: const TextStyle(fontSize: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(fontSize: 13),
        items: SalesOrderController.countryOptions
            .map((e) => DropdownMenuItem(
                  value: e,
                  child:
                      Text(e, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            address.country = v;
            onChanged(address);
          }
        },
        menuMaxHeight: 200,
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
        labelStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      style: const TextStyle(fontSize: 13),
      keyboardType: keyboard,
      maxLines: maxLines,
      controller: TextEditingController(text: value)
        ..selection =
            TextSelection.collapsed(offset: value.length),
      onChanged: onChanged,
    );
  }

  Widget _summaryRow(String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight:
                        bold ? FontWeight.w700 : FontWeight.w500,
                    color: kSubText,
                    fontSize: 13)),
          ),
          Text(value,
              style: TextStyle(
                  fontWeight:
                      bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold ? kPrimary : kText,
                  fontSize: 13)),
        ],
      ),
    );
  }
}