import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/database_service.dart';
import '../../services/cart_api_service.dart';
import '../../models/cart_wishlist.dart';
import 'cart_wishlist_event.dart';
import 'cart_wishlist_state.dart';


dynamic databaseServiceImpl = DatabaseService;
dynamic cartApiServiceImpl = CartApiService;

class CartWishlistBloc extends Bloc<CartWishlistEvent, CartWishlistState> {
  DatabaseService get _databaseService => databaseServiceImpl();

  CartWishlistBloc() : super(CartWishlistInitial()) {
    on<CartLoadRequested>(_onCartLoadRequested);
    on<CartAddItem>(_onCartAddItem);
    on<CartRemoveItem>(_onCartRemoveItem);
    on<CartUpdateQuantity>(_onCartUpdateQuantity);
    on<CartClear>(_onCartClear);
    on<CartLoadFromApi>(_onCartLoadFromApi);
    on<CartSyncWithApi>(_onCartSyncWithApi);
    on<WishlistLoadRequested>(_onWishlistLoadRequested);
    on<WishlistToggleProduct>(_onWishlistToggleProduct);
    on<WishlistRemoveProduct>(_onWishlistRemoveProduct);
    on<WishlistClear>(_onWishlistClear);
    on<ClearUserData>(_onClearUserData);
  }

  Future<void> _onCartLoadRequested(
    CartLoadRequested event,
    Emitter<CartWishlistState> emit,
  ) async {
    try {
      print('🛒 _onCartLoadRequested - Loading cart from local database');
      emit(CartWishlistLoading());

      final cart = await _databaseService.getCart();
      final wishlist = await _databaseService.getWishlist();

      print(
        '🛒 _onCartLoadRequested - Loaded cart with ${cart.items.length} items from database',
      );
      print(
        '🛒 _onCartLoadRequested - Loaded wishlist with ${wishlist.products.length} items from database',
      );

      emit(CartWishlistLoaded(cart: cart, wishlist: wishlist));
    } catch (e) {
      print('🛒 _onCartLoadRequested - Error loading cart: $e');
      emit(CartWishlistError(message: e.toString()));
    }
  }

  Future<void> _onCartAddItem(
    CartAddItem event,
    Emitter<CartWishlistState> emit,
  ) async {
    final currentState = state;
    print('🛒 _onCartAddItem - Current state: $currentState');

    if (currentState is! CartWishlistLoaded) {
      print(
        '🛒 _onCartAddItem - State is not CartWishlistLoaded, current state: $currentState',
      );
      return;
    }

    try {
      print(
        '🛒 _onCartAddItem - Adding ${event.product.title} to cart with quantity ${event.quantity}',
      );
      print(
        '🛒 _onCartAddItem - Current cart has ${currentState.cart.items.length} items',
      );

      final updatedCart = currentState.cart.addItem(
        event.product,
        quantity: event.quantity,
      );

      print(
        '🛒 _onCartAddItem - Updated cart has ${updatedCart.items.length} items',
      );

      await _databaseService.saveCart(updatedCart);
      print('🛒 _onCartAddItem - Cart saved to database');

      emit(currentState.copyWith(cart: updatedCart));
      print('🛒 _onCartAddItem - New state emitted');
    } catch (e) {
      print('🛒 _onCartAddItem - Error: $e');
      emit(CartWishlistError(message: 'Failed to add item to cart'));
    }
  }

  Future<void> _onCartRemoveItem(
    CartRemoveItem event,
    Emitter<CartWishlistState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CartWishlistLoaded) return;

    try {
      final updatedCart = currentState.cart.removeItem(event.productId);
      await _databaseService.saveCart(updatedCart);

      emit(currentState.copyWith(cart: updatedCart));
    } catch (e) {
      emit(CartWishlistError(message: 'Failed to remove item from cart'));
    }
  }

  Future<void> _onCartUpdateQuantity(
    CartUpdateQuantity event,
    Emitter<CartWishlistState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CartWishlistLoaded) return;

    try {
      final updatedCart = currentState.cart.updateQuantity(
        event.productId,
        event.quantity,
      );
      await _databaseService.saveCart(updatedCart);

      emit(currentState.copyWith(cart: updatedCart));
    } catch (e) {
      emit(CartWishlistError(message: 'Failed to update cart item quantity'));
    }
  }

  Future<void> _onCartClear(
    CartClear event,
    Emitter<CartWishlistState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CartWishlistLoaded) return;

    try {
      final clearedCart = currentState.cart.clear();
      await _databaseService.saveCart(clearedCart);

      emit(currentState.copyWith(cart: clearedCart));
    } catch (e) {
      emit(CartWishlistError(message: 'Failed to clear cart'));
    }
  }

  Future<void> _onWishlistLoadRequested(
    WishlistLoadRequested event,
    Emitter<CartWishlistState> emit,
  ) async {
    try {
      final cart = await _databaseService.getCart();
      final wishlist = await _databaseService.getWishlist();

      emit(CartWishlistLoaded(cart: cart, wishlist: wishlist));
    } catch (e) {
      emit(CartWishlistError(message: e.toString()));
    }
  }

  Future<void> _onWishlistToggleProduct(
    WishlistToggleProduct event,
    Emitter<CartWishlistState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CartWishlistLoaded) return;

    try {
      final updatedWishlist = currentState.wishlist.toggleProduct(
        event.product,
      );
      await _databaseService.saveWishlist(updatedWishlist);

      emit(currentState.copyWith(wishlist: updatedWishlist));
    } catch (e) {
      emit(CartWishlistError(message: 'Failed to update wishlist'));
    }
  }

  Future<void> _onWishlistRemoveProduct(
    WishlistRemoveProduct event,
    Emitter<CartWishlistState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CartWishlistLoaded) return;

    try {
      final updatedWishlist = currentState.wishlist.removeProduct(
        event.product,
      );
      await _databaseService.saveWishlist(updatedWishlist);

      emit(currentState.copyWith(wishlist: updatedWishlist));
    } catch (e) {
      emit(CartWishlistError(message: 'Failed to remove item from wishlist'));
    }
  }

  Future<void> _onWishlistClear(
    WishlistClear event,
    Emitter<CartWishlistState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CartWishlistLoaded) return;

    try {
      final clearedWishlist = currentState.wishlist.clear();
      await _databaseService.saveWishlist(clearedWishlist);

      emit(currentState.copyWith(wishlist: clearedWishlist));
    } catch (e) {
      emit(CartWishlistError(message: 'Failed to clear wishlist'));
    }
  }

  Future<void> _onCartLoadFromApi(
    CartLoadFromApi event,
    Emitter<CartWishlistState> emit,
  ) async {
    try {
      emit(CartWishlistLoading());
      print('🛒 Loading cart from API for user ${event.userId}...');

      final List<Cart> apiCarts = await CartApiService.getCartsByUserId(
        event.userId,
      );

      final Cart apiCart = apiCarts.isNotEmpty ? apiCarts.first : Cart.empty();

      final wishlist = await _databaseService.getWishlist();

      await _databaseService.saveCart(apiCart);

      print(
        '✅ Successfully loaded cart from API: ${apiCart.items.length} items',
      );
      emit(CartWishlistLoaded(cart: apiCart, wishlist: wishlist));
    } catch (e) {
      print('❌ Failed to load cart from API: $e');

      try {
        final localCart = await _databaseService.getCart();
        final wishlist = await _databaseService.getWishlist();

        print(
          '🔄 Using local cart as fallback: ${localCart.items.length} items',
        );
        emit(CartWishlistLoaded(cart: localCart, wishlist: wishlist));
      } catch (localError) {
        emit(CartWishlistError(message: 'Failed to load cart: $localError'));
      }
    }
  }

  Future<void> _onCartSyncWithApi(
    CartSyncWithApi event,
    Emitter<CartWishlistState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CartWishlistLoaded) return;

    try {
      print('🔄 Syncing cart with API for user ${event.userId}...');

      if (currentState.cart.isNotEmpty) {
        await CartApiService.addCart(
          userId: event.userId,
          items: currentState.cart.items,
        );

        print('✅ Successfully synced cart to API');
      } else {
        print('ℹ️ Cart is empty, no sync needed');
      }
    } catch (e) {
      print('❌ Failed to sync cart with API: $e');
    }
  }

  Future<void> _onClearUserData(
    ClearUserData event,
    Emitter<CartWishlistState> emit,
  ) async {
    try {
      print('🧹 Clearing all user data (cart and wishlist) on logout/skip');

      await _databaseService.clearCart();
      await _databaseService.clearWishlist();

      emit(CartWishlistLoaded(cart: Cart.empty(), wishlist: Wishlist.empty()));

      print('✅ Successfully cleared all user data');
    } catch (e) {
      print('❌ Error clearing user data: $e');
      emit(CartWishlistError(message: 'Failed to clear user data: $e'));
    }
  }
}
