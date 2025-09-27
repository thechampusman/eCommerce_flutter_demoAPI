import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ecommerce/bloc/auth/auth_bloc.dart';
import 'package:ecommerce/bloc/auth/auth_event.dart';
import 'package:ecommerce/bloc/auth/auth_state.dart';
import 'package:ecommerce/models/api_user.dart';



void main() {
  setUpAll(() {
    registerFallbackValue(
      ApiUser(
        id: 1,
        username: 'u',
        firstName: '',
        lastName: '',
        email: '',
        gender: '',
        image: '',
        accessToken: 't',
        refreshToken: 'r',
      ),
    );
  });

  test(
    'AuthBloc login success emits [AuthLoading, AuthAuthenticated]',
    () async {
      
      loginFn = ({required String username, required String password}) async =>
          ApiUser(
            id: 2,
            username: 'emilys',
            firstName: '',
            lastName: '',
            email: '',
            gender: '',
            image: '',
            accessToken: 'a',
            refreshToken: 'b',
          );

      storeUserSessionFn = (user) async {};

      final bloc = AuthBloc();

      bloc.add(
        const AuthLoginRequested(username: 'emilys', password: 'emilyspass'),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );
    },
  );
}
