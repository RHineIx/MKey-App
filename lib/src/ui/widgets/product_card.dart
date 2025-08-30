// FILE: lib/src/ui/widgets/product_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';
import 'package:rhineix_mkey_app/src/ui/screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'ar_IQ');
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final githubService = Provider.of<GithubService>(context, listen: false);

    final bool isOutOfStock = product.quantity <= 0;
    final bool isLowStock = !isOutOfStock && product.quantity <= product.alertLevel;

    final String badgeText;
    final Color badgeColor;

    if (isOutOfStock) {
      badgeText = 'نفد المخزون';
      badgeColor = colorScheme.error;
    } else if (isLowStock) {
      badgeText = 'منخفض: ${product.quantity}';
      badgeColor = Colors.orange.shade700;
    } else {
      badgeText = 'متوفر: ${product.quantity}';
      badgeColor = colorScheme.primary;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (product.imagePath != null && product.imagePath!.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: githubService.getImageUrl(product.imagePath!),
                    httpHeaders: githubService.authHeaders,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(
                        child: Icon(Symbols.broken_image, size: 48)),
                  )
                      : Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(
                        child: Icon(Symbols.inventory_2, size: 48)),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Chip(
                      label: Text(badgeText),
                      backgroundColor: badgeColor,
                      labelStyle: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onError,
                          fontWeight: FontWeight.bold),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('SKU: ${product.sku}', style: textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${formatter.format(product.sellPriceIqd)} د.ع',
                        style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              icon: const Icon(Symbols.shopping_cart, size: 20),
                              onPressed: isOutOfStock
                                  ? null
                                  : () {
                                // TODO: Implement Sell Action
                              },
                              tooltip: 'بيع',
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                disabledBackgroundColor:
                                colorScheme.onSurface.withAlpha(30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Symbols.more_vert),
                            onPressed: () {
                              // TODO: Implement More Actions Menu (Edit, Delete)
                            },
                            tooltip: 'المزيد',
                          ),
                        ],
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