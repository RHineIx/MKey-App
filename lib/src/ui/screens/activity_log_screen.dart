import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/activity_log_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/activity_log_notifier.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/app_snackbar.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/confirmation_dialog.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  Future<void> _handleClearLogs(BuildContext context) async {
    final notifier = context.read<ActivityLogNotifier>();
    if (notifier.filteredLogs.isEmpty) {
      showAppSnackBar(context, message: 'السجل فارغ بالفعل.', type: NotificationType.info);
      return;
    }

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'تأكيد تنظيف السجل',
      content: 'هل أنت متأكد من حذف جميع إدخالات سجل النشاطات نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'نعم, حذف الكل',
      icon: Symbols.delete_forever,
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      try {
        await notifier.clearLogs();
        if (context.mounted) {
          showAppSnackBar(context, message: 'تم تنظيف السجل بنجاح.', type: NotificationType.success);
        }
      } catch (e) {
        if (context.mounted) {
          showAppSnackBar(context, message: 'فشل تنظيف السجل: $e', type: NotificationType.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ActivityLogNotifier>();
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ActivityLogFilter>(
                    // FIXED: Using a Key to ensure the widget rebuilds with the new initialValue when the filter changes.
                    key: ValueKey(notifier.filter),
                    // FIXED: Using initialValue to satisfy the linter. The Key ensures reactivity.
                    initialValue: notifier.filter,
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
                  icon: const Icon(Symbols.delete_outline, weight: 700),
                  tooltip: 'تنظيف السجل',
                  onPressed: () => _handleClearLogs(context),
                )
              ],
            ),
          ),
          Expanded(
            child: _buildBody(notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ActivityLogNotifier notifier) {
    if (notifier.isLoading && notifier.filteredLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifier.filteredLogs.isEmpty) {
      return Center(
        child: Text(
          notifier.error ?? 'لا توجد سجلات لعرضها.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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

  (IconData, Color, String) _getVisualsForAction(String action) {
    switch (action) {
      case 'ITEM_CREATED':
        return (Symbols.add_box, Colors.green, 'إنشاء منتج');
      case 'SALE_RECORDED':
        return (Symbols.shopping_cart, Colors.blue, 'تسجيل بيع');
      case 'QUANTITY_UPDATED':
        return (Symbols.inventory_2, Colors.orange, 'تحديث الكمية');
      case 'ITEM_DELETED':
        return (Symbols.delete, Colors.red, 'حذف منتج');
      default:
        return (Symbols.edit, Colors.purple, 'تحديث بيانات');
    }
  }

  String _formatTimestamp(String isoString) {
    final dateTime = DateTime.parse(isoString).toLocal();
    return DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, title) = _getVisualsForAction(log.action);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Icon(icon, size: 20, weight: 700),
        ),
        title: Text(log.targetName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$title • ${_formatTimestamp(log.timestamp)}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _LogDetails(details: log.details),
          )
        ],
      ),
    );
  }
}

class _LogDetails extends StatelessWidget {
  final Map<String, dynamic> details;
  const _LogDetails({required this.details});
  @override
  Widget build(BuildContext context) {
    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 1))
      ),
      child: Column(
        children: details.entries.map((entry) {
          String keyText;
          String valueText;

          switch(entry.key) {
            case 'from':
              keyText = 'القيمة القديمة';
              break;
            case 'to':
              keyText = 'القيمة الجديدة';
              break;
            case 'quantity':
              keyText = 'الكمية';
              break;
            case 'price':
              keyText = 'السعر';
              break;
            case 'currency':
              keyText = 'العملة';
              break;
            case 'reason':
              keyText = 'السبب';
              break;
            default:
              keyText = entry.key;
          }

          valueText = entry.value.toString();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(keyText, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                Text(valueText, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}