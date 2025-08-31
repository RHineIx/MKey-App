// FILE: lib/src/ui/widgets/bulk_supplier_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/models/supplier_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/supplier_notifier.dart';

class BulkSupplierDialog extends StatefulWidget {
  const BulkSupplierDialog({super.key});

  @override
  State<BulkSupplierDialog> createState() => _BulkSupplierDialogState();
}

class _BulkSupplierDialogState extends State<BulkSupplierDialog> {
  String? _selectedSupplierId;

  @override
  Widget build(BuildContext context) {
    final supplierNotifier = context.watch<SupplierNotifier>();

    return AlertDialog(
      title: const Text('تغيير مورّد العناصر المحددة'),
      content: DropdownButtonFormField<String>(
        value: _selectedSupplierId,
        decoration: const InputDecoration(labelText: 'المورّد الجديد'),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('-- إزالة المورّد --'),
          ),
          ...supplierNotifier.suppliers.map((Supplier s) {
            return DropdownMenuItem<String>(
              value: s.id,
              child: Text(s.name),
            );
          }),
        ],
        onChanged: (value) {
          setState(() {
            _selectedSupplierId = value;
          });
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            context
                .read<InventoryNotifier>()
                .handleBulkSupplierChange(_selectedSupplierId);
            Navigator.of(context).pop();
          },
          child: const Text('حفظ التغييرات'),
        ),
      ],
    );
  }
}