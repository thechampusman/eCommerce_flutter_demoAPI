import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductsApiService {
  static const String baseUrl = 'https://dummyjson.com';

  
  static Future<ProductsResponse> getProducts({
    int limit = 30,
    int skip = 0,
    String? sortBy,
    String? order,
  }) async {
    try {
      String url = '$baseUrl/products?limit=$limit&skip=$skip';

      if (sortBy != null) {
        url += '&sortBy=$sortBy';
      }

      if (order != null) {
        url += '&order=$order';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProductsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  
  static Future<Product> getProduct(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Product.fromJson(data);
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  
  static Future<ProductsResponse> searchProducts({
    required String query,
    int limit = 30,
    int skip = 0,
    String? sortBy,
    String? order,
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      var url =
          '$baseUrl/products/search?q=$encodedQuery&limit=$limit&skip=$skip';

      
      if (sortBy != null && sortBy.isNotEmpty) {
        url += '&sortBy=$sortBy';
        if (order != null && order.isNotEmpty) {
          url += '&order=$order';
        }
      }

      print('🌐 API Request: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProductsResponse.fromJson(data);
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  
  static Future<ProductsResponse> getProductsByCategory({
    required String category,
    int limit = 30,
    int skip = 0,
  }) async {
    try {
      final url =
          '$baseUrl/products/category/$category?limit=$limit&skip=$skip';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProductsResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load category products: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  
  static Future<List<ProductCategory>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/categories'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data
            .map((category) => ProductCategory.fromJson(category))
            .toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  
  static Future<List<String>> getCategoryList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/category-list'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.cast<String>();
      } else {
        throw Exception('Failed to load category list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  
  static Future<List<Product>> getFilteredProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
    String? order,
    int limit = 100, 
  }) async {
    try {
      ProductsResponse response;

      if (category != null && category.isNotEmpty) {
        response = await getProductsByCategory(
          category: category,
          limit: limit,
        );
      } else {
        response = await getProducts(
          limit: limit,
          sortBy: sortBy,
          order: order,
        );
      }

      List<Product> filteredProducts = response.products;

      
      if (minPrice != null) {
        filteredProducts = filteredProducts
            .where((product) => product.discountedPrice >= minPrice)
            .toList();
      }

      if (maxPrice != null) {
        filteredProducts = filteredProducts
            .where((product) => product.discountedPrice <= maxPrice)
            .toList();
      }

      
      if (minRating != null) {
        filteredProducts = filteredProducts
            .where((product) => product.rating >= minRating)
            .toList();
      }

      
      if (sortBy != null && category != null) {
        filteredProducts.sort((a, b) {
          switch (sortBy) {
            case 'price':
              final comparison = a.discountedPrice.compareTo(b.discountedPrice);
              return order == 'desc' ? -comparison : comparison;
            case 'rating':
              final comparison = a.rating.compareTo(b.rating);
              return order == 'desc' ? -comparison : comparison;
            case 'title':
              final comparison = a.title.compareTo(b.title);
              return order == 'desc' ? -comparison : comparison;
            default:
              return 0;
          }
        });
      }

      return filteredProducts;
    } catch (e) {
      throw Exception('Failed to get filtered products: $e');
    }
  }
}
