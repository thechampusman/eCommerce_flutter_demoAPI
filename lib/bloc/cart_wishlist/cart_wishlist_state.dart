import 'package:equatable/equatable.dart';
import '../../models/cart_wishlist.dart';

abstract class CartWishlistState extends Equatable {
  const CartWishlistState();

  @override
  List<Object> get props => [];
}

class CartWishlistInitial extends CartWishlistState {}

class CartWishlistLoading extends CartWishlistState {}

class CartWishlistLoaded extends CartWishlistState {
  final Cart cart;
  final Wishlist wishlist;

  const CartWishlistLoaded({required this.cart, required this.wishlist});

  CartWishlistLoaded copyWith({Cart? cart, Wishlist? wishlist}) {
    return CartWishlistLoaded(
      cart: cart ?? this.cart,
      wishlist: wishlist ?? this.wishlist,
    );
  }

  @override
  List<Object> get props => [cart, wishlist];
}

class CartWishlistError extends CartWishlistState {
  final String message;

  const CartWishlistError({required this.message});

  @override
  List<Object> get props => [message];
}
