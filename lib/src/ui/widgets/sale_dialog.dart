// FILE: lib/src/ui/widgets/sale_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/settings_notifier.dart';

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
  late final TextEditingController _notesController;

  late DateTime _selectedDate;
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _notesController = TextEditingController();
    _selectedDate = DateTime.now();

    final settings = context.read<SettingsNotifier>();
    final isIqd = settings.activeCurrency == 'IQD';
    final initialPrice = isIqd ? widget.product.sellPriceIqd : widget.product.sellPriceUsd;
    _priceController = TextEditingController(text: initialPrice.toString());

    _calculateTotal();

    _quantityController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateTotal);
    _priceController.removeListener(_calculateTotal);
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    setState(() {
      _totalPrice = quantity * price;
    });
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _confirmSale() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'quantity': int.parse(_quantityController.text),
        'price': double.parse(_priceController.text),
        'notes': _notesController.text.trim(),
        'saleDate': _selectedDate,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    final isIqd = settings.activeCurrency == 'IQD';
    final currencySymbol = isIqd ? 'د.ع' : '\$';
    final priceLabel = 'سعر البيع ($currencySymbol)';
    final formatter = NumberFormat('#,##0.##');

    return AlertDialog(
      title: const Text('تسجيل عملية بيع'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      content: SizedBox(
        // Set a width to make the dialog wider
        width: MediaQuery.of(context).size.width,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.product.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'الكمية المباعة',
                          hintText: 'المتوفر: ${widget.product.quantity}',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'الرجاء إدخال الكمية';
                          final qty = int.tryParse(value);
                          if (qty == null || qty <= 0) return 'كمية غير صالحة';
                          if (qty > widget.product.quantity) return 'الكمية أكبر من المتوفر';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(labelText: priceLabel),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'الرجاء إدخال السعر';
                          final price = double.tryParse(value);
                          if (price == null || price < 0) return 'سعر غير صالح';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الإجمالي'),
                  trailing: Text(
                    '${formatter.format(_totalPrice)} $currencySymbol',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تاريخ البيع'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات على البيع (اختياري)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
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