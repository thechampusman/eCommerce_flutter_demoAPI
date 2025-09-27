import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_api_service.dart';
import '../../services/secure_storage_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';



Future<bool> Function()? isUserSkippedFn = () =>
    SecureStorageService.isUserSkipped();
Future<dynamic> Function()? getUserSessionFn = () =>
    SecureStorageService.getUserSession();
Future<void> Function(dynamic user)? storeUserSessionFn = (user) =>
    SecureStorageService.storeUserSession(user);
Future<void> Function()? clearUserSessionFn = () =>
    SecureStorageService.clearUserSession();
Future<String?> Function()? getRefreshTokenFn = () =>
    SecureStorageService.getRefreshToken();
Future<dynamic> Function({required String username, required String password})?
loginFn = ({required String username, required String password}) =>
    AuthApiService.login(username: username, password: password);
Future<dynamic> Function(String accessToken)? getCurrentUserFn =
    (accessToken) => AuthApiService.getCurrentUser(accessToken);
Future<dynamic> Function(String refreshToken)? refreshAccessTokenFn =
    (refreshToken) => AuthApiService.refreshAccessToken(refreshToken);
Future<void> Function(bool skipped)? setUserSkippedFn = (skipped) =>
    SecureStorageService.setUserSkipped(skipped);

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthRefreshTokenRequested>(_onAuthRefreshTokenRequested);
    on<AuthSkipRequested>(_onAuthSkipRequested);
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    print('🟡 AuthBloc: AuthStarted event received');
    emit(AuthLoading());

    try {
      print('🟡 AuthBloc: Checking if user skipped login...');
      final isSkipped = await isUserSkippedFn!();
      print('🟡 AuthBloc: User skipped: $isSkipped');
      if (isSkipped) {
        print('🟡 AuthBloc: Emitting AuthSkipped');
        emit(AuthSkipped());
        return;
      }

      final storedUser = await getUserSessionFn!();
      if (storedUser != null) {
        try {
          final currentUser = await getCurrentUserFn!(storedUser.accessToken);
          emit(
            AuthAuthenticated(
              user: currentUser.copyWith(
                accessToken: storedUser.accessToken,
                refreshToken: storedUser.refreshToken,
              ),
            ),
          );
        } catch (e) {
          if (storedUser.refreshToken.isNotEmpty) {
            add(AuthRefreshTokenRequested());
          } else {
            await SecureStorageService.clearUserSession();
            emit(AuthUnauthenticated());
          }
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await loginFn!(
        username: event.username,
        password: event.password,
      );

      await storeUserSessionFn!(user);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await clearUserSessionFn!();
    emit(AuthUnauthenticated());
  }

  Future<void> _onAuthRefreshTokenRequested(
    AuthRefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final refreshToken = await getRefreshTokenFn!();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final user = await refreshAccessTokenFn!(refreshToken);
        await storeUserSessionFn!(user);
        emit(AuthAuthenticated(user: user));
      } else {
        await clearUserSessionFn!();
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      await SecureStorageService.clearUserSession();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthSkipRequested(
    AuthSkipRequested event,
    Emitter<AuthState> emit,
  ) async {
    await setUserSkippedFn!(true);
    emit(AuthSkipped());
  }
}
