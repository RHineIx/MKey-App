import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';

void showAppSnackBar(
    BuildContext context, {
      required String message,
      required NotificationType type,
    }) {
  final colorScheme = Theme.of(context).colorScheme;
  final surfaceColor = Theme.of(context).cardColor;

  IconData icon;
  Color borderColor;

  switch (type) {
    case NotificationType.success:
      icon = Symbols.check_circle;
      borderColor = Colors.green;
      break;
    case NotificationType.error:
      icon = Symbols.error;
      borderColor = colorScheme.error;
      break;
    case NotificationType.info:
      icon = Symbols.info;
      borderColor = Colors.blue;
      break;
    case NotificationType.syncing:
      icon = Symbols.sync;
      borderColor = colorScheme.primary;
      break;
  }

  final snackBar = SnackBar(
    content: Row(
      children: [
        Container(
          width: 5,
          height: 40,
          decoration: BoxDecoration(
            color: borderColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: borderColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      ],
    ),
    backgroundColor: surfaceColor,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
    ),
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    elevation: 3,
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}