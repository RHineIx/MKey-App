// FILE: lib/src/ui/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/notifiers/dashboard_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/settings_notifier.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final notifier = Provider.of<DashboardNotifier>(context, listen: false);
        notifier.syncFromNetwork();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<DashboardNotifier>();
    final settings = context.watch<SettingsNotifier>();

    // Calculate totals based on currency
    double totalSales = 0;
    double totalProfit = 0;
    final isIqd = settings.activeCurrency == 'IQD';

    for (var sale in notifier.filteredSales) {
      final sellPrice = isIqd ? sale.sellPriceIqd : sale.sellPriceUsd;
      final costPrice = isIqd ? sale.costPriceIqd : sale.costPriceUsd;
      totalSales += sellPrice * sale.quantitySold;
      totalProfit += (sellPrice - costPrice) * sale.quantitySold;
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => notifier.syncFromNetwork(),
        child: ListView(
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
              const Center(child: CircularProgressIndicator())
            else if (notifier.error != null)
              Center(child: Text(notifier.error!))
            else
              _buildStats(totalSales, totalProfit, settings.activeCurrency),

            // TODO: Add Bestsellers and Sales Log widgets here
          ],
        ),
      ),
    );
  }

  Widget _buildStats(double totalSales, double totalProfit, String currency) {
    final symbol = currency == 'IQD' ? 'د.ع' : '\$';
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.point_of_sale),
            title: const Text('إجمالي المبيعات'),
            trailing: Text(
              '${totalSales.toStringAsFixed(2)} $symbol',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.trending_up, color: Colors.green[700]),
            title: const Text('إجمالي الأرباح'),
            trailing: Text(
              '${totalProfit.toStringAsFixed(2)} $symbol',
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
}