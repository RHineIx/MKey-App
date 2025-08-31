// FILE: lib/src/ui/widgets/product_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/settings_notifier.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';
import 'package:rhineix_mkey_app/src/ui/screens/product_detail_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/product_form_screen.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/confirmation_dialog.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/sale_dialog.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  void _showSaleDialog(BuildContext context) async {
    final notifier = context.read<InventoryNotifier>();
    final settings = context.read<SettingsNotifier>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SaleDialog(product: product),
    );
    if (result == null || !scaffoldMessenger.mounted) return;

    try {
      await notifier.recordSale(
        product: product,
        quantity: result['quantity'] as int,
        price: result['price'] as double,
        notes: result['notes'] as String,
        saleDate: result['saleDate'] as DateTime,
        currency: settings.activeCurrency,
        exchangeRate: settings.exchangeRate,
      );
      scaffoldMessenger.showSnackBar(
        const SnackBar(
            content: Text('تم تسجيل البيع بنجاح'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('فشل تسجيل البيع: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _deleteProduct(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final notifier = context.read<InventoryNotifier>();

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'تأكيد الحذف',
      content: 'هل أنت متأكد من رغبتك في حذف المنتج "${product.name}"؟',
      confirmText: 'حذف',
    );

    if (confirmed != true || !scaffoldMessenger.mounted) return;
    try {
      await notifier.deleteProduct(product.id);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
            content: Text('تم حذف المنتج بنجاح'), backgroundColor: Colors.green),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'ar_IQ');
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final githubService = Provider.of<GithubService>(context, listen: false);

    // NEW: Listen to notifier for selection mode changes
    final inventoryNotifier = context.watch<InventoryNotifier>();
    final isSelectionMode = inventoryNotifier.isSelectionModeActive;
    final isSelected = inventoryNotifier.selectedItemIds.contains(product.id);

    final bool isOutOfStock = product.quantity <= 0;
    final bool isLowStock =
        !isOutOfStock && product.quantity <= product.alertLevel;

    final String badgeText;
    final Color badgeColor;

    if (isOutOfStock) {
      badgeText = 'نفد المخزون';
      badgeColor = colorScheme.error;
    } else if (isLowStock) {
      badgeText = 'منخفض: ${product.quantity}';
      badgeColor = Colors.orange.shade800;
    } else {
      badgeText = 'متوفر: ${product.quantity}';
      badgeColor = colorScheme.primary;
    }

    return GestureDetector(
      onLongPress: () {
        inventoryNotifier.enterSelectionMode(product.id);
      },
      onTap: () {
        if (isSelectionMode) {
          inventoryNotifier.toggleSelection(product.id);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: (product.imagePath != null &&
                            product.imagePath!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl:
                                githubService.getImageUrl(product.imagePath!),
                            httpHeaders: githubService.authHeaders,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (context, url, error) => const Center(
                                child: Icon(Symbols.broken_image,
                                    size: 48, color: Colors.grey)),
                          )
                        : const Center(
                            child:
                                Icon(Symbols.key, size: 48, color: Colors.grey)),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Chip(
                      label: Text(badgeText),
                      backgroundColor: badgeColor,
                      labelStyle: textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.1,
                      ),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if (isSelectionMode)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${product.sku}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${formatter.format(product.sellPriceIqd)} د.ع',
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(
                        height: 36,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                icon: const Icon(Symbols.shopping_cart,
                                    size: 20),
                                onPressed: isOutOfStock
                                    ? null
                                    : () => _showSaleDialog(context),
                                tooltip: 'بيع',
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  disabledBackgroundColor:
                                      colorScheme.onSurface.withAlpha(30),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        ProductFormScreen(product: product),
                                  ));
                                } else if (value == 'delete') {
                                  _deleteProduct(context);
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: ListTile(
                                      leading: Icon(Symbols.edit),
                                      title: Text('تعديل')),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: ListTile(
                                      leading: Icon(Symbols.delete),
                                      title: Text('حذف')),
                                ),
                              ],
                              icon: const Icon(Symbols.more_vert),
                              tooltip: 'المزيد',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}