import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/warehouse/Stock_in/controller/stock_in_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/Stock_in/model/stock_movement_model.dart';
import 'package:flutter/material.dart';

class StockMovementDetailSheet extends StatelessWidget {
  final StockController controller;
  final StockMovementModel movement;
  final VoidCallback onClose;

  const StockMovementDetailSheet({
    super.key,
    required this.controller,
    required this.movement,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = controller.getTypeColor(movement.type);
    final boxSummary = movement.stockDetails?.boxSummary;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      controller.getTypeIcon(movement.type),
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movement.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          movement.getTypeLabel(),
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              _row(
                'Quantity',
                '${movement.type == 'stock_in' ? '+' : '-'}${movement.quantity}',
              ),
              _row('Stock', '${movement.previousStock} → ${movement.newStock}'),
              _row('Status', movement.status),
              if (boxSummary != null) _row('Box Details', boxSummary),
              if (movement.reason.isNotEmpty) _row('Reason', movement.reason),
              if (movement.supplierName != null &&
                  movement.supplierName!.isNotEmpty)
                _row('Supplier', movement.supplierName!),
              if (movement.customerName != null &&
                  movement.customerName!.isNotEmpty)
                _row('Customer', movement.customerName!),
              if (movement.reference != null && movement.reference!.isNotEmpty)
                _row('Reference', movement.reference!),
              if (movement.notes != null && movement.notes!.isNotEmpty)
                _row('Notes', movement.notes!),
              _row('Date', controller.formatDate(movement.createdAt)),
              if (movement.createdBy != null)
                _row('By', movement.createdBy!.name),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: kSubText, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
