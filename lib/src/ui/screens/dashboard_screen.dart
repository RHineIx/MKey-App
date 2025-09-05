import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/notifiers/dashboard_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/settings_notifier.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/sale_list_item.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<DashboardNotifier>();
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<DashboardPeriod>(
            segments: const <ButtonSegment<DashboardPeriod>>[
              ButtonSegment<DashboardPeriod>(
                  value: DashboardPeriod.today, label: Text('يومي')),
              ButtonSegment<DashboardPeriod>(
                  value: DashboardPeriod.week, label: Text('أسبوعي')),
              ButtonSegment<DashboardPeriod>(
                  value: DashboardPeriod.month, label: Text('شهري')),
            ],
            selected: <DashboardPeriod>{notifier.period},
            onSelectionChanged: (Set<DashboardPeriod> newSelection) {
              notifier.setPeriod(newSelection.first);
            },
          ),
          const SizedBox(height: 16),
          if (notifier.isLoading && notifier.filteredSales.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ))
          else if (notifier.error != null)
            Center(child: Text('حدث خطأ: ${notifier.error}'))
          else ...[
              _buildStats(context, notifier),
              const SizedBox(height: 24),
              _buildBestsellers(context, notifier),
              const SizedBox(height: 24),
              _buildSalesLog(context, notifier),
            ]
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, DashboardNotifier notifier) {
    final settings = context.watch<SettingsNotifier>();
    final isIqd = settings.activeCurrency == 'IQD';
    final currencySymbol = isIqd ? 'د.ع' : '\$';
    // FIXED: Added number formatter
    final formatter = NumberFormat('#,##0.##');

    double totalSales = 0;
    double totalProfit = 0;
    for (var sale in notifier.filteredSales) {
      final sellPrice = isIqd ? sale.sellPriceIqd : sale.sellPriceUsd;
      final costPrice = isIqd ? sale.costPriceIqd : sale.costPriceUsd;
      totalSales += sellPrice * sale.quantitySold;
      totalProfit += (sellPrice - costPrice) * sale.quantitySold;
    }

    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.point_of_sale),
            title: const Text('إجمالي المبيعات'),
            trailing: Text(
              '${formatter.format(totalSales)} $currencySymbol', // FIXED
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.trending_up, color: Colors.green[700]),
            title: const Text('إجمالي الأرباح'),
            trailing: Text(
              '${formatter.format(totalProfit)} $currencySymbol', // FIXED
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: totalProfit >= 0 ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBestsellers(BuildContext context, DashboardNotifier notifier) {
    final bestsellers = notifier.bestsellers;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('أفضل المنتجات مبيعًا', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            if (bestsellers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('لا توجد مبيعات في هذه الفترة.'),
              )
            else
              ...bestsellers.map((item) => ListTile(
                title: Text(item.name),
                trailing: Chip(label: Text('بيع ${item.count}')),
              ))
          ],
        ),
      ),
    );
  }

  Widget _buildSalesLog(BuildContext context, DashboardNotifier notifier) {
    final sales = notifier.filteredSales;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('سجل المبيعات', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (sales.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('لا توجد مبيعات في هذه الفترة.'),
            ),
          )
        else
          ...sales.map((sale) => SaleListItem(sale: sale)),
      ],
    );
  }
}