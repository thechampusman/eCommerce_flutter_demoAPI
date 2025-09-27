import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../bloc/products/product_bloc.dart';
import '../bloc/products/product_event.dart';
import '../bloc/products/product_state.dart';
import '../bloc/cart_wishlist/cart_wishlist_bloc.dart';
import '../bloc/cart_wishlist/cart_wishlist_event.dart';
import '../bloc/cart_wishlist/cart_wishlist_state.dart';

import '../models/product.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true;
  String _deliveryLocation = 'Select delivery location';
  bool _isNavigatingToProductDetail = false;

  
  String _currentSort = 'Default';
  Set<String> _selectedCategories = {};
  double _minPrice = 0;
  double _maxPrice = 1000;
  double _minRating = 0;
  List<String> _availableCategories = [];
  bool _categoriesLoading = false;

  @override
  void initState() {
    super.initState();
    print('🏠 ProductsScreen initState called');
    _scrollController.addListener(_onScroll);

    
    final currentState = context.read<ProductBloc>().state;
    print(
      '🏠 Current ProductBloc state before load: ${currentState.runtimeType}',
    );
    if (currentState is ProductsLoaded) {
      print('🏠 Already have ${currentState.products.length} products loaded');
    }
    context.read<ProductBloc>().add(const ProductsLoadRequested());

    
    print('🏠 Loading categories at app launch for offline availability');
    _fetchCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🏠 ProductsScreen didChangeDependencies called');
    final currentState = context.read<ProductBloc>().state;
    print(
      '🏠 ProductBloc state in didChangeDependencies: ${currentState.runtimeType}',
    );
  }

  @override
  void dispose() {
    print('🏠 ProductsScreen dispose called');
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ProductBloc>().add(ProductsLoadMoreRequested());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          print('🏠 BlocBuilder rebuilding with state: ${state.runtimeType}');
          if (state is ProductsLoaded) {
            print(
              '🏠 Showing ${state.products.length} products, fromCache: ${state.isFromCache}',
            );
            return _buildProductsList(state);
          } else if (state is ProductError) {
            print('🏠 Showing error: ${state.message}');
            return _buildErrorState(state);
          } else if (state is ProductLoading) {
            print('🏠 Showing shimmer (ProductLoading)');
            return _buildShimmerLoading();
          } else if (state is ProductDetailLoaded) {
            
            if (!_isNavigatingToProductDetail) {
              print(
                '🏠 ProductDetailLoaded detected - reloading products list (returned from detail)',
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<ProductBloc>().add(const ProductsLoadRequested());
              });
            } else {
              print(
                '🏠 ProductDetailLoaded detected - but navigating TO detail, not reloading',
              );
            }
            return _buildShimmerLoading();
          } else {
            print('🏠 Showing shimmer (${state.runtimeType} - fallback)');
            
            return _buildShimmerLoading();
          }
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor:
          Theme.of(context).appBarTheme.backgroundColor ??
          Theme.of(context).primaryColor,
      foregroundColor:
          Theme.of(context).appBarTheme.foregroundColor ??
          Theme.of(context).colorScheme.onPrimary,
      elevation: 0,
      toolbarHeight: 70,
      title: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.camera_alt,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {},
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
          readOnly: true,
        ),
      ),
    );
  }

  Widget _buildProductsList(ProductsLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProductBloc>().add(ProductsRefreshRequested());
      },
      child: Column(
        children: [
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : null,
              gradient: Theme.of(context).brightness == Brightness.light
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).primaryColor,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Deliver to: ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    _deliveryLocation,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showSortBottomSheet(),
                  child: _buildFilterChip(
                    'Sort',
                    Icons.sort,
                    _currentSort != 'Default',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showFilterBottomSheet(),
                  child: _buildFilterChip(
                    'Filter',
                    Icons.filter_list,
                    _minPrice > 0 || _maxPrice < 1000 || _minRating > 0,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: GestureDetector(
                    onTap: () => _showCategoriesBottomSheet(),
                    child: _buildFilterChip(
                      'Categories',
                      Icons.category_outlined,
                      _selectedCategories.isNotEmpty,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          if (state.isFromCache)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[100]!, Colors.orange[50]!],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.orange[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange[800]!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.offline_bolt_rounded,
                      color: Colors.orange[800],
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline Mode',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Showing cached data • Pull down to refresh',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.orange[700],
                    size: 16,
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isGridView
                ? _buildModernGridView(state.products)
                : _buildModernListView(state.products),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData icon, [
    bool isActive = false,
  ]) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary.withOpacity(isDark ? 0.25 : 0.12)
            : theme.cardColor,
        border: Border.all(
          color: isActive ? theme.colorScheme.primary : theme.dividerColor,
          width: isActive ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? theme.colorScheme.primary : theme.iconTheme.color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodyMedium?.color,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  
  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1565C0).withOpacity(0.05),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sort_rounded,
                      color: Color(0xFF1565C0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sort Products',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose how to organize your products',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),

            
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(children: _buildModernSortOptions()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildModernSortOptions() {
    final sortOptions = [
      {
        'label': 'Default',
        'value': 'Default',
        'icon': Icons.apps_rounded,
        'desc': 'Original order',
      },
      {
        'label': 'Price: Low to High',
        'value': 'PriceLowHigh',
        'icon': Icons.trending_up_rounded,
        'desc': 'Cheapest first',
      },
      {
        'label': 'Price: High to Low',
        'value': 'PriceHighLow',
        'icon': Icons.trending_down_rounded,
        'desc': 'Most expensive first',
      },
      {
        'label': 'Rating: High to Low',
        'value': 'RatingHighLow',
        'icon': Icons.star_rounded,
        'desc': 'Best rated first',
      },
      {
        'label': 'Name: A to Z',
        'value': 'NameAZ',
        'icon': Icons.sort_by_alpha_rounded,
        'desc': 'Alphabetical order',
      },
      {
        'label': 'Name: Z to A',
        'value': 'NameZA',
        'icon': Icons.sort_by_alpha_rounded,
        'desc': 'Reverse alphabetical',
      },
    ];

    return sortOptions.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value;
      final isSelected = _currentSort == option['value'];

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return Container(
        margin: EdgeInsets.only(
          bottom: index == sortOptions.length - 1 ? 20 : 12,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _currentSort = option['value']! as String;
              });
              Navigator.pop(context);
              _applySortAndFilter();
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(
                        isDark ? 0.18 : 0.08,
                      )
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.3)
                      : theme.dividerColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.dividerColor.withOpacity(
                              isDark ? 0.18 : 0.12,
                            ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      option['icon'] as IconData,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.iconTheme.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),

                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option['label']! as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option['desc']! as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: theme.colorScheme.onPrimary,
                            size: 14,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1565C0).withOpacity(0.05),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF1565C0),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filter Products',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Refine your search results',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: () {
                          setModalState(() {
                            _minPrice = 0;
                            _maxPrice = 1000;
                            _minRating = 0;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),

              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1565C0,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.attach_money_rounded,
                                    color: Color(0xFF1565C0),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Price Range',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            RangeSlider(
                              values: RangeValues(_minPrice, _maxPrice),
                              min: 0,
                              max: 1000,
                              divisions: 100,
                              labels: RangeLabels(
                                '\$${_minPrice.round()}',
                                '\$${_maxPrice.round()}',
                              ),
                              onChanged: (values) {
                                setModalState(() {
                                  _minPrice = values.start;
                                  _maxPrice = values.end;
                                });
                              },
                              activeColor: const Color(0xFF1565C0),
                              inactiveColor: Colors.grey[300],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1565C0,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '\$${_minPrice.round()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1565C0,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '\$${_maxPrice.round()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Minimum Rating',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Slider(
                              value: _minRating,
                              min: 0,
                              max: 5,
                              divisions: 50,
                              label: '${_minRating.toStringAsFixed(1)} ⭐',
                              onChanged: (value) {
                                setModalState(() {
                                  _minRating = value;
                                });
                              },
                              activeColor: Colors.amber,
                              inactiveColor: Colors.grey[300],
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_minRating.toStringAsFixed(1)} and above',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      
                      if (_minPrice > 0 || _maxPrice < 1000 || _minRating > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF1565C0),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Active filters: ${_getActiveFiltersText()}',
                                  style: const TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applySortAndFilter();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActiveFiltersText() {
    List<String> filters = [];
    if (_minPrice > 0 || _maxPrice < 1000) {
      filters.add('Price range');
    }
    if (_minRating > 0) {
      filters.add('Rating');
    }
    return filters.join(', ');
  }

  
  Future<void> _fetchCategories() async {
    if (_availableCategories.isNotEmpty) {
      print(
        '📂 Categories already loaded: ${_availableCategories.length} categories',
      );
      return; 
    }

    if (mounted) {
      setState(() {
        _categoriesLoading = true;
      });
    }

    try {
      print('🔄 Fetching categories from DummyJSON API...');
      final response = await http
          .get(Uri.parse('https://dummyjson.com/products/categories'))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏰ API request timed out, using fallback categories');
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        final List<dynamic> categoriesData = json.decode(response.body);
        print(
          '✅ Successfully fetched ${categoriesData.length} categories from API',
        );

        
        final List<String> categories = categoriesData
            .map((category) => category['slug'] as String)
            .toList();

        if (mounted) {
          setState(() {
            _availableCategories = categories;
            _categoriesLoading = false;
          });
        }

        print('📂 Available categories cached: $categories');

        
        
      } else {
        print('❌ API request failed with status: ${response.statusCode}');
        _setFallbackCategories();
      }
    } catch (e) {
      print('❌ Error fetching categories (offline mode?): $e');
      print('🔄 Loading fallback categories for offline use');
      _setFallbackCategories();
    }
  }

  void _setFallbackCategories() {
    print('🔄 Using fallback categories for offline reliability...');
    if (mounted) {
      setState(() {
        _availableCategories = [
          'beauty',
          'fragrances',
          'furniture',
          'groceries',
          'home-decoration',
          'kitchen-accessories',
          'laptops',
          'mens-shirts',
          'mens-shoes',
          'mens-watches',
          'mobile-accessories',
          'motorcycle',
          'skin-care',
          'smartphones',
          'sports-accessories',
          'sunglasses',
          'tablets',
          'tops',
          'vehicle',
          'womens-bags',
          'womens-dresses',
          'womens-jewellery',
          'womens-shoes',
          'womens-watches',
        ];
        _categoriesLoading = false;
      });
    }
    print(
      '📂 Fallback categories loaded: ${_availableCategories.length} categories available offline',
    );
  }

  
  void _showCategoriesBottomSheet() async {
    
    if (_availableCategories.isEmpty) {
      print('📂 Categories not loaded yet, fetching now...');
      await _fetchCategories();
    } else {
      print(
        '📂 Using cached categories: ${_availableCategories.length} available',
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1565C0).withOpacity(0.05),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.category_rounded,
                            color: Color(0xFF1565C0),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Product Categories',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A202C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedCategories.isEmpty
                                    ? 'Select categories to filter products'
                                    : '${_selectedCategories.length} categories selected',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedCategories.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  _selectedCategories.clear();
                                });
                              },
                              icon: const Icon(
                                Icons.clear_all_rounded,
                                size: 18,
                                color: Color(0xFFE53E3E),
                              ),
                              label: const Text(
                                'Clear',
                                style: TextStyle(
                                  color: Color(0xFFE53E3E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFE53E3E,
                                ).withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF64748B),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: _buildModernCategoryOptions(setModalState),
                    ),
                  ),
                ),
              ),

              
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      
                      if (_selectedCategories.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1565C0).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF1565C0),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${_selectedCategories.length} categories selected',
                                  style: const TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applySortAndFilter();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: const Color(
                              0xFF1565C0,
                            ).withOpacity(0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.filter_alt_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _selectedCategories.isEmpty
                                    ? 'Show All Products'
                                    : 'Apply Filter (${_selectedCategories.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildModernCategoryOptions(StateSetter setModalState) {
    if (_categoriesLoading) {
      return [
        Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading categories...',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fetching latest categories or loading offline data',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }

    if (_availableCategories.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.category_outlined,
                  color: Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Categories unavailable',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to load categories. Check connection and try again.',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _availableCategories.clear();
                  });
                  _fetchCategories();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return _availableCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final isSelected = _selectedCategories.contains(category);
      final displayName = category
          .replaceAll('-', ' ')
          .split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');

      return Container(
        margin: EdgeInsets.only(
          bottom: index == _availableCategories.length - 1 ? 0 : 12,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setModalState(() {
                if (isSelected) {
                  _selectedCategories.remove(category);
                } else {
                  _selectedCategories.add(category);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1565C0).withOpacity(0.08)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1565C0).withOpacity(0.3)
                      : Colors.grey[200]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1565C0)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),

                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF1565C0)
                                : const Color(0xFF1A202C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to ${isSelected ? 'remove' : 'select'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1565C0)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1565C0)
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'beauty':
        return Icons.face_rounded;
      case 'fragrances':
        return Icons.local_florist_rounded;
      case 'furniture':
        return Icons.chair_rounded;
      case 'groceries':
        return Icons.shopping_cart_rounded;
      case 'home-decoration':
        return Icons.home_rounded;
      case 'kitchen-accessories':
        return Icons.kitchen_rounded;
      case 'laptops':
        return Icons.laptop_rounded;
      case 'mens-shirts':
      case 'mens-shoes':
      case 'mens-watches':
        return Icons.person_rounded;
      case 'mobile-accessories':
        return Icons.phone_android_rounded;
      case 'motorcycle':
        return Icons.two_wheeler_rounded;
      case 'skin-care':
        return Icons.spa_rounded;
      case 'smartphones':
        return Icons.smartphone_rounded;
      case 'sports-accessories':
        return Icons.sports_basketball_rounded;
      case 'sunglasses':
        return Icons.wb_sunny_rounded;
      case 'tablets':
        return Icons.tablet_rounded;
      case 'tops':
        return Icons.checkroom_rounded;
      case 'vehicle':
        return Icons.directions_car_rounded;
      case 'womens-bags':
      case 'womens-dresses':
      case 'womens-jewellery':
      case 'womens-shoes':
      case 'womens-watches':
        return Icons.person_4_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  
  void _applySortAndFilter() {
    
    
    
    setState(() {});
  }

  
  List<Product> _filterAndSortProducts(List<Product> products) {
    
    var filteredProducts = products.where((product) {
      
      if (_minPrice > 0 || _maxPrice < 1000) {
        final price = product.discountPercentage > 0
            ? product.price * (1 - product.discountPercentage / 100)
            : product.price;
        if (price < _minPrice || price > _maxPrice) return false;
      }

      
      if (_minRating > 0) {
        if (product.rating < _minRating) return false;
      }

      
      if (_selectedCategories.isNotEmpty) {
        if (!_selectedCategories.contains(product.category)) return false;
      }

      return true;
    }).toList();

    
    switch (_currentSort) {
      case 'PriceLowHigh':
        filteredProducts.sort((a, b) {
          final priceA = a.discountPercentage > 0
              ? a.price * (1 - a.discountPercentage / 100)
              : a.price;
          final priceB = b.discountPercentage > 0
              ? b.price * (1 - b.discountPercentage / 100)
              : b.price;
          return priceA.compareTo(priceB);
        });
        break;
      case 'PriceHighLow':
        filteredProducts.sort((a, b) {
          final priceA = a.discountPercentage > 0
              ? a.price * (1 - a.discountPercentage / 100)
              : a.price;
          final priceB = b.discountPercentage > 0
              ? b.price * (1 - b.discountPercentage / 100)
              : b.price;
          return priceB.compareTo(priceA);
        });
        break;
      case 'RatingHighLow':
        filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'NameAZ':
        filteredProducts.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'NameZA':
        filteredProducts.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'Default':
      default:
        
        break;
    }

    return filteredProducts;
  }

  Widget _buildModernGridView(List<Product> products) {
    final filteredProducts = _filterAndSortProducts(products);

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildModernProductCard(filteredProducts[index]);
      },
    );
  }

  Widget _buildModernListView(List<Product> products) {
    final filteredProducts = _filterAndSortProducts(products);

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildModernListCard(filteredProducts[index]);
      },
    );
  }

  Widget _buildModernProductCard(Product product) {
    return GestureDetector(
      onTap: () async {
        print('🏠 Navigating to product detail: ${product.id}');
        final currentState = context.read<ProductBloc>().state;
        print(
          '🏠 ProductBloc state before navigation: ${currentState.runtimeType}',
        );

        setState(() {
          _isNavigatingToProductDetail = true;
        });

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        );

        print('🏠 Returned from product detail');
        setState(() {
          _isNavigatingToProductDetail = false;
        });
        final stateAfterReturn = context.read<ProductBloc>().state;
        print(
          '🏠 ProductBloc state after return: ${stateAfterReturn.runtimeType}',
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: product.thumbnail,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[50],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[50],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    
                    if (product.discountPercentage > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53E3E),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: BlocBuilder<CartWishlistBloc, CartWishlistState>(
                          builder: (context, state) {
                            bool isInWishlist = false;
                            if (state is CartWishlistLoaded) {
                              isInWishlist = state.wishlist.products.any(
                                (p) => p.id == product.id,
                              );
                            }
                            return IconButton(
                              icon: Icon(
                                isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_outline,
                                color: isInWishlist
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              onPressed: () {
                                context.read<CartWishlistBloc>().add(
                                  WishlistToggleProduct(product: product),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isInWishlist
                                          ? '${product.title} removed from wishlist'
                                          : '${product.title} added to wishlist',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: isInWishlist
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                );
                              },
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Text(
                      product.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < product.rating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color(0xFFFFA726),
                              size: 12,
                            );
                          }),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).textTheme.bodySmall?.color?.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          product.formattedDiscountedPrice,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (product.discountPercentage > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernListCard(Product product) {
    return GestureDetector(
      onTap: () async {
        print('🏠 Navigating to product detail (list): ${product.id}');
        final currentState = context.read<ProductBloc>().state;
        print(
          '🏠 ProductBloc state before navigation (list): ${currentState.runtimeType}',
        );

        setState(() {
          _isNavigatingToProductDetail = true;
        });

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        );

        print('🏠 Returned from product detail (list)');
        final stateAfterReturn = context.read<ProductBloc>().state;
        print(
          '🏠 ProductBloc state after return (list): ${stateAfterReturn.runtimeType}',
        );

        setState(() {
          _isNavigatingToProductDetail = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: product.thumbnail,
                      fit: BoxFit.contain,
                      width: 100,
                      height: 100,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[50],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[50],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  
                  if (product.discountPercentage > 0)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53E3E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product.discountPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Text(
                    product.title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < product.rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFFF8A65),
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${(product.rating * 100).toInt()})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.discountPercentage > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-${product.discountPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      const Spacer(),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF1565C0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: BlocBuilder<CartWishlistBloc, CartWishlistState>(
                          builder: (context, state) {
                            bool isInWishlist = false;
                            if (state is CartWishlistLoaded) {
                              isInWishlist = state.wishlist.products.any(
                                (p) => p.id == product.id,
                              );
                            }
                            return IconButton(
                              onPressed: () {
                                context.read<CartWishlistBloc>().add(
                                  WishlistToggleProduct(product: product),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isInWishlist
                                          ? '${product.title} removed from wishlist'
                                          : '${product.title} added to wishlist',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: isInWishlist
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                );
                              },
                              icon: Icon(
                                isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_outline,
                                size: 16,
                                color: isInWishlist
                                    ? Colors.red
                                    : const Color(0xFF1565C0),
                              ),
                              padding: EdgeInsets.zero,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ProductError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ProductBloc>().add(ProductsRefreshRequested());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).unselectedWidgetColor,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          color: Theme.of(context).unselectedWidgetColor,
        ),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WishlistScreen()),
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: [
        
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 10, 
            itemBuilder: (context, index) {
              return _buildShimmerProductCard();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerProductCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),

            
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(width: 120, height: 14, color: Colors.white),
                    const SizedBox(height: 8),

                    
                    Row(
                      children: [
                        Container(width: 60, height: 12, color: Colors.white),
                      ],
                    ),
                    const Spacer(),

                    
                    Row(
                      children: [
                        Container(width: 40, height: 12, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(width: 60, height: 16, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
