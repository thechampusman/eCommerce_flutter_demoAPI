import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/auth/auth_state.dart';
import 'bloc/products/product_bloc.dart';
import 'bloc/cart_wishlist/cart_wishlist_bloc.dart';
import 'bloc/cart_wishlist/cart_wishlist_event.dart';
import 'bloc/theme/theme_bloc.dart';
import 'bloc/theme/theme_event.dart';
import 'bloc/theme/theme_state.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ShopSphereApp());
}

class ShopSphereApp extends StatelessWidget {
  const ShopSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()..add(AuthStarted())),
        BlocProvider(create: (context) => ProductBloc()),
        BlocProvider(
          create: (context) => CartWishlistBloc()..add(CartLoadRequested()),
        ),
        BlocProvider(create: (context) => ThemeBloc()..add(ThemeInitialized())),
      ],
      child: _AppWithAuthListener(
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'ShopSphere',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeState is ThemeLoaded && themeState.isDarkMode
                  ? ThemeMode.dark
                  : ThemeMode.light,
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}

class _AppWithAuthListener extends StatelessWidget {
  final Widget child;

  const _AppWithAuthListener({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        
        if (state is AuthUnauthenticated || state is AuthSkipped) {
          context.read<CartWishlistBloc>().add(ClearUserData());
        }
      },
      child: child,
    );
  }
}
