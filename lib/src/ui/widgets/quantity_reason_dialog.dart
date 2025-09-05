import 'package:flutter/material.dart';

Future<String?> showQuantityReasonDialog(BuildContext context) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('سبب تغيير الكمية'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'السبب (اختياري)',
            hintText: 'مثال: استلام بضاعة، تلف، جرد...',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(''), // Save without reason
          child: const Text('حفظ بدون سبب'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(dialogContext).pop(controller.text.trim());
            }
          },
          child: const Text('تأكيد السبب'),
        ),
      ],
    ),
  );
}