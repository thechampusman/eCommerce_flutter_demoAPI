import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class ProductsLoadRequested extends ProductEvent {
  final bool forceRefresh;
  final int limit;
  final int skip;
  final String? sortBy;
  final String? order;

  const ProductsLoadRequested({
    this.forceRefresh = false,
    this.limit = 30,
    this.skip = 0,
    this.sortBy,
    this.order,
  });

  @override
  List<Object?> get props => [forceRefresh, limit, skip, sortBy, order];
}

class ProductsLoadMoreRequested extends ProductEvent {}

class ProductSearchRequested extends ProductEvent {
  final String query;
  final bool forceRefresh;
  final int limit;
  final int skip;
  final String? sortBy;
  final String? order;

  const ProductSearchRequested({
    required this.query,
    this.forceRefresh = false,
    this.limit = 30,
    this.skip = 0,
    this.sortBy,
    this.order,
  });

  @override
  List<Object?> get props => [query, forceRefresh, limit, skip, sortBy, order];
}

class ProductSearchLoadMoreRequested extends ProductEvent {
  final String query;
  final String? sortBy;
  final String? order;

  const ProductSearchLoadMoreRequested({
    required this.query,
    this.sortBy,
    this.order,
  });

  @override
  List<Object?> get props => [query, sortBy, order];
}

class ProductsByCategoryRequested extends ProductEvent {
  final String category;
  final bool forceRefresh;

  const ProductsByCategoryRequested({
    required this.category,
    this.forceRefresh = false,
  });

  @override
  List<Object> get props => [category, forceRefresh];
}

class ProductsFilterRequested extends ProductEvent {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String? sortBy;
  final String? order;

  const ProductsFilterRequested({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.sortBy,
    this.order,
  });

  @override
  List<Object?> get props => [
    category,
    minPrice,
    maxPrice,
    minRating,
    sortBy,
    order,
  ];
}

class ProductDetailRequested extends ProductEvent {
  final int productId;
  final bool forceRefresh;

  const ProductDetailRequested({
    required this.productId,
    this.forceRefresh = false,
  });

  @override
  List<Object> get props => [productId, forceRefresh];
}

class CategoriesLoadRequested extends ProductEvent {
  final bool forceRefresh;

  const CategoriesLoadRequested({this.forceRefresh = false});

  @override
  List<Object> get props => [forceRefresh];
}

class ProductsRefreshRequested extends ProductEvent {}

class ProductsClearCacheRequested extends ProductEvent {}
