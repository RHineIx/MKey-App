import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/models/supplier_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/services/firestore_service.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/app_snackbar.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';

class SupplierNotifier extends ChangeNotifier {
  FirestoreService _firestoreService;
  StreamSubscription? _supplierSubscription;

  SupplierNotifier(this._firestoreService) {
    _listenToSuppliers();
  }

  void updateFirestoreService(FirestoreService firestoreService) {
    _firestoreService = firestoreService;
    _supplierSubscription?.cancel();
    _listenToSuppliers();
  }

  bool _isLoading = true;
  List<Supplier> _suppliers = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<Supplier> get suppliers => _suppliers;
  String?
  get error => _error;

  void _listenToSuppliers() {
    if (!_firestoreService.isReady) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    _supplierSubscription = _firestoreService.getSuppliersStream().listen((suppliers) {
      _suppliers = suppliers..sort((a, b) => a.name.compareTo(b.name));
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _error = "فشل تحميل المورّدين: $e";
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addSupplier(String name, String? phone) async {
    if (!_firestoreService.isReady) return;
    final newSupplier = Supplier(
      id: 'sup_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
    );
    await _firestoreService.setSupplier(newSupplier);
  }

  Future<void> updateSupplier(String id, String name, String? phone) async {
    if (!_firestoreService.isReady) return;
    final updatedSupplier = Supplier(id: id, name: name, phone: phone);
    await _firestoreService.setSupplier(updatedSupplier);
  }

  Future<void> deleteSupplier(BuildContext context, String id) async {
    if (!_firestoreService.isReady) return;

    final inventoryNotifier = context.read<InventoryNotifier>();
    final linkedProducts = inventoryNotifier.allProducts.where((p) => p.supplierId == id).toList();
    
    for (final product in linkedProducts) {
      final updatedProduct = Product(
        id: product.id, name: product.name, sku: product.sku, quantity: product.quantity,
        alertLevel: product.alertLevel, costPriceIqd: product.costPriceIqd, sellPriceIqd: product.sellPriceIqd,
        costPriceUsd: product.costPriceUsd, sellPriceUsd: product.sellPriceUsd, notes: product.notes,
        imagePath: product.imagePath, categories: product.categories, oemPartNumber: product.oemPartNumber,
        compatiblePartNumber: product.compatiblePartNumber, supplierId: null,
      );
      await inventoryNotifier.updateProduct(updatedProduct, null, originalProduct: product);
    }

    await _firestoreService.deleteSupplier(id);

    if (context.mounted) {
       showAppSnackBar(context,
            message: 'تم الحذف بنجاح', type: NotificationType.success);
    }
  }

  Supplier?
  getSupplierById(String? id) {
    if (id == null) return null;
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _supplierSubscription?.cancel();
    super.dispose();
  }
}