// FILE: lib/src/ui/screens/suppliers_screen.dart
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/supplier_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/supplier_notifier.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/app_snackbar.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/confirmation_dialog.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/supplier_dialog.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<SupplierNotifier>(context, listen: false).syncFromNetwork();
      }
    });
  }

  void _showSupplierDialog({Supplier? supplier}) async {
    final notifier = context.read<SupplierNotifier>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => SupplierDialog(supplier: supplier),
    );
    if (result == null || !mounted) return;

    final name = result['name']!;
    final phone = result['phone'];
    final isEditing = supplier != null;

    try {
      if (isEditing) {
        await notifier.updateSupplier(supplier.id, name, phone);
      } else {
        await notifier.addSupplier(name, phone);
      }
      if (mounted) {
        showAppSnackBar(context,
            message: 'تم الحفظ بنجاح', type: NotificationType.success);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context,
            message: 'فشل الحفظ: $e', type: NotificationType.error);
      }
    }
  }

  void _deleteSupplier(Supplier supplier) async {
    final notifier = context.read<SupplierNotifier>();

    final confirmed = await showConfirmationDialog(
        context: context,
        title: 'تأكيد الحذف',
        content:
            'هل أنت متأكد من حذف المورّد "${supplier.name}"؟ سيتم فك ارتباطه من جميع المنتجات.',
        confirmText: 'حذف',
        icon: Symbols.delete,
        isDestructive: true);

    if (confirmed != true || !mounted) return;

    try {
      await notifier.deleteSupplier(supplier.id);
      if (mounted) {
        showAppSnackBar(context,
            message: 'تم الحذف بنجاح', type: NotificationType.success);
      }
    } catch (e) {
      if (mounted) {
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
        actions: [
          IconButton(
            icon: const Icon(Symbols.sync),
            onPressed:
                notifier.isLoading ? null : () => notifier.syncFromNetwork(),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _buildBody(notifier),
      floatingActionButton: FloatingActionButton(
        heroTag: 'suppliers_add_fab',
        onPressed: _showSupplierDialog,
        tooltip: 'إضافة مورّد جديد',
        child: const Icon(Symbols.add),
      ),
    );
  }

  Widget _buildBody(SupplierNotifier notifier) {
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
                  onPressed: () => _showSupplierDialog(supplier: supplier),
                ),
                IconButton(
                  icon: Icon(Symbols.delete,
                      color: Theme.of(context).colorScheme.error),
                  onPressed: () => _deleteSupplier(supplier),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}