// FILE: lib/src/ui/widgets/sale_list_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/settings_notifier.dart';
import 'package:provider/provider.dart';

class SaleListItem extends StatelessWidget {
  final Sale sale;

  const SaleListItem({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    final isIqd = settings.activeCurrency == 'IQD';
    final currencySymbol = isIqd ? 'د.ع' : '\$';
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
          '${formatter.format(totalSellPrice)} $currencySymbol',
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      '${formatter.format(profit)} $currencySymbol',
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
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}