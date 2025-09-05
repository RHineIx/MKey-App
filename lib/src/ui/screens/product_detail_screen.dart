import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/models/supplier_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/supplier_notifier.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';
import 'package:rhineix_mkey_app/src/ui/screens/product_form_screen.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/app_snackbar.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/confirmation_dialog.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/quantity_reason_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int _currentQuantity;
  late final TextEditingController _quantityController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentQuantity = widget.product.quantity;
    _quantityController = TextEditingController(text: _currentQuantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  bool get _hasChanges => _currentQuantity != widget.product.quantity;

  Future<void> _saveQuantityChanges() async {
    if (!_hasChanges || _isSaving) return;

    final reason = await showQuantityReasonDialog(context);
    if (reason == null || !mounted) return;

    setState(() => _isSaving = true);
    final notifier = context.read<InventoryNotifier>();
    final navigator = Navigator.of(context);

    try {
      await notifier.updateProductQuantity(
        productId: widget.product.id,
        newQuantity: _currentQuantity,
        reason: reason,
      );

      if (!mounted) return;
      showAppSnackBar(context, message: 'تم تحديث الكمية بنجاح', type: NotificationType.success);
      navigator.pop();

    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: 'فشل تحديث الكمية: $e', type: NotificationType.error);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildPartNumberChip(BuildContext context, String partNumber) {
    return ActionChip(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: partNumber));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم نسخ الرقم: $partNumber')),
        );
      },
      label: Text(partNumber,
          style: const TextStyle(
              fontFamily: 'RobotoMono', letterSpacing: 0.8, height: 1.2)),
      avatar: const Icon(Symbols.content_copy, size: 16, weight: 700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: Theme.of(context).dividerColor),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildSection(
      {required String title, required Widget content, bool isVisible = true}) {
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

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      showAppSnackBar(context, message: 'تعذر فتح الرابط: $url', type: NotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat('#,###', 'ar_IQ');
    final githubService = Provider.of<GithubService>(context, listen: false);
    final cacheManager = Provider.of<CacheManager>(context, listen: false);

    final compatibleParts = widget.product.compatiblePartNumber
        ?.split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList() ??
        [];

    final supplier = widget.product.supplierId != null
        ? Provider.of<SupplierNotifier>(context, listen: false)
        .getSupplierById(widget.product.supplierId!)
        : null;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await showConfirmationDialog(
          context: context,
          title: 'تجاهل التغييرات؟',
          content: 'لقد قمت بتعديل الكمية. هل تريد تجاهل هذه التغييرات؟',
          confirmText: 'تجاهل',
          isDestructive: true,
          icon: Symbols.warning,
        );
        if (discard == true) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.product.name),
          actions: [
            IconButton(
              icon: const Icon(Symbols.edit, weight: 700),
              tooltip: 'تعديل المنتج',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ProductFormScreen(product: widget.product),
                ));
              },
            )
          ],
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
                  child: (widget.product.imagePath != null && widget.product.imagePath!.isNotEmpty)
                      ? CachedNetworkImage(
                    cacheManager: cacheManager,
                    imageUrl: githubService.getImageUrl(widget.product.imagePath!),
                    httpHeaders: githubService.authHeaders,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(
                        child: Icon(Symbols.broken_image, size: 64, weight: 700)),
                  )
                      : Icon(Symbols.inventory_2, size: 64, color: colorScheme.onSurface.withAlpha(128), weight: 700),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.product.name, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'SKU: ${widget.product.sku}',
                style: textTheme.bodyLarge?.copyWith(color: textTheme.bodySmall?.color),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 8),
              if (widget.product.categories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: widget.product.categories.map((category) => Chip(label: Text(category))).toList(),
                  ),
                ),
              const Divider(height: 32),
              _buildSection(
                title: 'أرقام القطع',
                isVisible: (widget.product.oemPartNumber?.isNotEmpty ?? false) || compatibleParts.isNotEmpty,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product.oemPartNumber?.isNotEmpty ?? false) ...[
                      const Text('رقم القطعة الأصلي (OEM):'),
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerLeft, child: _buildPartNumberChip(context, widget.product.oemPartNumber!)),
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
                ),
              ),
              _buildSection(
                title: 'التسعير والمخزون',
                content: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        _PriceRow(label: 'سعر التكلفة:', value: widget.product.costPriceIqd, formatter: formatter, style: textTheme.bodyLarge),
                        _PriceRow(label: 'سعر البيع:', value: widget.product.sellPriceIqd, formatter: formatter, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Text('الكمية المتوفرة:'),
                            const Spacer(),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Symbols.remove),
                                  onPressed: () {
                                    if (_currentQuantity > 0) {
                                      setState(() {
                                        _currentQuantity--;
                                        _quantityController.text = _currentQuantity.toString();
                                      });
                                    }
                                  },
                                ),
                                SizedBox(
                                  width: 50,
                                  child: TextFormField(
                                    controller: _quantityController,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    onChanged: (value) {
                                      setState(() {
                                        _currentQuantity = int.tryParse(value) ?? 0;
                                      });
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Symbols.add),
                                  onPressed: () {
                                    setState(() {
                                      _currentQuantity++;
                                      _quantityController.text = _currentQuantity.toString();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (supplier != null)
                _buildSection(
                    title: 'معلومات المورّد',
                    content: _SupplierInfo(supplier: supplier, onLaunch: _launchUrl)
                ),
              _buildSection(
                title: 'ملاحظات',
                isVisible: widget.product.notes?.trim().isNotEmpty ?? false,
                content: Text(_stripHtmlIfNeeded(widget.product.notes!), style: textTheme.bodyLarge),
              ),
            ],
          ),
        ),
        floatingActionButton: _hasChanges
            ? FloatingActionButton.extended(
          onPressed: _isSaving ? null : _saveQuantityChanges,
          label: const Text('حفظ تغيير الكمية'),
          icon: _isSaving
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
              : const Icon(Symbols.save),
        )
            : null,
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, required this.formatter, this.style});

  final String label;
  final double value;
  final NumberFormat formatter;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text('${formatter.format(value)} د.ع', style: style),
        ],
      ),
    );
  }
}

class _SupplierInfo extends StatelessWidget {
  final Supplier supplier;
  final Function(Uri) onLaunch;
  const _SupplierInfo({required this.supplier, required this.onLaunch});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(supplier.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
              const Divider(),
              Text(supplier.phone!, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Symbols.call, weight: 700),
                      label: const Text('اتصال'),
                      onPressed: () => onLaunch(Uri.parse('tel:${supplier.phone}')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Symbols.sms, weight: 700),
                      label: const Text('واتساب'),
                      onPressed: () => onLaunch(Uri.parse('https://wa.me/${supplier.phone}')),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                    ),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}