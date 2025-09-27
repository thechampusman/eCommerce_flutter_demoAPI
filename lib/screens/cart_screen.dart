import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../bloc/cart_wishlist/cart_wishlist_bloc.dart';
import '../bloc/cart_wishlist/cart_wishlist_event.dart';
import '../bloc/cart_wishlist/cart_wishlist_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../models/cart_wishlist.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isOnline = true;
  bool _isAutoSyncing = false;

  @override
  void initState() {
    super.initState();
    
    _loadCartWithApiIntegration();
  }

  void _loadCartWithApiIntegration() async {
    
    context.read<CartWishlistBloc>().add(CartLoadRequested());

    
    _isOnline = await _checkInternetConnection();
    if (mounted) setState(() {});

    
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && _isOnline) {
      _autoSyncWithApi(authState.user.id);
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('dummyjson.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _autoSyncWithApi(int userId) async {
    if (_isAutoSyncing) return;

    setState(() => _isAutoSyncing = true);

    try {
      context.read<CartWishlistBloc>().add(CartSyncWithApi(userId: userId));

      
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      if (mounted) {
        setState(() => _isOnline = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isAutoSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        foregroundColor:
            Theme.of(context).appBarTheme.foregroundColor ??
            Theme.of(context).colorScheme.onSurface,
        elevation: 1,
        title: Text(
          'Shopping Cart',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          BlocBuilder<CartWishlistBloc, CartWishlistState>(
            builder: (context, state) {
              if (state is CartWishlistLoaded && state.cart.isNotEmpty) {
                return TextButton(
                  onPressed: () {
                    context.read<CartWishlistBloc>().add(CartClear());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cart cleared'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Clear All'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<CartWishlistBloc, CartWishlistState>(
        builder: (context, state) {
          if (state is CartWishlistLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CartWishlistLoaded) {
            if (state.cart.isEmpty) {
              return _buildEmptyCart();
            }
            return _buildCartContent(context, state);
          } else if (state is CartWishlistError) {
            return _buildErrorState(context, state.message);
          }
          return const Center(child: Text('Cart not available'));
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 400;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: isMobile ? 80 : (isTablet ? 120 : 100),
            color: Theme.of(context).disabledColor,
          ),
          SizedBox(height: isMobile ? 16 : (isTablet ? 32 : 24)),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: isMobile ? 20 : (isTablet ? 28 : 24),
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: isMobile ? 8 : (isTablet ? 16 : 12)),
          Text(
            'Add some products to get started',
            style: TextStyle(
              fontSize: isMobile ? 14 : (isTablet ? 18 : 16),
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 24 : (isTablet ? 40 : 32)),
          Builder(
            builder: (context) => ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.shopping_bag_outlined,
                color: Theme.of(context).iconTheme.color,
              ),
              label: const Text('Start Shopping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartWishlistLoaded state) {
    final totalAmount = state.cart.totalPrice;

    return Column(
      children: [
        
        if (!_isOnline) _buildOfflineNotice(),
        if (_isAutoSyncing) _buildSyncingIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              
              _isOnline = await _checkInternetConnection();
              if (mounted) setState(() {});

              
              context.read<CartWishlistBloc>().add(CartLoadRequested());

              
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated && _isOnline) {
                _autoSyncWithApi(authState.user.id);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.cart.items.length,
              itemBuilder: (context, index) {
                final cartItem = state.cart.items[index];
                return _buildCartItem(context, cartItem);
              },
            ),
          ),
        ),
        _buildCheckoutSection(context, totalAmount, state.cart.totalItems),
      ],
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem cartItem) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 400;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : (isTablet ? 24 : 16),
        vertical: 4,
      ),
      padding: EdgeInsets.all(isMobile ? 10 : (isTablet ? 16 : 12)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailScreen(productId: cartItem.product.id),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: cartItem.product.thumbnail,
                width: isMobile ? 70 : (isTablet ? 100 : 80),
                height: isMobile ? 70 : (isTablet ? 100 : 80),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: isMobile ? 70 : (isTablet ? 100 : 80),
                  height: isMobile ? 70 : (isTablet ? 100 : 80),
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: isMobile ? 70 : (isTablet ? 100 : 80),
                  height: isMobile ? 70 : (isTablet ? 100 : 80),
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.product.title,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : (isTablet ? 18 : 16),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (cartItem.product.brand.isNotEmpty)
                  Text(
                    cartItem.product.brand,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : (isTablet ? 16 : 14),
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (cartItem.product.discountPercentage > 0) ...[
                      Text(
                        '\$${cartItem.product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      cartItem.product.formattedDiscountedPrice,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : (isTablet ? 18 : 16),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                if (!cartItem.product.isInStock)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Out of Stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          
          Column(
            children: [
              
              IconButton(
                onPressed: () {
                  context.read<CartWishlistBloc>().add(
                    CartRemoveItem(productId: cartItem.product.id),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${cartItem.product.title} removed from cart',
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),

              const SizedBox(height: 8),

              
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuantityButton(
                      context,
                      Icons.remove,
                      () => _updateQuantity(
                        context,
                        cartItem,
                        cartItem.quantity - 1,
                      ),
                      cartItem.quantity <= 1,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        cartItem.quantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      context,
                      Icons.add,
                      () => _updateQuantity(
                        context,
                        cartItem,
                        cartItem.quantity + 1,
                      ),
                      cartItem.quantity >= cartItem.product.stock ||
                          !cartItem.product.isInStock,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              
              Text(
                '\$${(cartItem.product.discountedPrice * cartItem.quantity).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
    bool isDisabled,
  ) {
    return InkWell(
      onTap: isDisabled ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 16,
          color: isDisabled
              ? Theme.of(context).disabledColor
              : Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(
    BuildContext context,
    double totalAmount,
    int itemCount,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 400;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 20 : 16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            
            Row(
              children: [
                Text(
                  'Items ($itemCount)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Shipping',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const Spacer(),
                Text(
                  totalAmount > 50 ? 'FREE' : '\$5.99',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: totalAmount > 50
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : (isTablet ? 24 : 20),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${(totalAmount + (totalAmount > 50 ? 0 : 5.99)).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : (isTablet ? 24 : 20),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),

            if (totalAmount <= 50)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Add \$${(50 - totalAmount).toStringAsFixed(2)} more for FREE shipping',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _proceedToCheckout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 14 : (isTablet ? 20 : 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : (isTablet ? 18 : 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading cart',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<CartWishlistBloc>().add(CartLoadRequested());
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(
    BuildContext context,
    CartItem cartItem,
    int newQuantity,
  ) {
    if (newQuantity <= 0) {
      context.read<CartWishlistBloc>().add(
        CartRemoveItem(productId: cartItem.product.id),
      );
    } else if (newQuantity <= cartItem.product.stock) {
      context.read<CartWishlistBloc>().add(
        CartUpdateQuantity(
          productId: cartItem.product.id,
          quantity: newQuantity,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${cartItem.product.stock} items available'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _proceedToCheckout(BuildContext context) {
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Checkout'),
          content: const Text(
            'Checkout functionality will be implemented soon!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOfflineNotice() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 400;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 10 : (isTablet ? 16 : 12)),
      margin: EdgeInsets.all(isMobile ? 12 : (isTablet ? 20 : 16)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.08),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Theme.of(context).colorScheme.error,
            size: isMobile ? 18 : (isTablet ? 24 : 20),
          ),
          SizedBox(width: isMobile ? 6 : (isTablet ? 10 : 8)),
          Expanded(
            child: Text(
              'You\'re offline. Cart changes will sync when connection is restored.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: isMobile ? 12 : (isTablet ? 16 : 14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncingIndicator() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 400;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 10 : (isTablet ? 16 : 12)),
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : (isTablet ? 20 : 16),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: isMobile ? 8 : (isTablet ? 16 : 12)),
          Text(
            'Syncing cart...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: isMobile ? 12 : (isTablet ? 16 : 14),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
