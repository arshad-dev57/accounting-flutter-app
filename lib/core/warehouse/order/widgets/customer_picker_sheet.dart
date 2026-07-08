import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehouse/order/controller/order_customer_controller.dart';
import 'package:LedgerPro_app/core/warehouse/order/model/customer_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CustomerPickerSheet extends StatefulWidget {
  final ValueChanged<WarehouseCustomer> onSelect;

  const CustomerPickerSheet({super.key, required this.onSelect});

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  late final OrderCustomerController customerController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    customerController = Get.put(OrderCustomerController(), tag: 'order_customer_picker');
    customerController.resetAndLoad();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Get.delete<OrderCustomerController>(tag: 'order_customer_picker');
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      customerController.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.person_search, color: kPrimary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Select Customer',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name, email or phone...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: customerController.onSearchChanged,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                if (customerController.isLoading.value &&
                    customerController.customers.isEmpty) {
                  return Center(
                    child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 32),
                  );
                }

                if (customerController.customers.isEmpty) {
                  return Center(
                    child: Text('No customers found', style: TextStyle(color: kSubText)),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: customerController.customers.length + 1,
                  itemBuilder: (context, index) {
                    if (index == customerController.customers.length) {
                      if (customerController.isLoadingMore.value) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      return const SizedBox(height: 16);
                    }

                    final customer = customerController.customers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kPrimary.withOpacity(0.15),
                        child: Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        [
                          customer.email,
                          customer.phone,
                          customer.customerNumber,
                        ].whereType<String>().where((e) => e.isNotEmpty).join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        widget.onSelect(customer);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
