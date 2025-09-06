import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rhineix_mkey_app/src/models/activity_log_model.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';
import 'package:rhineix_mkey_app/src/models/supplier_model.dart';

class FirestoreService extends ChangeNotifier {
  final String? uid;
  FirebaseFirestore? _firestore;

  FirestoreService(this.uid) {
    if (uid != null) {
      _firestore = FirebaseFirestore.instance;
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  }

  bool get isReady => uid != null && _firestore != null;

  DocumentReference? get userDocRef =>
      isReady ? _firestore!.collection('users').doc(uid) : null;

  // PRODUCTS
  Stream<List<Product>> getProductsStream() {
    if (!isReady) return Stream.value([]);
    return userDocRef!.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromJson(doc.data())).toList();
    });
  }

  Future<void> setProduct(Product product) async {
    if (!isReady) throw Exception("User not authenticated.");
    await userDocRef!
        .collection('products')
        .doc(product.id)
        .set(product.toMapForJson());
  }

  Future<void> deleteProduct(String productId) async {
    if (!isReady) throw Exception("User not authenticated.");
    await userDocRef!.collection('products').doc(productId).delete();
  }

  // SUPPLIERS
  Stream<List<Supplier>> getSuppliersStream() {
    if (!isReady) return Stream.value([]);
    return userDocRef!.collection('suppliers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Supplier.fromJson(doc.data())).toList();
    });
  }

  Future<void> setSupplier(Supplier supplier) async {
    if (!isReady) throw Exception("User not authenticated.");
    await userDocRef!
        .collection('suppliers')
        .doc(supplier.id)
        .set(supplier.toMap());
  }

  Future<void> deleteSupplier(String supplierId) async {
    if (!isReady) throw Exception("User not authenticated.");
    await userDocRef!.collection('suppliers').doc(supplierId).delete();
  }

  // SALES
  Stream<List<Sale>> getSalesStream() {
    if (!isReady) return Stream.value([]);
    return userDocRef!
        .collection('sales')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Sale.fromJson(doc.data())).toList();
    });
  }

  Future<void> addSale(Sale sale) async {
    if (!isReady) throw Exception("User not authenticated.");
    await userDocRef!.collection('sales').doc(sale.saleId).set(sale.toMap());
  }

  Future<void> deleteSale(String saleId) async {
    if (!isReady) throw Exception("User not authenticated.");
    await userDocRef!.collection('sales').doc(saleId).delete();
  }

  Future<void> deleteSalesBatch(List<Sale> sales) async {
    if (!isReady) throw Exception("User not authenticated.");
    WriteBatch batch = _firestore!.batch();
    for (final sale in sales) {
      final docRef = userDocRef!.collection('sales').doc(sale.saleId);
      batch.delete(docRef);
    }
    await batch.commit();
  }

  // ACTIVITY LOG
  Stream<List<ActivityLog>> getActivityLogsStream() {
    if (!isReady) return Stream.value([]);
    return userDocRef!
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityLog.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> addActivityLog(ActivityLog log) async {
    if (!isReady) throw Exception("User not authenticated.");
    await userDocRef!
        .collection('activity_logs')
        .doc(log.id)
        .set(log.toMap());
  }

  Future<void> clearActivityLogs() async {
    if (!isReady) throw Exception("User not authenticated.");
    await _clearCollection('activity_logs');
  }

  Future<void> saveUserFCMToken(String token) async {
    if (!isReady) return;
    await userDocRef!.set({'fcmToken': token}, SetOptions(merge: true));
  }

  // BACKUP & RESTORE
  Future<void> _clearCollection(String collectionPath) async {
    final collection = userDocRef!.collection(collectionPath);
    final snapshot = await collection.limit(500).get();
    if (snapshot.docs.isEmpty) return;

    WriteBatch batch = _firestore!.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    if (snapshot.docs.length == 500) {
      await _clearCollection(collectionPath);
    }
  }

  Future<void> performRestore({
    required List<Product> products,
    required List<Sale> sales,
    required List<Supplier> suppliers,
    required List<ActivityLog> activityLogs,
  }) async {
    if (!isReady) throw Exception("User not authenticated.");

    await _clearCollection('products');
    await _clearCollection('sales');
    await _clearCollection('suppliers');
    await _clearCollection('activity_logs');

    WriteBatch batch = _firestore!.batch();
    int count = 0;

    for (final product in products) {
      final docRef = userDocRef!.collection('products').doc(product.id);
      batch.set(docRef, product.toMapForJson());
      if (++count % 500 == 0) { await batch.commit(); batch = _firestore!.batch(); }
    }
    for (final sale in sales) {
      final docRef = userDocRef!.collection('sales').doc(sale.saleId);
      batch.set(docRef, sale.toMap());
      if (++count % 500 == 0) { await batch.commit(); batch = _firestore!.batch(); }
    }
    for (final supplier in suppliers) {
      final docRef = userDocRef!.collection('suppliers').doc(supplier.id);
      batch.set(docRef, supplier.toMap());
      if (++count % 500 == 0) { await batch.commit(); batch = _firestore!.batch(); }
    }
    for (final log in activityLogs) {
      final docRef = userDocRef!.collection('activity_logs').doc(log.id);
      batch.set(docRef, log.toMap());
      if (++count % 500 == 0) { await batch.commit(); batch = _firestore!.batch(); }
    }

    await batch.commit();
  }
}