import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/ui/screens/product_form_screen.dart';
import '../widgets/bulk_actions_bar.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/inventory_header.dart';
import '../widgets/product_card.dart';

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
    _scrollController.addListener(() {
      if (!mounted) return;

      // Show/hide scroll to top button
      if (_scrollController.position.pixels > 400) {
        if (!_showScrollTopButton) setState(() => _showScrollTopButton = true);
      } else {
        if (_showScrollTopButton) setState(() => _showScrollTopButton = false);
      }

      // Trigger load more
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<InventoryNotifier>().loadMoreProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _onFilterChanged() {
    if (_scrollController.hasClients && _scrollController.position.pixels > 0) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<InventoryNotifier>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Column(
          children: [
            InventoryHeader(onFilterChanged: _onFilterChanged),
            CategoryFilterBar(
              onCategorySelected: (category) {
                notifier.selectCategory(category);
                _onFilterChanged();
              },
            ),
            Expanded(
              child: _buildBody(notifier),
            ),
            const BulkActionsBar(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showScrollTopButton && !notifier.isSelectionModeActive)
              FloatingActionButton.small(
                heroTag: 'inventory_scroll_top_fab',
                onPressed: _scrollToTop,
                tooltip: 'العودة للأعلى',
                child: const Icon(Symbols.arrow_upward, weight: 700),
              ),
            const SizedBox(height: 16),
            if (!notifier.isSelectionModeActive)
              FloatingActionButton(
                heroTag: 'inventory_add_fab',
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ProductFormScreen(),
                  ));
                },
                tooltip: 'إضافة منتج جديد',
                child: const Icon(Symbols.add, weight: 700),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(InventoryNotifier notifier) {
    if (notifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifier.displayedProducts.isEmpty && !notifier.isLoadingMore) {
      if (notifier.error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
            Text('حدث خطأ:\n${notifier.error}', textAlign: TextAlign.center),
          ),
        );
      }
      return const Center(child: Text('لم يتم العثور على منتجات.'));
    }

    return AnimationLimiter(
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 0.65,
        ),
        itemCount:
        notifier.displayedProducts.length + (notifier.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == notifier.displayedProducts.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = notifier.displayedProducts[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 300),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: ProductCard(product: product),
              ),
            ),
          );
        },
      ),
    );
  }
}