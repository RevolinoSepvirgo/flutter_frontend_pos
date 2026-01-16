import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

// Auth State
class AuthState {
  final bool isAuthenticated;
  final String? token;
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.token,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth Provider
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(AuthState()) {
    print('🔵 AuthNotifier: Constructor called');
    print('🔵 Initial state - isAuthenticated: ${state.isAuthenticated}, token: ${state.token}');
    _checkAuth();
  }

  // Check if user is logged in
  Future<void> _checkAuth() async {
    print('🔍 _checkAuth: Starting...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('🔍 _checkAuth: Token from storage: ${token?.substring(0, 20) ?? "null"}');

      if (token != null && token.isNotEmpty) {
        print('🔍 _checkAuth: Token found, validating...');
        
        try {
          final user = await _authService.getUserProfile(token);
          
          print('✅ _checkAuth: Token valid - User: ${user.username}');
          
          state = state.copyWith(
            isAuthenticated: true,
            token: token,
            user: user,
          );
          
          print('✅ _checkAuth: State updated - isAuthenticated: ${state.isAuthenticated}');
        } catch (e) {
          print('❌ _checkAuth: Token invalid - $e');
          await prefs.remove('token');
          state = AuthState();
          print('✅ _checkAuth: State reset to default');
        }
      } else {
        print('ℹ️ _checkAuth: No token found - staying logged out');
        state = AuthState();
        print('✅ _checkAuth: State confirmed as logged out - isAuthenticated: ${state.isAuthenticated}');
      }
    } catch (e) {
      print('❌ _checkAuth: Error - $e');
      state = AuthState();
      print('✅ _checkAuth: State reset due to error');
    }
    
    print('🏁 _checkAuth: Finished - Final state isAuthenticated: ${state.isAuthenticated}');
  }

  // Login
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔄 login: Starting...');
      final response = await _authService.login(email, password);
      final user = await _authService.getUserProfile(response.token);

      print('✅ login: User fetched - ${user.username} (${user.role})');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response.token);

      print('✅ login: Token saved to storage');

      state = state.copyWith(
        isAuthenticated: true,
        token: response.token,
        user: user,
        isLoading: false,
      );

      print('✅ login: State updated - isAuthenticated: ${state.isAuthenticated}');
    } catch (e) {
      print('❌ login: Failed - $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  // Register
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String storeName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
        storeName: storeName,
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    print('🚪 logout: Starting...');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    print('✅ logout: Token removed from storage');

    state = AuthState();
    
    print('✅ logout: State reset - isAuthenticated: ${state.isAuthenticated}');
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (state.token != null) {
      try {
        final user = await _authService.getUserProfile(state.token!);
        state = state.copyWith(user: user);
        print('✅ refreshUser: User data refreshed');
      } catch (e) {
        print('❌ refreshUser: Failed - $e');
      }
    }
  }
}

// Provider instance
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});