// FILE: lib/src/ui/widgets/bulk_actions_bar.dart
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/supplier_notifier.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/bulk_category_dialog.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/bulk_supplier_dialog.dart';

class BulkActionsBar extends StatelessWidget {
  const BulkActionsBar({super.key});

  void _showBulkCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const BulkCategoryDialog(),
    );
  }

  void _showBulkSupplierDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SupplierNotifier>(),
        child: const BulkSupplierDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<InventoryNotifier>();
    final bool isVisible = notifier.isSelectionModeActive;
    final int count = notifier.selectedItemIds.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isVisible ? 80.0 : 0.0,
      child: isVisible
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('تم تحديد $count عناصر'),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Symbols.folder_open),
                    label: const Text('الفئة'),
                    onPressed: () => _showBulkCategoryDialog(context),
                  ),
                  TextButton.icon(
                    icon: const Icon(Symbols.group),
                    label: const Text('المورّد'),
                    onPressed: () => _showBulkSupplierDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.close),
                    onPressed: notifier.exitSelectionMode,
                    tooltip: 'إلغاء',
                  ),
                ],
              ),
            )
          : null,
    );
  }
}