import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';

class CategoryEditDialog extends StatefulWidget {
  final String oldName;
  const CategoryEditDialog({super.key, required this.oldName});

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.oldName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_nameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<InventoryNotifier>();
    return AlertDialog(
      title: const Text('تعديل اسم الفئة'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration:
          const InputDecoration(labelText: 'الاسم الجديد للفئة'),
          validator: (value) {
            final trimmedValue = value?.trim() ?? '';
            if (trimmedValue.isEmpty) {
              return 'الرجاء إدخال اسم الفئة';
            }
            if (trimmedValue.toLowerCase() != widget.oldName.toLowerCase() &&
                notifier.categories.any((c) => c.toLowerCase() == trimmedValue.toLowerCase())) {
              return 'اسم الفئة هذا موجود بالفعل.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('حفظ التغييرات'),
        ),
      ],
    );
  }
}