import 'package:flutter/material.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  required IconData icon,
  String confirmText = 'تأكيد',
  bool isDestructive = true,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final iconColor = isDestructive ? colorScheme.error : colorScheme.primary;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 48, weight: 700),
          const SizedBox(height: 16),
          Text(title),
        ],
      ),
      content: Text(content, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: isDestructive ? colorScheme.error : null,
          ),
          child: Text(confirmText),
        ),
      ],
    ),
  );
}