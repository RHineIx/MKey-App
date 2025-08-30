// FILE: lib/src/ui/widgets/inventory_header.dart
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';

class InventoryHeader extends StatefulWidget {
  final VoidCallback onFilterChanged;
  const InventoryHeader({
    super.key,
    required this.onFilterChanged,
  });

  @override
  State<InventoryHeader> createState() => _InventoryHeaderState();
}

class _InventoryHeaderState extends State<InventoryHeader> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<InventoryNotifier>();
    final hintColor = Theme.of(context).hintColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                notifier.filterProducts(query: query);
                widget.onFilterChanged();
                setState(() {}); // To show/hide the clear button
              },
              decoration: InputDecoration(
                hintText: 'ابحث في المنتجات...',
                prefixIcon: const Icon(Symbols.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Symbols.close),
                  onPressed: () {
                    _searchController.clear();
                    notifier.filterProducts(query: '');
                    widget.onFilterChanged();
                    setState(() {});
                  },
                )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<SortOption>(
            onSelected: (option) {
              notifier.sortProducts(option);
              widget.onFilterChanged();
            },
            itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<SortOption>>[
              const PopupMenuItem(
                  value: SortOption.defaults, child: Text('فرز افتراضي')),
              const PopupMenuItem(
                  value: SortOption.dateDesc, child: Text('الأحدث أولاً')),
              const PopupMenuItem(
                  value: SortOption.nameAsc, child: Text('الاسم (أ - ي)')),
              const PopupMenuItem(
                  value: SortOption.quantityAsc,
                  child: Text('الكمية (الأقل أولاً)')),
              const PopupMenuItem(
                  value: SortOption.quantityDesc,
                  child: Text('الكمية (الأكثر أولاً)')),
            ],
            icon: Icon(Symbols.sort, color: hintColor),
            tooltip: 'فرز',
          ),
        ],
      ),
    );
  }
}