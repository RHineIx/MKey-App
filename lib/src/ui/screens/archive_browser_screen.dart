import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/models/github_file_model.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/settings_notifier.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';

class ArchiveBrowserScreen extends StatefulWidget {
  const ArchiveBrowserScreen({super.key});
  @override
  State<ArchiveBrowserScreen> createState() => _ArchiveBrowserScreenState();
}

class _ArchiveBrowserScreenState extends State<ArchiveBrowserScreen> {
  bool _isLoadingList = true;
  bool _isLoadingDetails = false;
  String? _error;
  List<GithubFile> _archives = [];
  List<Sale> _selectedArchiveContent = [];
  String? _selectedArchivePath;

  @override
  void initState() {
    super.initState();
    _fetchArchiveList();
  }

  Future<void> _fetchArchiveList() async {
    if (!mounted) return;
    setState(() {
      _isLoadingList = true;
      _error = null;
    });
    try {
      final githubService = context.read<GithubService>();
      final archives = await githubService.getDirectoryListing('archive');
      archives.sort((a, b) => b.path.compareTo(a.path));
      if (mounted) {
        setState(() {
          _archives = archives;
          _isLoadingList = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل تحميل قائمة الأرشيف: $e';
          _isLoadingList = false;
        });
      }
    }
  }

  Future<void> _fetchArchiveDetails(String path) async {
    if (!mounted) return;
    setState(() {
      _isLoadingDetails = true;
      _selectedArchivePath = path;
      _selectedArchiveContent = [];
      _error = null;
    });
    try {
      final githubService = context.read<GithubService>();
      final jsonContent = await githubService.fetchFileContent(path);
      final List<dynamic> decodedList = jsonDecode(jsonContent);
      final sales = decodedList.map((item) => Sale.fromJson(item)).toList();

      if (mounted) {
        setState(() {
          _selectedArchiveContent = sales;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل تحميل تفاصيل الأرشيف: $e';
          _isLoadingDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متصفح الأرشيف'),
      ),
      body: Column(
        children: [
          _buildArchiveList(),
          const Divider(height: 1),
          Expanded(child: _buildDetailsView()),
        ],
      ),
    );
  }

  Widget _buildArchiveList() {
    if (_isLoadingList) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_archives.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('لم يتم العثور على ملفات أرشفة.')),
      );
    }

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        itemCount: _archives.length,
        itemBuilder: (context, index) {
          final archive = _archives[index];
          final isSelected = _selectedArchivePath == archive.path;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(archive.path.split('/').last.replaceAll('.json', '')),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _fetchArchiveDetails(archive.path);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsView() {
    if (_isLoadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_selectedArchivePath == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.archive, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('الرجاء اختيار ملف أرشيف لعرض محتواه'),
          ],
        ),
      );
    }
    if (_selectedArchiveContent.isEmpty) {
      return const Center(child: Text('ملف الأرشيف هذا فارغ.'));
    }

    final settings = context.watch<SettingsNotifier>();
    final isIqd = settings.activeCurrency == 'IQD';
    final currencySymbol = isIqd ? 'د.ع' : '\$';
    final formatter = NumberFormat('#,##0.##');

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _selectedArchiveContent.length,
      itemBuilder: (context, index) {
        final sale = _selectedArchiveContent[index];
        final price = isIqd ? sale.sellPriceIqd : sale.sellPriceUsd;
        final total = price * sale.quantitySold;

        return Card(
          child: ListTile(
            title: Text(sale.itemName),
            subtitle: Text('الكمية: ${sale.quantitySold} • التاريخ: ${sale.saleDate}'),
            trailing: Text(
              '${formatter.format(total)} $currencySymbol',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}