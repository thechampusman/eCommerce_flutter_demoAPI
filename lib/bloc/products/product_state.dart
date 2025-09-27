import 'package:equatable/equatable.dart';
import '../../models/product.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductsLoaded extends ProductState {
  final List<Product> products;
  final bool hasReachedMax;
  final int currentPage;
  final String? currentQuery;
  final String? currentCategory;
  final bool isFromCache;

  const ProductsLoaded({
    required this.products,
    this.hasReachedMax = false,
    this.currentPage = 0,
    this.currentQuery,
    this.currentCategory,
    this.isFromCache = false,
  });

  ProductsLoaded copyWith({
    List<Product>? products,
    bool? hasReachedMax,
    int? currentPage,
    String? currentQuery,
    String? currentCategory,
    bool? isFromCache,
  }) {
    return ProductsLoaded(
      products: products ?? this.products,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      currentQuery: currentQuery ?? this.currentQuery,
      currentCategory: currentCategory ?? this.currentCategory,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  @override
  List<Object?> get props => [
    products,
    hasReachedMax,
    currentPage,
    currentQuery,
    currentCategory,
    isFromCache,
  ];
}

class ProductDetailLoaded extends ProductState {
  final Product product;
  final List<Product> relatedProducts;
  final bool isFromCache;

  const ProductDetailLoaded({
    required this.product,
    this.relatedProducts = const [],
    this.isFromCache = false,
  });

  @override
  List<Object> get props => [product, relatedProducts, isFromCache];
}

class CategoriesLoaded extends ProductState {
  final List<ProductCategory> categories;
  final bool isFromCache;

  const CategoriesLoaded({required this.categories, this.isFromCache = false});

  @override
  List<Object> get props => [categories, isFromCache];
}

class ProductError extends ProductState {
  final String message;
  final bool hasOfflineData;

  const ProductError({required this.message, this.hasOfflineData = false});

  @override
  List<Object> get props => [message, hasOfflineData];
}

class ProductOfflineMode extends ProductState {
  final List<Product> cachedProducts;
  final List<ProductCategory> cachedCategories;

  const ProductOfflineMode({
    required this.cachedProducts,
    required this.cachedCategories,
  });

  @override
  List<Object> get props => [cachedProducts, cachedCategories];
}
