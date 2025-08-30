import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_workshop_app/src/models/product_model.dart';
import 'package:rhineix_workshop_app/src/services/github_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  Widget _buildPartNumberChip(BuildContext context, String partNumber) {
    return ActionChip(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: partNumber));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم نسخ الرقم: $partNumber')),
        );
      },
      label: Text(partNumber, style: const TextStyle(fontFamily: 'RobotoMono', letterSpacing: 0.8)),
      avatar: const Icon(Symbols.content_copy, size: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: Theme.of(context).dividerColor),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildSection({required String title, required Widget content, bool isVisible = true}) {
    if (!isVisible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  String _stripHtmlIfNeeded(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat('#,###', 'ar_IQ');
    final githubService = Provider.of<GithubService>(context, listen: false);

    final List<String> compatibleParts = product.compatiblePartNumber
        ?.split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1 / 1,
                child: (product.imagePath != null && product.imagePath!.isNotEmpty)
                    ? CachedNetworkImage(
                  imageUrl: githubService.getImageUrl(product.imagePath!),
                  httpHeaders: githubService.authHeaders,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Center(child: Icon(Symbols.broken_image, size: 64)),
                )
                    : Icon(Symbols.inventory_2, size: 64, color: colorScheme.onSurface.withAlpha(128)),
              ),
            ),
            const SizedBox(height: 16),
            Text(product.name, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Corrected: Add textDirection directly to the Text widget
            Text(
              'SKU: ${product.sku}',
              style: textTheme.bodyLarge?.copyWith(color: textTheme.bodySmall?.color),
              textDirection: TextDirection.ltr,
            ),

            const SizedBox(height: 8),
            if (product.categories != null && product.categories!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: product.categories!.map((category) => Chip(label: Text(category))).toList(),
                ),
              ),
            const Divider(height: 32),
            _buildSection(
                title: 'أرقام القطع',
                isVisible: (product.oemPartNumber?.isNotEmpty ?? false) || compatibleParts.isNotEmpty,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.oemPartNumber?.isNotEmpty ?? false) ...[
                      const Text('رقم القطعة الأصلي (OEM):'),
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerLeft, child: _buildPartNumberChip(context, product.oemPartNumber!)),
                    ],
                    if (compatibleParts.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('أرقام القطع المتوافقة:'),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(spacing: 8.0, runSpacing: 8.0, children: compatibleParts.map((p) => _buildPartNumberChip(context, p)).toList()),
                      ),
                    ],
                  ],
                )
            ),
            _buildSection(
                title: 'التسعير والمخزون',
                content: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('سعر التكلفة:'),
                            const Spacer(),
                            Text('${formatter.format(product.costPriceIqd ?? 0)} د.ع', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('سعر البيع:'),
                            const Spacer(),
                            Text('${formatter.format(product.sellPriceIqd ?? 0)} د.ع', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Text('الكمية المتوفرة:'),
                            const Spacer(),
                            Text('${product.quantity ?? 0}', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
            ),
            _buildSection(
              title: 'ملاحظات',
              isVisible: product.notes?.trim().isNotEmpty ?? false,
              content: Text(_stripHtmlIfNeeded(product.notes ?? ''), style: textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}