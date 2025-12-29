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
        item['sale_id'] = saleId;
        await txn.insert('sale_items', item);
      }
      return saleId;
    });
  }

  Future<List<Map<String, dynamic>>> getAllSales() async {
    final db = await instance.database;
    return await db.query('sales', orderBy: 'date DESC');
  }
}
