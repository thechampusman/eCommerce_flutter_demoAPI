import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ecommerce/bloc/cart_wishlist/cart_wishlist_bloc.dart';
import 'package:ecommerce/bloc/cart_wishlist/cart_wishlist_event.dart';
import 'package:ecommerce/bloc/cart_wishlist/cart_wishlist_state.dart';
import 'package:ecommerce/services/database_service.dart';
import 'package:ecommerce/models/cart_wishlist.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();
    databaseServiceImpl = () => mockDb; 
  });

  test('CartLoadRequested emits CartWishlistLoaded when DB has data', () async {
    final emptyCart = Cart.empty();
    final emptyWishlist = Wishlist.empty();

    when(() => mockDb.getCart()).thenAnswer((_) async => emptyCart);
    when(() => mockDb.getWishlist()).thenAnswer((_) async => emptyWishlist);

    final bloc = CartWishlistBloc();

    bloc.add(CartLoadRequested());

    await expectLater(
      bloc.stream,
      emitsInOrder([isA<CartWishlistLoading>(), isA<CartWishlistLoaded>()]),
    );
  });
}
