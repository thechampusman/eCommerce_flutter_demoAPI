import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/products_api_service.dart';
import '../../services/database_service.dart';
import 'product_event.dart';
import 'product_state.dart';

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final DatabaseService _databaseService = DatabaseService();
  static const int _pageSize = 30;

  ProductBloc() : super(ProductInitial()) {
    on<ProductsLoadRequested>(_onProductsLoadRequested);
    on<ProductsLoadMoreRequested>(_onProductsLoadMoreRequested);
    on<ProductSearchRequested>(_onProductSearchRequested);
    on<ProductSearchLoadMoreRequested>(_onProductSearchLoadMoreRequested);
    on<ProductsByCategoryRequested>(_onProductsByCategoryRequested);
    on<ProductsFilterRequested>(_onProductsFilterRequested);
    on<ProductDetailRequested>(_onProductDetailRequested);
    on<CategoriesLoadRequested>(_onCategoriesLoadRequested);
    on<ProductsRefreshRequested>(_onProductsRefreshRequested);
    on<ProductsClearCacheRequested>(_onProductsClearCacheRequested);
  }

  Future<void> _onProductsLoadRequested(
    ProductsLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      print('🔵 ProductBloc: ProductsLoadRequested event received');
      print('🔵 Current state: ${state.runtimeType}');
      print('🔵 Force refresh: ${event.forceRefresh}');

      if (state is ProductsLoaded && !event.forceRefresh) {
        print('🔵 ProductBloc: Already loaded, skipping reload');
        return;
      }

      print('🔵 ProductBloc: Trying to load fresh data from API...');
      try {
        final response = await ProductsApiService.getProducts(
          limit: event.limit,
          skip: event.skip,
          sortBy: event.sortBy,
          order: event.order,
        );
        print(
          '🔵 ProductBloc: API call successful, got ${response.products.length} fresh products',
        );

        await _databaseService.cacheProducts(response.products);
        print('🔵 ProductBloc: Fresh products cached successfully');

        emit(
          ProductsLoaded(
            products: response.products,
            hasReachedMax: response.products.length < event.limit,
            currentPage: event.skip ~/ event.limit,
            isFromCache: false,
          ),
        );
        print('🔵 ProductBloc: Emitted ProductsLoaded with fresh data');
        return;
      } catch (e) {
        print('🔴 ProductBloc: API call failed: $e');
      }

      print('🔵 ProductBloc: Loading cached products as fallback...');
      final cachedProducts = await _databaseService.getCachedProducts(
        limit: event.limit,
        offset: event.skip,
      );
      print('🔵 ProductBloc: Found ${cachedProducts.length} cached products');

      if (cachedProducts.isNotEmpty) {
        print(
          '🔵 ProductBloc: Emitting cached products with offline indicator',
        );
        emit(
          ProductsLoaded(
            products: cachedProducts,
            hasReachedMax: cachedProducts.length < event.limit,
            currentPage: event.skip ~/ event.limit,
            isFromCache: true,
          ),
        );
        return;
      }

      print('🔵 ProductBloc: No cached data, emitting ProductLoading');
      emit(ProductLoading());

      print('🔵 ProductBloc: Calling API...');
      try {
        final response = await ProductsApiService.getProducts(
          limit: event.limit,
          skip: event.skip,
          sortBy: event.sortBy,
          order: event.order,
        );
        print(
          '🔵 ProductBloc: API call successful, got ${response.products.length} products',
        );

        await _databaseService.cacheProducts(response.products);
        print('🔵 ProductBloc: Products cached successfully');

        emit(
          ProductsLoaded(
            products: response.products,
            hasReachedMax: response.products.length < event.limit,
            currentPage: event.skip ~/ event.limit,
            isFromCache: false,
          ),
        );
      } catch (e) {
        print('🔴 ProductBloc: API call failed: $e');

        if (cachedProducts.isNotEmpty) {
          print('🔵 ProductBloc: Using cached data as fallback');
          emit(
            ProductsLoaded(
              products: cachedProducts,
              hasReachedMax: cachedProducts.length < event.limit,
              currentPage: event.skip ~/ event.limit,
              isFromCache: true,
            ),
          );
        } else {
          print('🔴 ProductBloc: No cached data available, emitting error');
          emit(
            ProductError(
              message: 'No internet connection and no cached data available',
              hasOfflineData: false,
            ),
          );
        }
      }
    } catch (e) {
      print('🔴 ProductBloc: Overall error: $e');
      emit(ProductError(message: e.toString()));
    }
  }

  Future<void> _onProductsLoadMoreRequested(
    ProductsLoadMoreRequested event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProductsLoaded || currentState.hasReachedMax) {
      return;
    }

    try {
      final nextPage = currentState.currentPage + 1;
      final skip = nextPage * _pageSize;

      final response = await ProductsApiService.getProducts(
        limit: _pageSize,
        skip: skip,
      );

      await _databaseService.cacheProducts(
        response.products,
        category: currentState.currentCategory,
      );

      final allProducts = [...currentState.products, ...response.products];

      emit(
        currentState.copyWith(
          products: allProducts,
          hasReachedMax: response.products.length < _pageSize,
          currentPage: nextPage,
          isFromCache: false,
        ),
      );
    } catch (e) {
      emit(currentState);
    }
  }

  Future<void> _onProductSearchRequested(
    ProductSearchRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(ProductLoading());

      if (!event.forceRefresh && event.skip == 0) {
        final cachedResults = await _databaseService.getCachedSearchResults(
          event.query,
        );
        if (cachedResults != null && cachedResults.isNotEmpty) {
          emit(
            ProductsLoaded(
              products: cachedResults,
              hasReachedMax: cachedResults.length < event.limit,
              currentQuery: event.query,
              isFromCache: true,
            ),
          );
          return;
        }
      }

      try {
        print(
          '🔍 Searching for: "${event.query}" with sortBy: ${event.sortBy}, order: ${event.order}',
        );
        final response = await ProductsApiService.searchProducts(
          query: event.query,
          limit: event.limit,
          skip: event.skip,
          sortBy: event.sortBy,
          order: event.order,
        );

        if (event.skip == 0) {
          await _databaseService.cacheSearchResults(
            event.query,
            response.products,
          );
        }

        await _databaseService.cacheProducts(response.products);

        final hasReachedMax =
            response.products.length < event.limit ||
            (response.skip + response.products.length) >= response.total;

        print(
          '✅ Search completed: Found ${response.products.length} products out of ${response.total} total',
        );

        emit(
          ProductsLoaded(
            products: response.products,
            hasReachedMax: hasReachedMax,
            currentQuery: event.query,
            isFromCache: false,
          ),
        );
      } catch (e) {
        if (event.skip == 0) {
          final cachedResults = await _databaseService.searchCachedProducts(
            event.query,
          );

          if (cachedResults.isNotEmpty) {
            emit(
              ProductsLoaded(
                products: cachedResults,
                hasReachedMax: true,
                currentQuery: event.query,
                isFromCache: true,
              ),
            );
          } else {
            emit(
              ProductError(message: 'No results found', hasOfflineData: false),
            );
          }
        } else {
          emit(ProductError(message: e.toString()));
        }
      }
    } catch (e) {
      emit(ProductError(message: e.toString()));
    }
  }

  Future<void> _onProductSearchLoadMoreRequested(
    ProductSearchLoadMoreRequested event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProductsLoaded || currentState.hasReachedMax) return;

    try {
      final response = await ProductsApiService.searchProducts(
        query: event.query,
        limit: _pageSize,
        skip: currentState.products.length,
        sortBy: event.sortBy,
        order: event.order,
      );

      final hasReachedMax =
          response.products.length < _pageSize ||
          (response.skip + response.products.length) >= response.total;

      emit(
        ProductsLoaded(
          products: [...currentState.products, ...response.products],
          hasReachedMax: hasReachedMax,
          currentQuery: event.query,
          isFromCache: false,
        ),
      );
    } catch (e) {
      emit(
        ProductsLoaded(
          products: currentState.products,
          hasReachedMax: currentState.hasReachedMax,
          currentQuery: currentState.currentQuery,
          isFromCache: currentState.isFromCache,
        ),
      );
    }
  }

  Future<void> _onProductsByCategoryRequested(
    ProductsByCategoryRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(ProductLoading());

      
      if (!event.forceRefresh) {
        final cachedProducts = await _databaseService.getCachedProducts(
          category: event.category,
        );

        if (cachedProducts.isNotEmpty) {
          emit(
            ProductsLoaded(
              products: cachedProducts,
              hasReachedMax: true,
              currentCategory: event.category,
              isFromCache: true,
            ),
          );
        }
      }

      
      try {
        final response = await ProductsApiService.getProductsByCategory(
          category: event.category,
        );

        
        await _databaseService.cacheProducts(
          response.products,
          category: event.category,
        );

        emit(
          ProductsLoaded(
            products: response.products,
            hasReachedMax: response.products.length < _pageSize,
            currentCategory: event.category,
            isFromCache: false,
          ),
        );
      } catch (e) {
        
        final cachedProducts = await _databaseService.getCachedProducts(
          category: event.category,
        );

        if (cachedProducts.isNotEmpty) {
          emit(
            ProductsLoaded(
              products: cachedProducts,
              hasReachedMax: true,
              currentCategory: event.category,
              isFromCache: true,
            ),
          );
        } else {
          emit(ProductError(message: 'Failed to load category products'));
        }
      }
    } catch (e) {
      emit(ProductError(message: e.toString()));
    }
  }

  Future<void> _onProductsFilterRequested(
    ProductsFilterRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(ProductLoading());

      final filteredProducts = await ProductsApiService.getFilteredProducts(
        category: event.category,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        minRating: event.minRating,
        sortBy: event.sortBy,
        order: event.order,
      );

      emit(
        ProductsLoaded(
          products: filteredProducts,
          hasReachedMax: true,
          currentCategory: event.category,
          isFromCache: false,
        ),
      );
    } catch (e) {
      emit(ProductError(message: e.toString()));
    }
  }

  Future<void> _onProductDetailRequested(
    ProductDetailRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      print('📱 Loading product detail for ID: ${event.productId}');
      emit(ProductLoading());

      
      final currentState = state;
      if (currentState is ProductsLoaded) {
        final productFromResults = currentState.products
            .where((p) => p.id == event.productId)
            .firstOrNull;
        if (productFromResults != null) {
          print(
            '✅ Found product in current search results: ${productFromResults.title}',
          );

          
          try {
            final relatedResponse =
                await ProductsApiService.getProductsByCategory(
                  category: productFromResults.category,
                  limit: 6,
                );

            emit(
              ProductDetailLoaded(
                product: productFromResults,
                relatedProducts: relatedResponse.products
                    .where((p) => p.id != productFromResults.id)
                    .take(5)
                    .toList(),
                isFromCache: false,
              ),
            );
            return;
          } catch (e) {
            
            print('⚠️ Failed to load related products, continuing...');
          }
        }
      }

      
      if (!event.forceRefresh) {
        final cachedProduct = await _databaseService.getCachedProduct(
          event.productId,
        );
        if (cachedProduct != null) {
          print('✅ Found cached product: ${cachedProduct.title}');
          
          final relatedProducts = await _databaseService.getCachedProducts(
            category: cachedProduct.category,
            limit: 6,
          );

          emit(
            ProductDetailLoaded(
              product: cachedProduct,
              relatedProducts: relatedProducts
                  .where((p) => p.id != cachedProduct.id)
                  .take(5)
                  .toList(),
              isFromCache: true,
            ),
          );
          return;
        } else {
          print('❌ Product not found in cache');
        }
      }

      
      try {
        print('🌐 Fetching product from API...');
        final product = await ProductsApiService.getProduct(event.productId);

        print('✅ Successfully fetched product from API: ${product.title}');

        
        await _databaseService.cacheProducts([product]);

        
        final relatedResponse = await ProductsApiService.getProductsByCategory(
          category: product.category,
          limit: 6,
        );

        emit(
          ProductDetailLoaded(
            product: product,
            relatedProducts: relatedResponse.products
                .where((p) => p.id != product.id)
                .take(5)
                .toList(),
            isFromCache: false,
          ),
        );
      } catch (e) {
        
        final cachedProduct = await _databaseService.getCachedProduct(
          event.productId,
        );
        if (cachedProduct != null) {
          final relatedProducts = await _databaseService.getCachedProducts(
            category: cachedProduct.category,
            limit: 6,
          );

          emit(
            ProductDetailLoaded(
              product: cachedProduct,
              relatedProducts: relatedProducts
                  .where((p) => p.id != cachedProduct.id)
                  .take(5)
                  .toList(),
              isFromCache: true,
            ),
          );
        } else {
          print('❌ Product not found in cache and API failed');
          emit(ProductError(message: 'Product not found'));
        }
      }
    } catch (e) {
      emit(ProductError(message: e.toString()));
    }
  }

  Future<void> _onCategoriesLoadRequested(
    CategoriesLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      
      if (!event.forceRefresh) {
        final cachedCategories = await _databaseService.getCachedCategories();
        if (cachedCategories.isNotEmpty) {
          emit(
            CategoriesLoaded(categories: cachedCategories, isFromCache: true),
          );
        }
      }

      
      try {
        final categories = await ProductsApiService.getCategories();

        
        await _databaseService.cacheCategories(categories);

        emit(CategoriesLoaded(categories: categories, isFromCache: false));
      } catch (e) {
        
        final cachedCategories = await _databaseService.getCachedCategories();
        if (cachedCategories.isNotEmpty) {
          emit(
            CategoriesLoaded(categories: cachedCategories, isFromCache: true),
          );
        } else {
          emit(ProductError(message: 'Failed to load categories'));
        }
      }
    } catch (e) {
      emit(ProductError(message: e.toString()));
    }
  }

  Future<void> _onProductsRefreshRequested(
    ProductsRefreshRequested event,
    Emitter<ProductState> emit,
  ) async {
    add(const ProductsLoadRequested(forceRefresh: true));
  }

  Future<void> _onProductsClearCacheRequested(
    ProductsClearCacheRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _databaseService.clearCache();
      emit(ProductInitial());
    } catch (e) {
      emit(ProductError(message: 'Failed to clear cache'));
    }
  }
}
