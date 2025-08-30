// FILE: lib/src/ui/widgets/sale_dialog.dart
import 'package:flutter/material.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';

class SaleDialog extends StatefulWidget {
  final Product product;

  const SaleDialog({super.key, required this.product});

  @override
  State<SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<SaleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    // TODO: Implement currency logic from SettingsNotifier
    _priceController = TextEditingController(text: widget.product.sellPriceIqd.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _confirmSale() {
    if (_formKey.currentState!.validate()) {
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      final price = double.tryParse(_priceController.text) ?? 0.0;
      // Return the result to the calling widget
      Navigator.of(context).pop({'quantity': quantity, 'price': price});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تسجيل عملية بيع'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.product.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'الكمية المباعة',
                hintText: 'الكمية المتوفرة: ${widget.product.quantity}',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال الكمية';
                }
                final qty = int.tryParse(value);
                if (qty == null || qty <= 0) {
                  return 'كمية غير صالحة';
                }
                if (qty > widget.product.quantity) {
                  return 'الكمية المطلوبة أكبر من المتوفر';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'سعر البيع للقطعة (دينار)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال السعر';
                }
                final price = double.tryParse(value);
                if (price == null || price < 0) {
                  return 'سعر غير صالح';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _confirmSale,
          child: const Text('تأكيد البيع'),
        ),
      ],
    );
  }
}