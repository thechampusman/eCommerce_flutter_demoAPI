import 'package:equatable/equatable.dart';
import '../../models/product.dart';

abstract class CartWishlistEvent extends Equatable {
  const CartWishlistEvent();

  @override
  List<Object> get props => [];
}


class CartLoadRequested extends CartWishlistEvent {}

class CartAddItem extends CartWishlistEvent {
  final Product product;
  final int quantity;

  const CartAddItem({required this.product, this.quantity = 1});

  @override
  List<Object> get props => [product, quantity];
}

class CartRemoveItem extends CartWishlistEvent {
  final int productId;

  const CartRemoveItem({required this.productId});

  @override
  List<Object> get props => [productId];
}

class CartUpdateQuantity extends CartWishlistEvent {
  final int productId;
  final int quantity;

  const CartUpdateQuantity({required this.productId, required this.quantity});

  @override
  List<Object> get props => [productId, quantity];
}

class CartClear extends CartWishlistEvent {}

class CartLoadFromApi extends CartWishlistEvent {
  final int userId;

  const CartLoadFromApi({required this.userId});

  @override
  List<Object> get props => [userId];
}

class CartSyncWithApi extends CartWishlistEvent {
  final int userId;

  const CartSyncWithApi({required this.userId});

  @override
  List<Object> get props => [userId];
}

class WishlistLoadRequested extends CartWishlistEvent {}

class WishlistToggleProduct extends CartWishlistEvent {
  final Product product;

  const WishlistToggleProduct({required this.product});

  @override
  List<Object> get props => [product];
}

class WishlistRemoveProduct extends CartWishlistEvent {
  final Product product;

  const WishlistRemoveProduct({required this.product});

  @override
  List<Object> get props => [product];
}

class WishlistClear extends CartWishlistEvent {}

class ClearUserData extends CartWishlistEvent {}
