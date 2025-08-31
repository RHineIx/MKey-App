// FILE: lib/src/ui/widgets/bulk_category_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/category_input.dart';

class BulkCategoryDialog extends StatefulWidget {
  const BulkCategoryDialog({super.key});

  @override
  State<BulkCategoryDialog> createState() => _BulkCategoryDialogState();
}

class _BulkCategoryDialogState extends State<BulkCategoryDialog> {
  Set<String> _selectedCategories = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تغيير فئة العناصر المحددة'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'القائمة الجديدة التي تبنيها هنا ستحل محل جميع الفئات القديمة للمنتجات المحددة.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            CategoryInput(
              initialCategories: _selectedCategories,
              onChanged: (newCategories) {
                setState(() {
                  _selectedCategories = newCategories;
                });
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
          onPressed: () {
            context
                .read<InventoryNotifier>()
                .handleBulkCategoryChange(_selectedCategories.toList());
            Navigator.of(context).pop();
          },
          child: const Text('حفظ التغييرات'),
        ),
      ],
    );
  }
}