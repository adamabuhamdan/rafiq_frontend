import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../../providers/network_provider.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isOtpSent;
  final bool isAuthenticated;
  final String? userId;
  final bool isInitializing;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isOtpSent = false,
    this.isAuthenticated = false,
    this.userId,
    this.isInitializing = true,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isOtpSent,
    bool? isAuthenticated,
    String? userId,
    bool? isInitializing,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    try {
      final userId = await _authService.getLoggedUserId();
      if (userId != null) {
        state = state.copyWith(
            isAuthenticated: true, userId: userId, isInitializing: false);
      } else {
        state = state.copyWith(isInitializing: false);
      }
    } catch (e) {
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> sendOtp(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.sendOtp(email);
      state = state.copyWith(isLoading: false, isOtpSent: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> verifyOtp(String email, String token) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _authService.verifyOtp(email, token);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userId: response['user_id'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
