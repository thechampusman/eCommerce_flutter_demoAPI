import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_wishlist.dart';
import '../models/product.dart';

class CartApiService {
  static const String baseUrl = 'https://dummyjson.com/carts';

  
  static Future<List<Cart>> getAllCarts({int limit = 30, int skip = 0}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl?limit=$limit&skip=$skip'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> cartsData = data['carts'] ?? [];

        return cartsData
            .map((cartJson) => _parseCartFromApi(cartJson))
            .toList();
      } else {
        throw Exception('Failed to fetch carts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching carts: $e');
    }
  }

  
  static Future<Cart> getCartById(int cartId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/$cartId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final cartData = json.decode(response.body);
        return _parseCartFromApi(cartData);
      } else {
        throw Exception('Failed to fetch cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching cart: $e');
    }
  }

  
  static Future<List<Cart>> getCartsByUserId(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/user/$userId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> cartsData = data['carts'] ?? [];

        return cartsData
            .map((cartJson) => _parseCartFromApi(cartJson))
            .toList();
      } else {
        throw Exception('Failed to fetch user carts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user carts: $e');
    }
  }

  
  static Future<Cart> addCart({
    required int userId,
    required List<CartItem> items,
  }) async {
    try {
      final products = items
          .map((item) => {'id': item.product.id, 'quantity': item.quantity})
          .toList();

      final response = await http
          .post(
            Uri.parse('$baseUrl/add'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'userId': userId, 'products': products}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final cartData = json.decode(response.body);
        return _parseCartFromApi(cartData);
      } else {
        throw Exception('Failed to add cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding cart: $e');
    }
  }

  
  static Future<Cart> updateCart({
    required int cartId,
    required List<CartItem> items,
    bool merge = true,
  }) async {
    try {
      final products = items
          .map((item) => {'id': item.product.id, 'quantity': item.quantity})
          .toList();

      final response = await http
          .put(
            Uri.parse('$baseUrl/$cartId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'merge': merge, 'products': products}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final cartData = json.decode(response.body);
        return _parseCartFromApi(cartData);
      } else {
        throw Exception('Failed to update cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating cart: $e');
    }
  }

  
  static Future<Map<String, dynamic>> deleteCart(int cartId) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/$cartId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting cart: $e');
    }
  }

  
  static Cart _parseCartFromApi(Map<String, dynamic> cartData) {
    final List<dynamic> productsData = cartData['products'] ?? [];

    final cartItems = productsData.map((productData) {
      
      final product = Product(
        id: productData['id'] ?? 0,
        title: productData['title'] ?? '',
        description:
            productData['title'] ??
            '', 
        category: '', 
        price: (productData['price'] ?? 0.0).toDouble(),
        discountPercentage: (productData['discountPercentage'] ?? 0.0)
            .toDouble(),
        rating: 4.5, 
        stock: 100, 
        tags: const [], 
        brand: '', 
        sku: '', 
        weight: 0.0, 
        dimensions: const ProductDimensions(width: 0, height: 0, depth: 0),
        warrantyInformation: '',
        shippingInformation: '',
        availabilityStatus: 'In Stock',
        reviews: const [],
        returnPolicy: '',
        minimumOrderQuantity: 1,
        meta: ProductMeta(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          barcode: '',
          qrCode: '',
        ),
        thumbnail: productData['thumbnail'] ?? '',
        images: [
          productData['thumbnail'] ?? '',
        ], 
      );

      return CartItem(product: product, quantity: productData['quantity'] ?? 1);
    }).toList();

    return Cart(items: cartItems);
  }
}
