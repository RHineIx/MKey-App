// FILE: lib/src/ui/screens/suppliers_screen.dart
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/notifiers/supplier_notifier.dart';

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
        final notifier = Provider.of<SupplierNotifier>(context, listen: false);
        notifier.syncFromNetwork();
      }
    });
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
            onPressed: notifier.isLoading ? null : () => notifier.syncFromNetwork(),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _buildBody(notifier),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement Add/Edit Supplier Dialog
        },
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
      return const Center(child: Text('لا يوجد مورّدون. قم بإضافة واحد جديد.'));
    }

    return ListView.builder(
      itemCount: notifier.suppliers.length,
      itemBuilder: (context, index) {
        final supplier = notifier.suppliers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(supplier.phone ?? 'لا يوجد رقم هاتف'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Symbols.edit),
                  onPressed: () {
                    // TODO: Implement Add/Edit Supplier Dialog (edit mode)
                  },
                ),
                IconButton(
                  icon: Icon(Symbols.delete, color: Theme.of(context).colorScheme.error),
                  onPressed: () {
                    // TODO: Implement delete logic with confirmation
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}