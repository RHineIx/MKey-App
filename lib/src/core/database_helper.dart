// FILE: lib/src/core/database_helper.dart
import 'package:path/path.dart';
import 'package:rhineix_mkey_app/src/models/activity_log_model.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';
import 'package:rhineix_mkey_app/src/models/supplier_model.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const nullableTextType = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const nullableIntegerType = 'INTEGER';
    const realType = 'REAL NOT NULL';
    const nullableRealType = 'REAL';

    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        sku $textType,
        quantity $nullableIntegerType,
        alertLevel $nullableIntegerType,
        costPriceIqd $nullableRealType,
        sellPriceIqd $nullableRealType,
        costPriceUsd $nullableRealType,
        sellPriceUsd $nullableRealType,
        imagePath $nullableTextType,
        categories $nullableTextType,
        oemPartNumber $nullableTextType,
        compatiblePartNumber $nullableTextType,
        notes $nullableTextType,
        supplierId $nullableTextType
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        saleId $idType,
        itemId $textType,
        itemName $textType,
        quantitySold $integerType,
        sellPriceIqd $realType,
        costPriceIqd $realType,
        sellPriceUsd $realType,
        costPriceUsd $realType,
        saleDate $textType,
        notes $nullableTextType,
        timestamp $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id $idType,
        name $textType,
        phone $nullableTextType
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_logs (
        id $idType,
        timestamp $textType,
        user $textType,
        action $textType,
        targetId $textType,
        targetName $textType,
        details $textType
      )
    ''');
  }

  // --- Product Operations ---
  Future<void> batchUpdateProducts(List<Product> products) async {
    final db = await instance.database;
    final batch = db.batch();
    batch.delete('products');
    for (final product in products) {
      batch.insert('products', product.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final maps = await db.query('products');
    if (maps.isEmpty) return [];
    return maps.map((json) => Product.fromMap(json)).toList();
  }

  // --- Sales Operations ---
  Future<void> batchUpdateSales(List<Sale> sales) async {
    final db = await instance.database;
    final batch = db.batch();
    batch.delete('sales');
    for (final sale in sales) {
      batch.insert('sales', sale.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Sale>> getAllSales() async {
    final db = await instance.database;
    final maps = await db.query('sales', orderBy: 'timestamp DESC');
    if (maps.isEmpty) return [];
    return maps.map((json) => Sale.fromMap(json)).toList();
  }

  // --- Supplier Operations ---
  Future<void> batchUpdateSuppliers(List<Supplier> suppliers) async {
    final db = await instance.database;
    final batch = db.batch();
    batch.delete('suppliers');
    for (final supplier in suppliers) {
      batch.insert('suppliers', supplier.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await instance.database;
    final maps = await db.query('suppliers', orderBy: 'name ASC');
    if (maps.isEmpty) return [];
    return maps.map((json) => Supplier.fromMap(json)).toList();
  }

  // --- Activity Log Operations ---
  Future<void> batchUpdateActivityLogs(List<ActivityLog> logs) async {
    final db = await instance.database;
    final batch = db.batch();
    batch.delete('activity_logs');
    for (final log in logs) {
      batch.insert('activity_logs', log.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<ActivityLog>> getAllActivityLogs() async {
    final db = await instance.database;
    final maps = await db.query('activity_logs', orderBy: 'timestamp DESC');
    if (maps.isEmpty) return [];
    return maps.map((json) => ActivityLog.fromMap(json)).toList();
  }
}