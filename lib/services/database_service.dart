import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/cart_wishlist.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'ecommerce.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        data TEXT NOT NULL,
        category TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    
    await db.execute('''
      CREATE TABLE categories (
        slug TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    
    await db.execute('''
      CREATE TABLE cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        product_data TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    
    await db.execute('''
      CREATE TABLE wishlist (
        product_id INTEGER PRIMARY KEY,
        product_data TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    
    await db.execute('''
      CREATE TABLE search_cache (
        query TEXT PRIMARY KEY,
        results TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  
  Future<void> cacheProducts(List<Product> products, {String? category}) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final product in products) {
      batch.insert('products', {
        'id': product.id,
        'data': json.encode(product.toJson()),
        'category': category ?? product.category,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit();
  }

  Future<List<Product>> getCachedProducts({
    String? category,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    String query = 'SELECT data FROM products';
    List<dynamic> args = [];

    if (category != null) {
      query += ' WHERE category = ?';
      args.add(category);
    }

    query += ' ORDER BY created_at DESC';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
      if (offset != null) {
        query += ' OFFSET ?';
        args.add(offset);
      }
    }

    final result = await db.rawQuery(query, args);
    return result.map((row) {
      final productData = json.decode(row['data'] as String);
      return Product.fromJson(productData);
    }).toList();
  }

  Future<Product?> getCachedProduct(int productId) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final productData = json.decode(result.first['data'] as String);
    return Product.fromJson(productData);
  }

  Future<List<Product>> searchCachedProducts(String query) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT data FROM products 
      WHERE data LIKE ? OR data LIKE ?
      ORDER BY created_at DESC
    ''',
      ['%${query.toLowerCase()}%', '%${query.toUpperCase()}%'],
    );

    return result.map((row) {
      final productData = json.decode(row['data'] as String);
      return Product.fromJson(productData);
    }).toList();
  }

  
  Future<void> cacheCategories(List<ProductCategory> categories) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final category in categories) {
      batch.insert('categories', {
        'slug': category.slug,
        'name': category.name,
        'url': category.url,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit();
  }

  Future<List<ProductCategory>> getCachedCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'name ASC');

    return result
        .map(
          (row) => ProductCategory(
            slug: row['slug'] as String,
            name: row['name'] as String,
            url: row['url'] as String,
          ),
        )
        .toList();
  }

  
  Future<void> saveCart(Cart cart) async {
    final db = await database;
    await db.delete('cart');

    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final item in cart.items) {
      batch.insert('cart', {
        'product_id': item.product.id,
        'quantity': item.quantity,
        'product_data': json.encode(item.product.toJson()),
        'created_at': now,
      });
    }

    await batch.commit();
  }

  Future<Cart> getCart() async {
    final db = await database;
    final result = await db.query('cart', orderBy: 'created_at ASC');

    final items = result.map((row) {
      final productData = json.decode(row['product_data'] as String);
      final product = Product.fromJson(productData);
      return CartItem(product: product, quantity: row['quantity'] as int);
    }).toList();

    return Cart(items: items);
  }

  
  Future<void> saveWishlist(Wishlist wishlist) async {
    final db = await database;
    await db.delete('wishlist');

    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final product in wishlist.products) {
      batch.insert('wishlist', {
        'product_id': product.id,
        'product_data': json.encode(product.toJson()),
        'created_at': now,
      });
    }

    await batch.commit();
  }

  Future<Wishlist> getWishlist() async {
    final db = await database;
    final result = await db.query('wishlist', orderBy: 'created_at DESC');

    final products = result.map((row) {
      final productData = json.decode(row['product_data'] as String);
      return Product.fromJson(productData);
    }).toList();

    return Wishlist(products: products);
  }

  
  Future<void> cacheSearchResults(String query, List<Product> products) async {
    final db = await database;
    await db.insert('search_cache', {
      'query': query.toLowerCase(),
      'results': json.encode(products.map((p) => p.toJson()).toList()),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>?> getCachedSearchResults(String query) async {
    final db = await database;
    final result = await db.query(
      'search_cache',
      where: 'query = ?',
      whereArgs: [query.toLowerCase()],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final resultsData = json.decode(result.first['results'] as String) as List;
    return resultsData.map((data) => Product.fromJson(data)).toList();
  }

  
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('products');
    await db.delete('categories');
    await db.delete('search_cache');
  }

  
  Future<void> clearCart() async {
    final db = await database;
    await db.delete('cart');
  }

  
  Future<void> clearWishlist() async {
    final db = await database;
    await db.delete('wishlist');
  }

  
  Future<void> clearOldCache({int maxAgeInHours = 24}) async {
    final db = await database;
    final cutoffTime = DateTime.now()
        .subtract(Duration(hours: maxAgeInHours))
        .millisecondsSinceEpoch;

    await db.delete(
      'products',
      where: 'created_at < ?',
      whereArgs: [cutoffTime],
    );
    await db.delete(
      'categories',
      where: 'created_at < ?',
      whereArgs: [cutoffTime],
    );
    await db.delete(
      'search_cache',
      where: 'created_at < ?',
      whereArgs: [cutoffTime],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
