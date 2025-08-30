import 'package:rhineix_workshop_app/src/models/product_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // We can define the types directly in the query for simplicity
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const nullableTextType = 'TEXT';
    const nullableIntegerType = 'INTEGER';
    const nullableRealType = 'REAL';

    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        sku $textType,
        quantity $nullableIntegerType,
        sellPriceIqd $nullableRealType,
        costPriceIqd $nullableRealType,
        imagePath $nullableTextType,
        categories $nullableTextType,
        alertLevel $nullableIntegerType,
        oemPartNumber $nullableTextType,
        compatiblePartNumber $nullableTextType,
        notes $nullableTextType
      )
    ''');
  }

  // --- Product CRUD Operations ---
  Future<void> batchUpdateProducts(List<Product> products) async {
    final db = await instance.database;
    final batch = db.batch();

    batch.delete('products');

    for (final product in products) {
      batch.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final maps = await db.query('products');
    if (maps.isEmpty) {
      return [];
    }
    return maps.map((json) => Product.fromMap(json)).toList();
  }
}