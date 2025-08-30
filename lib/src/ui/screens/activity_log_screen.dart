// FILE: lib/src/ui/screens/activity_log_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/activity_log_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/activity_log_notifier.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final notifier = Provider.of<ActivityLogNotifier>(context, listen: false);
        notifier.syncFromNetwork();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ActivityLogNotifier>();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => notifier.syncFromNetwork(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ActivityLogFilter>(
                      initialValue: notifier.filter, // Corrected: from 'value' to 'initialValue'
                      decoration: const InputDecoration(
                        labelText: 'فلترة حسب النشاط',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: ActivityLogFilter.all, child: Text('كل النشاطات')),
                        DropdownMenuItem(value: ActivityLogFilter.sale, child: Text('المبيعات')),
                        DropdownMenuItem(value: ActivityLogFilter.quantity, child: Text('تعديلات الكمية')),
                        DropdownMenuItem(value: ActivityLogFilter.lifecycle, child: Text('إضافة / حذف')),
                        DropdownMenuItem(value: ActivityLogFilter.other, child: Text('تحديثات أخرى')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          notifier.setFilter(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Symbols.delete_outline),
                    tooltip: 'تنظيف السجل',
                    onPressed: () {
                      // TODO: Implement log cleanup logic with confirmation
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: _buildBody(notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ActivityLogNotifier notifier) {
    if (notifier.isLoading && notifier.filteredLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifier.error != null) {
      return Center(child: Text(notifier.error!));
    }

    if (notifier.filteredLogs.isEmpty) {
      return const Center(child: Text('لا توجد سجلات لعرضها.'));
    }

    return ListView.builder(
      itemCount: notifier.filteredLogs.length,
      itemBuilder: (context, index) {
        final log = notifier.filteredLogs[index];
        return _LogEntryCard(log: log);
      },
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  final ActivityLog log;
  const _LogEntryCard({required this.log});

  (IconData, Color) _getIconForAction(String action) {
    switch (action) {
      case 'ITEM_CREATED':
        return (Symbols.add_box, Colors.green);
      case 'SALE_RECORDED':
        return (Symbols.shopping_cart, Colors.blue);
      case 'QUANTITY_UPDATED':
        return (Symbols.inventory_2, Colors.orange);
      case 'ITEM_DELETED':
        return (Symbols.delete, Colors.red);
      default:
        return (Symbols.edit, Colors.purple);
    }
  }

  String _formatTimestamp(String isoString) {
    final dateTime = DateTime.parse(isoString).toLocal();
    return DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getIconForAction(log.action);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Icon(icon, size: 20),
        ),
        title: Text(
          '${log.targetName}: ${log.action}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('بواسطة ${log.user} • ${_formatTimestamp(log.timestamp)}'),
        // TODO: Add an expansion tile to show log.details
      ),
    );
  }
}