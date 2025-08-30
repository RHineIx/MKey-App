// FILE: lib/src/ui/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/category_filter_bar.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/inventory_header.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/product_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTopButton = false;

  @override
  void initState() {
    super.initState();
    // Added mounted check for safety
    if (mounted) {
      final notifier = Provider.of<InventoryNotifier>(context, listen: false);
      Future.microtask(() => _handleSync(notifier, isInitial: true));
    }

    _scrollController.addListener(() {
      if (!mounted) return;
      if (_scrollController.position.pixels > 400) {
        if (!_showScrollTopButton) setState(() => _showScrollTopButton = true);
      } else {
        if (_showScrollTopButton) setState(() => _showScrollTopButton = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSync(InventoryNotifier notifier, {bool isInitial = false}) async {
    _onFilterChanged();
    final String? errorMessage = await notifier.syncFromNetwork();
    if (mounted && errorMessage != null && !isInitial) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل التحديث: $errorMessage'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _onFilterChanged() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<InventoryNotifier>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _handleSync(notifier),
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
              child: _buildBody(notifier),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showScrollTopButton)
            FloatingActionButton.small(
              onPressed: _scrollToTop,
              tooltip: 'العودة للأعلى',
              child: const Icon(Symbols.arrow_upward),
            ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () {
              // TODO: Navigate to Product Form Screen for adding
            },
            tooltip: 'إضافة منتج جديد',
            icon: const Icon(Symbols.add),
            label: const Text('إضافة منتج'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(InventoryNotifier notifier) {
    if (notifier.isLoading && notifier.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifier.products.isEmpty && notifier.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
          Text('حدث خطأ:\n${notifier.error}', textAlign: TextAlign.center),
        ),
      );
    }

    if (notifier.filteredProducts.isEmpty) {
      return const Center(child: Text('لم يتم العثور على منتجات.'));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.7,
      ),
      itemCount: notifier.filteredProducts.length,
      itemBuilder: (context, index) {
        final product = notifier.filteredProducts[index];
        return ProductCard(product: product);
      },
    );
  }
}