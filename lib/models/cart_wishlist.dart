import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {'product': product.toJson(), 'quantity': quantity};
  }

  double get totalPrice => product.discountedPrice * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object> get props => [product, quantity];
}

class Cart extends Equatable {
  final List<CartItem> items;

  const Cart({required this.items});

  factory Cart.empty() {
    return const Cart(items: []);
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => CartItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'items': items.map((item) => item.toJson()).toList()};
  }

  double get totalPrice => items.fold(0, (sum, item) => sum + item.totalPrice);

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  Cart addItem(Product product, {int quantity = 1}) {
    final existingItemIndex = items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingItemIndex != -1) {
      final updatedItems = List<CartItem>.from(items);
      updatedItems[existingItemIndex] = updatedItems[existingItemIndex]
          .copyWith(
            quantity: updatedItems[existingItemIndex].quantity + quantity,
          );
      return Cart(items: updatedItems);
    } else {
      return Cart(
        items: [
          ...items,
          CartItem(product: product, quantity: quantity),
        ],
      );
    }
  }

  Cart removeItem(int productId) {
    return Cart(
      items: items.where((item) => item.product.id != productId).toList(),
    );
  }

  Cart updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      return removeItem(productId);
    }

    final updatedItems = items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    return Cart(items: updatedItems);
  }

  Cart clear() {
    return const Cart(items: []);
  }

  @override
  List<Object> get props => [items];
}

class Wishlist extends Equatable {
  final List<Product> products;

  const Wishlist({required this.products});

  factory Wishlist.empty() {
    return const Wishlist(products: []);
  }

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      products: (json['products'] as List<dynamic>? ?? [])
          .map((product) => Product.fromJson(product))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'products': products.map((product) => product.toJson()).toList()};
  }

  bool get isEmpty => products.isEmpty;

  bool get isNotEmpty => products.isNotEmpty;

  int get length => products.length;

  bool contains(Product product) {
    return products.any((p) => p.id == product.id);
  }

  Wishlist addProduct(Product product) {
    if (contains(product)) {
      return this;
    }
    return Wishlist(products: [...products, product]);
  }

  Wishlist removeProduct(Product product) {
    return Wishlist(
      products: products.where((p) => p.id != product.id).toList(),
    );
  }

  Wishlist toggleProduct(Product product) {
    if (contains(product)) {
      return removeProduct(product);
    } else {
      return addProduct(product);
    }
  }

  Wishlist clear() {
    return const Wishlist(products: []);
  }

  @override
  List<Object> get props => [products];
}
