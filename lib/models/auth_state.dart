import 'user.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthStateData {
  final AuthState state;
  final User? user;
  final String? errorMessage;

  const AuthStateData({required this.state, this.user, this.errorMessage});

  AuthStateData copyWith({AuthState? state, User? user, String? errorMessage}) {
    return AuthStateData(
      state: state ?? this.state,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
