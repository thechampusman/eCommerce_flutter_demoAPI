import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../bloc/products/product_bloc.dart';
import '../bloc/products/product_event.dart';
import '../bloc/products/product_state.dart';
import '../bloc/cart_wishlist/cart_wishlist_bloc.dart';
import '../bloc/cart_wishlist/cart_wishlist_event.dart';
import '../bloc/cart_wishlist/cart_wishlist_state.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  Product? _cachedProduct;
  List<Product> _cachedRelatedProducts = [];
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(
      ProductDetailRequested(productId: widget.productId),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductDetailLoaded) {
          setState(() {
            _cachedProduct = state.product;
            _cachedRelatedProducts = state.relatedProducts;
            _hasError = false;
            _errorMessage = '';
          });
        } else if (state is ProductError) {
          setState(() {
            _hasError = true;
            _errorMessage = state.message;
          });
        }
      },
      child: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          
          if (_cachedProduct != null && !_hasError) {
            return _buildProductDetail(_cachedProduct!, _cachedRelatedProducts);
          }

          
          if (_hasError) {
            return Scaffold(
              backgroundColor: Theme.of(context).cardColor,
              body: _buildErrorState(_errorMessage),
            );
          }

          
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildProductDetail(Product product, List<Product> relatedProducts) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(product),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductImages(product),
                _buildProductInfo(product),
                _buildReviews(product),
                if (relatedProducts.isNotEmpty)
                  _buildRelatedProducts(relatedProducts),
                const SizedBox(height: 100), 
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButtons(product),
    );
  }

  Widget _buildAppBar(Product product) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      elevation: 0,
      pinned: true,
      actions: [
        BlocBuilder<CartWishlistBloc, CartWishlistState>(
          builder: (context, state) {
            bool isInWishlist = false;
            if (state is CartWishlistLoaded) {
              isInWishlist = state.wishlist.contains(product);
            }

            return IconButton(
              icon: Icon(
                isInWishlist ? Icons.favorite : Icons.favorite_border,
                color: isInWishlist ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                context.read<CartWishlistBloc>().add(
                  WishlistToggleProduct(product: product),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isInWishlist
                          ? 'Removed from wishlist'
                          : 'Added to wishlist',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share functionality coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductImages(Product product) {
    final images = product.images.isNotEmpty
        ? product.images
        : [product.thumbnail];

    return Container(
      height: 400,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImageViewer(images, index),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: images.length,
                  effect: WormEffect(
                    dotColor: Colors.grey[300]!,
                    activeDotColor: const Color(0xFF2C3E50),
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),
              ),
            ),
          
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageViewer(List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(images[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            itemCount: images.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            pageController: PageController(initialPage: initialIndex),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo(Product product) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Text(
            product.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (product.brand.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'by ${product.brand}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],

          const SizedBox(height: 12),

          
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < product.rating.floor()
                        ? Icons.star
                        : index < product.rating
                        ? Icons.star_half
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                '${product.rating.toStringAsFixed(1)} (${product.reviews.length} reviews)',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 16),

          
          Row(
            children: [
              if (product.discountPercentage > 0) ...[
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            product.formattedDiscountedPrice,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 16),

          
          Row(
            children: [
              Icon(
                product.isInStock ? Icons.check_circle : Icons.error,
                color: product.isInStock ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                product.isInStock
                    ? 'In Stock (${product.stock})'
                    : 'Out of Stock',
                style: TextStyle(
                  color: product.isInStock ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),

          const SizedBox(height: 24),

          
          _buildProductDetails(product),
        ],
      ),
    );
  }

  Widget _buildProductDetails(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Category', product.category.toUpperCase()),
        _buildDetailRow('SKU', product.sku),
        _buildDetailRow('Weight', '${product.weight} kg'),
        _buildDetailRow(
          'Dimensions',
          '${product.dimensions.width} × ${product.dimensions.height} × ${product.dimensions.depth} cm',
        ),
        _buildDetailRow('Warranty', product.warrantyInformation),
        _buildDetailRow('Shipping', product.shippingInformation),
        _buildDetailRow('Return Policy', product.returnPolicy),
        if (product.tags.isNotEmpty)
          _buildDetailRow('Tags', product.tags.join(', ')),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildReviews(Product product) {
    if (product.reviews.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Reviews',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...product.reviews.take(3).map((review) => _buildReviewCard(review)),
          if (product.reviews.length > 3)
            TextButton(
              onPressed: () {
                
              },
              child: Text('View all ${product.reviews.length} reviews'),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ProductReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.reviewerName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(review.comment, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            _formatDate(review.date),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedProducts(List<Product> relatedProducts) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Related Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: relatedProducts.length,
              itemBuilder: (context, index) {
                final product = relatedProducts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(productId: product.id),
                      ),
                    );
                  },
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: product.thumbnail,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.formattedDiscountedPrice,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading product',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<ProductBloc>().add(
                ProductDetailRequested(
                  productId: widget.productId,
                  forceRefresh: true,
                ),
              );
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildBottomButtons(Product product) {
    return BlocBuilder<CartWishlistBloc, CartWishlistState>(
      builder: (context, state) {
        int currentQuantity = 0;

        
        if (state is CartWishlistLoaded) {
          final cartItem = state.cart.items
              .where((item) => item.product.id == product.id)
              .firstOrNull;
          currentQuantity = cartItem?.quantity ?? 0;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: currentQuantity > 0
                ? _buildQuantityControls(product, currentQuantity)
                : _buildInitialButtons(product),
          ),
        );
      },
    );
  }

  Widget _buildInitialButtons(Product product) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: product.isInStock
                ? () {
                    context.read<CartWishlistBloc>().add(
                      CartAddItem(product: product),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.title} added to cart'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Add to Cart'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: product.isInStock
                    ? const Color(0xFF2C3E50)
                    : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: product.isInStock
                ? () {
                    context.read<CartWishlistBloc>().add(
                      CartAddItem(product: product),
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Buy now functionality coming soon'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.flash_on),
            label: const Text('Buy Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControls(Product product, int currentQuantity) {
    return Row(
      children: [
        
        Expanded(
          child: Container(
            height: 48, 
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2C3E50)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                
                InkWell(
                  onTap: () {
                    if (currentQuantity > 1) {
                      context.read<CartWishlistBloc>().add(
                        CartUpdateQuantity(
                          productId: product.id,
                          quantity: currentQuantity - 1,
                        ),
                      );
                    } else {
                      context.read<CartWishlistBloc>().add(
                        CartRemoveItem(productId: product.id),
                      );
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed from cart'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(7),
                        bottomLeft: Radius.circular(7),
                      ),
                    ),
                    child: Icon(
                      currentQuantity > 1 ? Icons.remove : Icons.delete_outline,
                      color: const Color(0xFF2C3E50),
                      size: 18,
                    ),
                  ),
                ),

                
                Expanded(
                  child: Container(
                    height: 48,
                    color: const Color(0xFF2C3E50).withOpacity(0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$currentQuantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'in cart',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                
                InkWell(
                  onTap: product.isInStock
                      ? () {
                          context.read<CartWishlistBloc>().add(
                            CartUpdateQuantity(
                              productId: product.id,
                              quantity: currentQuantity + 1,
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    width: 40,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2C3E50),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(7),
                        bottomRight: Radius.circular(7),
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        
        Expanded(
          child: ElevatedButton.icon(
            onPressed: product.isInStock
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Buy now functionality coming soon'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.flash_on),
            label: const Text('Buy Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
