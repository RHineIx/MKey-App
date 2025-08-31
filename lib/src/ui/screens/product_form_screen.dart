// FILE: lib/src/ui/screens/product_form_screen.dart
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/models/supplier_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/settings_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/supplier_notifier.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/category_input.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.product != null;
  bool _isSaving = false;

  // Form Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _quantityController;
  late final TextEditingController _alertLevelController;
  late final TextEditingController _costPriceIqdController;
  late final TextEditingController _sellPriceIqdController;
  late final TextEditingController _costPriceUsdController;
  late final TextEditingController _sellPriceUsdController;
  late final TextEditingController _oemPartNumberController;
  late final TextEditingController _compatiblePartNumberController;
  late final TextEditingController _notesController;

  // Focus Nodes to prevent infinite loops during conversion
  final _costIqdFocus = FocusNode();
  final _costUsdFocus = FocusNode();
  final _sellIqdFocus = FocusNode();
  final _sellUsdFocus = FocusNode();

  File? _imageFile;
  Set<String> _selectedCategories = {};
  String? _selectedSupplierId;

  @override
    void initState() {
      super.initState();
      final p = widget.product;
      _nameController = TextEditingController(text: p?.name ?? '');
      _skuController = TextEditingController(text: p?.sku ?? 'KEY-${DateTime.now().millisecondsSinceEpoch}');
      _quantityController = TextEditingController(text: p?.quantity.toString() ?? '0');
      _alertLevelController = TextEditingController(text: p?.alertLevel.toString() ?? '2');
      _costPriceIqdController = TextEditingController(text: p?.costPriceIqd.toString() ?? '0.0');
      _sellPriceIqdController = TextEditingController(text: p?.sellPriceIqd.toString() ?? '0.0');
      _costPriceUsdController = TextEditingController(text: p?.costPriceUsd.toString() ?? '0.0');
      _sellPriceUsdController = TextEditingController(text: p?.sellPriceUsd.toString() ?? '0.0');
      _oemPartNumberController = TextEditingController(text: p?.oemPartNumber ?? '');
      _compatiblePartNumberController = TextEditingController(text: p?.compatiblePartNumber ?? '');
      _notesController = TextEditingController(text: p?.notes ?? '');
      _selectedCategories = p?.categories.toSet() ?? {};
      _selectedSupplierId = p?.supplierId;

      _costPriceIqdController.addListener(_convertCostIqdToUsd);
      _costPriceUsdController.addListener(_convertCostUsdToIqd);
      _sellPriceIqdController.addListener(_convertSellIqdToUsd);
      _sellPriceUsdController.addListener(_convertSellUsdToIqd);

      Future.microtask(() {
        if (mounted) {
          context.read<SupplierNotifier>().loadSuppliersFromDb();
        }
      });
    }

  void _convertCostIqdToUsd() {
    if (_costIqdFocus.hasFocus) {
      final exchangeRate = context.read<SettingsNotifier>().exchangeRate;
      if (exchangeRate == 0) return;
      final iqdValue = double.tryParse(_costPriceIqdController.text) ?? 0.0;
      final usdValue = (iqdValue / exchangeRate);
      _costPriceUsdController.text = usdValue.toStringAsFixed(2);
    }
  }

  void _convertCostUsdToIqd() {
    if (_costUsdFocus.hasFocus) {
      final exchangeRate = context.read<SettingsNotifier>().exchangeRate;
      final usdValue = double.tryParse(_costPriceUsdController.text) ?? 0.0;
      final iqdValue = (usdValue * exchangeRate);
      _costPriceIqdController.text = iqdValue.toStringAsFixed(0);
    }
  }

  void _convertSellIqdToUsd() {
    if (_sellIqdFocus.hasFocus) {
      final exchangeRate = context.read<SettingsNotifier>().exchangeRate;
      if (exchangeRate == 0) return;
      final iqdValue = double.tryParse(_sellPriceIqdController.text) ?? 0.0;
      final usdValue = (iqdValue / exchangeRate);
      _sellPriceUsdController.text = usdValue.toStringAsFixed(2);
    }
  }

  void _convertSellUsdToIqd() {
    if (_sellUsdFocus.hasFocus) {
      final exchangeRate = context.read<SettingsNotifier>().exchangeRate;
      final usdValue = double.tryParse(_sellPriceUsdController.text) ?? 0.0;
      final iqdValue = (usdValue * exchangeRate);
      _sellPriceIqdController.text = iqdValue.toStringAsFixed(0);
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    _alertLevelController.dispose();
    _costPriceIqdController.dispose();
    _sellPriceIqdController.dispose();
    _costPriceUsdController.dispose();
    _sellPriceUsdController.dispose();
    _oemPartNumberController.dispose();
    _compatiblePartNumberController.dispose();
    _notesController.dispose();
    _costIqdFocus.dispose();
    _costUsdFocus.dispose();
    _sellIqdFocus.dispose();
    _sellUsdFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!mounted) return;
    final picker = ImagePicker();
    final theme = Theme.of(context);

    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile == null) return;

    if (!mounted) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'اقتصاص الصورة',
            toolbarColor: theme.colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true),
        IOSUiSettings(
          title: 'اقتصاص الصورة',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile == null) return;

    setState(() {
      _imageFile = File(croppedFile.path);
    });
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    // It's good practice to check `mounted` before starting the async work too.
    if (!mounted) {
      setState(() => _isSaving = false);
      return;
    }

    final notifier = context.read<InventoryNotifier>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Create the productData object before the try-catch block
    final productData = Product(
      id: widget.product?.id ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      quantity: int.tryParse(_quantityController.text) ?? 0,
      alertLevel: int.tryParse(_alertLevelController.text) ?? 2,
      costPriceIqd: double.tryParse(_costPriceIqdController.text) ?? 0.0,
      sellPriceIqd: double.tryParse(_sellPriceIqdController.text) ?? 0.0,
      costPriceUsd: double.tryParse(_costPriceUsdController.text) ?? 0.0,
      sellPriceUsd: double.tryParse(_sellPriceUsdController.text) ?? 0.0,
      oemPartNumber: _oemPartNumberController.text.trim(),
      compatiblePartNumber: _compatiblePartNumberController.text.trim(),
      notes: _notesController.text.trim(),
      imagePath: widget.product?.imagePath,
      categories: _selectedCategories.toList(),
      supplierId: _selectedSupplierId,
    );

    try {
      if (_isEditing) {
        await notifier.updateProduct(productData, _imageFile);
      } else {
        await notifier.addProduct(productData, _imageFile);
      }

      // ADD THIS CHECK: If the widget was removed from the tree while saving, do nothing.
      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('تم الحفظ بنجاح!'), backgroundColor: Colors.green),
      );
      if (navigator.canPop()) {
        navigator.pop();
      }
    } catch (e) {
      // ADD THIS CHECK HERE TOO: For safety in the catch block.
      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('فشل الحفظ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل منتج' : 'إضافة منتج جديد'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white,)),
            )
          else
            IconButton(
              icon: const Icon(Symbols.save),
              onPressed: _submitForm,
              tooltip: 'حفظ',
            )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('صورة المنتج'),
            _buildImagePicker(),
            const SizedBox(height: 24),

            _buildSectionTitle('المعلومات الأساسية'),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم المنتج'),
              validator: (value) => value!.isEmpty ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _skuController,
              decoration: const InputDecoration(labelText: 'SKU (رقم المنتج)'),
              validator: (value) => value!.isEmpty ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _oemPartNumberController,
              decoration: const InputDecoration(labelText: 'رقم القطعة الأصلي (OEM)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _compatiblePartNumberController,
              decoration: const InputDecoration(labelText: 'أرقام القطع المتوافقة (بينها ,)'),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('الفئات'),
            CategoryInput(
              initialCategories: _selectedCategories,
              onChanged: (newCategories) {
                _selectedCategories = newCategories;
              },
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('المخزون والمورّد'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'الكمية'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _alertLevelController,
                    decoration: const InputDecoration(labelText: 'حد التنبيه'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<SupplierNotifier>(
              builder: (context, notifier, child) {
                final validSupplierIds = notifier.suppliers.map((s) => s.id).toSet();
                if (_selectedSupplierId != null && !validSupplierIds.contains(_selectedSupplierId)) {
                  _selectedSupplierId = null;
                }

                return DropdownButtonFormField<String>(
                  initialValue: _selectedSupplierId,
                  decoration: const InputDecoration(labelText: 'المورّد (اختياري)'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('-- اختر مورّد --'),
                    ),
                    ...notifier.suppliers.map((Supplier s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text(s.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSupplierId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('التسعير'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costPriceIqdController,
                    focusNode: _costIqdFocus,
                    decoration: const InputDecoration(labelText: 'التكلفة (دينار)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _costPriceUsdController,
                    focusNode: _costUsdFocus,
                    decoration: const InputDecoration(labelText: 'التكلفة (دولار)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sellPriceIqdController,
                    focusNode: _sellIqdFocus,
                    decoration: const InputDecoration(labelText: 'البيع (دينار)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _sellPriceUsdController,
                    focusNode: _sellUsdFocus,
                    decoration: const InputDecoration(labelText: 'البيع (دولار)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('ملاحظات'),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'ملاحظات إضافية'),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Column(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: _imageFile != null
                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                  : (widget.product?.imagePath != null && widget.product!.imagePath!.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: context.read<GithubService>().getImageUrl(widget.product!.imagePath!),
                httpHeaders: context.read<GithubService>().authHeaders,
                fit: BoxFit.cover,
                placeholder: (c, u) => const Center(child: CircularProgressIndicator()),
                errorWidget: (c, u, e) => const Icon(Symbols.broken_image, size: 64),
              )
                  : const Center(child: Icon(Symbols.key, size: 64))),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: const Icon(Symbols.photo_camera),
                label: const Text('الكاميرا'),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                icon: const Icon(Symbols.photo_library),
                label: const Text('المعرض'),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ],
          )
        ],
      ),
    );
  }
}