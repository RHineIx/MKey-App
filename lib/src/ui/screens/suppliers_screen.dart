import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/models/supplier_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/supplier_notifier.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/app_snackbar.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/confirmation_dialog.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/supplier_dialog.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  void _showSupplierDialog(BuildContext context, {Supplier? supplier}) async {
    final notifier = context.read<SupplierNotifier>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => SupplierDialog(supplier: supplier),
    );
    if (result == null || !context.mounted) return;

    final name = result['name']!;
    final phone = result['phone'];
    final isEditing = supplier != null;

    try {
      if (isEditing) {
        await notifier.updateSupplier(supplier.id, name, phone);
      } else {
        await notifier.addSupplier(name, phone);
      }
      if (context.mounted) {
        showAppSnackBar(context,
            message: 'تم الحفظ بنجاح', type: NotificationType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context,
            message: 'فشل الحفظ: $e', type: NotificationType.error);
      }
    }
  }

  void _deleteSupplier(BuildContext context, Supplier supplier) async {
    final supplierNotifier = context.read<SupplierNotifier>();
    final inventoryNotifier = context.read<InventoryNotifier>();

    final confirmed = await showConfirmationDialog(
        context: context,
        title: 'تأكيد الحذف',
        content:
        'هل أنت متأكد من حذف المورّد "${supplier.name}"؟ سيتم فك ارتباطه من جميع المنتجات.',
        confirmText: 'حذف',
        icon: Symbols.delete,
        isDestructive: true);
    if (confirmed != true || !context.mounted) return;

    try {
      // Unlink products from the supplier before deleting the supplier
      final linkedProducts = inventoryNotifier.displayedProducts.where((p) => p.supplierId == supplier.id).toList();
      for (final product in linkedProducts) {
        final updatedProduct = Product(
          id: product.id, name: product.name, sku: product.sku, quantity: product.quantity,
          alertLevel: product.alertLevel, costPriceIqd: product.costPriceIqd, sellPriceIqd: product.sellPriceIqd,
          costPriceUsd: product.costPriceUsd, sellPriceUsd: product.sellPriceUsd, notes: product.notes,
          imagePath: product.imagePath, categories: product.categories, oemPartNumber: product.oemPartNumber,
          compatiblePartNumber: product.compatiblePartNumber, supplierId: null, // This is the change
        );
        await inventoryNotifier.updateProduct(updatedProduct, null);
      }

      // Now, delete the supplier
      await supplierNotifier.deleteSupplier(supplier.id);

      if (context.mounted) {
        showAppSnackBar(context,
            message: 'تم الحذف بنجاح', type: NotificationType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context,
            message: 'فشل الحذف: $e', type: NotificationType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SupplierNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المورّدين'),
      ),
      body: _buildBody(notifier, context),
      floatingActionButton: FloatingActionButton(
        heroTag: 'suppliers_add_fab',
        onPressed: () => _showSupplierDialog(context),
        tooltip: 'إضافة مورّد جديد',
        child: const Icon(Symbols.add),
      ),
    );
  }

  Widget _buildBody(SupplierNotifier notifier, BuildContext context) {
    if (notifier.isLoading && notifier.suppliers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifier.error != null) {
      return Center(child: Text(notifier.error!));
    }

    if (notifier.suppliers.isEmpty) {
      return const Center(
          child: Text('لا يوجد مورّدون. قم بإضافة واحد جديد.'));
    }

    return ListView.builder(
      itemCount: notifier.suppliers.length,
      itemBuilder: (context, index) {
        final supplier = notifier.suppliers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            title: Text(supplier.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(supplier.phone ?? 'لا يوجد رقم هاتف'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Symbols.edit),
                  onPressed: () => _showSupplierDialog(context, supplier: supplier),
                ),
                IconButton(
                  icon: Icon(Symbols.delete,
                      color: Theme.of(context).colorScheme.error),
                  onPressed: () => _deleteSupplier(context, supplier),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}