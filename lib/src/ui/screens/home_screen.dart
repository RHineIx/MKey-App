import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_workshop_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_workshop_app/src/ui/screens/settings_screen.dart';
import 'package:rhineix_workshop_app/src/ui/widgets/category_filter_bar.dart';
import 'package:rhineix_workshop_app/src/ui/widgets/inventory_header.dart';
import 'package:rhineix_workshop_app/src/ui/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 15;
  int _itemsToShow = 15;
  bool _showScrollTopButton = false;

  @override
  void initState() {
    super.initState();
    final notifier = Provider.of<InventoryNotifier>(context, listen: false);
    notifier.fetchInventory(onFilterChanged: _onFilterChanged);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMoreItems();
      }
      if (_scrollController.position.pixels > 400) {
        if (!_showScrollTopButton) {
          setState(() {
            _showScrollTopButton = true;
          });
        }
      } else {
        if (_showScrollTopButton) {
          setState(() {
            _showScrollTopButton = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMoreItems() {
    final notifier = Provider.of<InventoryNotifier>(context, listen: false);
    if (_itemsToShow < notifier.filteredProducts.length) {
      setState(() {
        _itemsToShow += _pageSize;
        if (_itemsToShow > notifier.filteredProducts.length) {
          _itemsToShow = notifier.filteredProducts.length;
        }
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onFilterChanged() {
    if (mounted) {
      setState(() {
        _itemsToShow = _pageSize;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MASTER KEY'),
        actions: [
          Consumer<InventoryNotifier>(
            builder: (context, notifier, child) => IconButton(
              icon: const Icon(Icons.sync),
              onPressed: notifier.isLoading ? null : () => notifier.fetchInventory(onFilterChanged: _onFilterChanged),
              tooltip: 'تحديث',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _navigateToSettings,
            tooltip: 'الإعدادات',
          ),
        ],
      ),
      body: Consumer<InventoryNotifier>(
        builder: (context, notifier, child) {
          if (notifier.isLoading && notifier.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (notifier.error != null) {
            // Corrected: Added const here
            return const Center(child: Text('Error placeholder'));
          }

          final productsToDisplay = notifier.filteredProducts.take(_itemsToShow).toList();

          return RefreshIndicator(
            onRefresh: () async => notifier.fetchInventory(onFilterChanged: _onFilterChanged),
            child: Column(
              children: [
                InventoryHeader(onFilterChanged: _onFilterChanged),
                CategoryFilterBar(
                  allCategories: notifier.categories,
                  selectedCategory: notifier.selectedCategory,
                  onCategorySelected: (category) {
                    notifier.selectCategory(category);
                    _onFilterChanged();
                  },
                ),
                Expanded(
                  child: productsToDisplay.isEmpty && !notifier.isLoading
                      ? const Center(child: Text('لم يتم العثور على منتجات.'))
                      : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.7,
                    ),
                    itemCount: productsToDisplay.length,
                    itemBuilder: (context, index) {
                      final product = productsToDisplay[index];
                      return ProductCard(product: product);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            opacity: _showScrollTopButton ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: FloatingActionButton.small(
              onPressed: _scrollToTop,
              tooltip: 'العودة للأعلى',
              child: const Icon(Symbols.arrow_upward),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () {
              // TODO: Implement Add Product Action
            },
            tooltip: 'إضافة منتج جديد',
            icon: const Icon(Symbols.add),
            label: const Text('إضافة منتج'),
          ),
        ],
      ),
    );
  }
}