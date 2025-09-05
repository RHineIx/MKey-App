import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/dashboard_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/settings_notifier.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/app_snackbar.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/confirmation_dialog.dart';

class SaleListItem extends StatelessWidget {
  final Sale sale;

  const SaleListItem({super.key, required this.sale});

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'تأكيد الحذف',
      content: 'هل أنت متأكد من حذف سجل بيع المنتج "${sale.itemName}"؟ سيتم إعادة الكمية المباعة إلى المخزون.',
      confirmText: 'نعم, حذف',
      icon: Symbols.delete,
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    final notifier = context.read<DashboardNotifier>();
    try {
      await notifier.deleteSale(sale.saleId);
      if (context.mounted) {
        showAppSnackBar(context, message: 'تم حذف السجل وإعادة الكمية للمخزون.', type: NotificationType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: 'فشل حذف السجل: $e', type: NotificationType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    final isIqd = settings.activeCurrency == 'IQD';
    final currencySymbol = isIqd ? 'د.ع' : '\$';
    // FIXED: Added number formatter
    final formatter = NumberFormat('#,##0.##');
    final totalSellPrice = (isIqd ? sale.sellPriceIqd : sale.sellPriceUsd) * sale.quantitySold;
    final totalCostPrice = (isIqd ? sale.costPriceIqd : sale.costPriceUsd) * sale.quantitySold;
    final profit = totalSellPrice - totalCostPrice;
    final profitIsPositive = profit >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(sale.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('الكمية: ${sale.quantitySold}'),
        trailing: Text(
          '${formatter.format(totalSellPrice)} $currencySymbol', // FIXED
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          profitIsPositive ? Symbols.trending_up : Symbols.trending_down,
                          color: profitIsPositive ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('الربح'),
                      ],
                    ),
                    Text(
                      '${formatter.format(profit)} $currencySymbol', // FIXED
                      style: TextStyle(
                        color: profitIsPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Symbols.notes, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text('ملاحظات: ${sale.notes!}')),
                    ],
                  ),
                ],
                const Divider(),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: () => _handleDelete(context),
                    icon: Icon(Symbols.delete, color: Theme.of(context).colorScheme.error),
                    label: Text('حذف السجل', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}