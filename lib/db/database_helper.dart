import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sales_buddy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      code TEXT,
      buying_price REAL NOT NULL, 
      selling_price REAL NOT NULL,
      stock INTEGER NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      shop_name TEXT NOT NULL,
      date TEXT NOT NULL,
      total_amount REAL NOT NULL,
      discount REAL NOT NULL,
      net_profit REAL NOT NULL 
    )
    ''');

    await db.execute('''
    CREATE TABLE sale_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      price_per_unit REAL NOT NULL,
      FOREIGN KEY (sale_id) REFERENCES sales (id)
    )
    ''');
  }

  Future<int> addProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('products', row);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'name ASC');
  }

  Future<int> addSale(
    Map<String, dynamic> saleRow,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      int saleId = await txn.insert('sales', saleRow);

      for (var item in items) {
        int productId = item['product_id'];
        int qty = item['quantity'];

        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [qty, productId],
        );

        Map<String, dynamic> itemToInsert = {
          'sale_id': saleId,
          'product_name': item['product_name'],
          'quantity': item['quantity'],
          'price_per_unit': item['price_per_unit']
        };

        await txn.insert('sale_items', itemToInsert);
      }
      return saleId;
    });
  }

  Future<List<Map<String, dynamic>>> getAllSales() async {
    final db = await instance.database;
    return await db.query('sales', orderBy: 'date DESC');
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getSaleItems(int saleId) async {
    final db = await instance.database;
    return await db.query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
  }

  Future<void> deleteSale(int saleId) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
      await txn.delete('sales', where: 'id = ?', whereArgs: [saleId]);
    });
  }
}