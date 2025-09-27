class ApiService {
  static const String baseUrl =
      'https://jsonplaceholder.typicode.com'; 

  
  Future<Map<String, dynamic>> login(String email, String password) async {
    
    await Future.delayed(const Duration(seconds: 2));

    
    if (email.isNotEmpty && password.isNotEmpty) {
      if (email == 'demo@example.com' && password == 'password123') {
        return {
          'success': true,
          'user': {
            'id': '1',
            'email': email,
            'name': 'Demo User',
            'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          },
        };
      } else {
        return {'success': false, 'message': 'Invalid email or password'};
      }
    }

    return {'success': false, 'message': 'Please fill in all fields'};
  }

  
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    
    await Future.delayed(const Duration(seconds: 2));

    
    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      if (email.contains('@') && password.length >= 6) {
        return {
          'success': true,
          'user': {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'email': email,
            'name': name,
            'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          },
        };
      } else {
        return {
          'success': false,
          'message':
              'Please enter a valid email and password (min 6 characters)',
        };
      }
    }

    return {'success': false, 'message': 'Please fill in all fields'};
  }

  
  Future<bool> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
