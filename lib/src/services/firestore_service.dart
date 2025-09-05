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

  // FIXED: Renamed from _userDocRef to userDocRef to make it public
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

  // ACTIVITY LOG
  Stream<List<ActivityLog>> getActivityLogsStream() {
    if (!isReady) return Stream.value([]);
    return userDocRef!
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ActivityLog.fromJson(doc.data())).toList();
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
    final snapshot = await userDocRef!.collection('activity_logs').get();
    WriteBatch batch = _firestore!.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> saveUserFCMToken(String token) async {
    if (!isReady) return;
    await userDocRef!.set({'fcmToken': token}, SetOptions(merge: true));
  }
}