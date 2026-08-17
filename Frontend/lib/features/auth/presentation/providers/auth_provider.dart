import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/role_enum.dart';
import '../../domain/models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/firebase_auth_repository.dart';
import '../../services/session_manager.dart';

import '../../../users/presentation/providers/user_profile_providers.dart';

// Providers for dependencies
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager(ref.watch(secureStorageProvider));
});

// We switch between FirebaseAuthRepository and MockAuthRepository based on initialization
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return MockAuthRepository();
  }
  final authService = ref.watch(firebaseAuthServiceProvider);
  final userProfileRepo = ref.watch(userProfileRepositoryProvider);
  return FirebaseAuthRepository(authService, userProfileRepo);
});

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SessionManager _sessionManager;
  final FirebaseAuthService _firebaseAuthService;
  StreamSubscription<firebase.User?>? _authStateSubscription;

  AuthNotifier(this._repository, this._sessionManager, this._firebaseAuthService) : super(const AuthInitial()) {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _authStateSubscription = _firebaseAuthService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        // User is logged out in Firebase
        await _sessionManager.clearSession();
        if (state is! AuthUnauthenticated) {
          state = const AuthUnauthenticated();
        }
      } else {
        // User is logged in to Firebase, need to fetch profile if not already authenticated or loading
        if (state is! AuthAuthenticated && state is! AuthProfileLoading) {
          await _loadProfile(firebaseUser.uid);
        }
      }
    });
  }

  Future<void> _loadProfile(String uid) async {
    state = const AuthProfileLoading();
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        if (user.accountStatus != AccountStatus.active) {
          state = AuthError(message: 'Your account is ${user.accountStatus.name}. Access denied.');
          await _firebaseAuthService.signOut();
          return;
        }
        final token = await _firebaseAuthService.currentUser?.getIdToken() ?? 'token';
        await _sessionManager.saveSession(token: token, user: user);
        state = AuthAuthenticated(user: user, token: token);
      } else {
        state = const AuthProfileError(message: 'Profile not found. Please contact support.');
      }
    } catch (e) {
      state = AuthProfileError(message: e.toString());
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await _repository.login(email, password);
      final token = await _firebaseAuthService.currentUser?.getIdToken() ?? 'token';
      
      await _sessionManager.saveSession(token: token, user: user);
      state = AuthAuthenticated(user: user, token: token);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  Future<void> loginAsDevelopmentRole(AppRole role) async {
    state = const AuthLoading();
    try {
      final user = await _repository.loginAsDevelopmentRole(role);
      final token = 'dev-token'; // mock token
      await _sessionManager.saveSession(token: token, user: user);
      state = AuthAuthenticated(user: user, token: token);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _repository.logout();
      await _sessionManager.clearSession();
      // State is handled by _authStateSubscription (will emit null)
    } catch (e) {
      // Even if backend fails, clear local session
      await _sessionManager.clearSession();
      state = const AuthUnauthenticated();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _repository.sendPasswordResetEmail(email);
    } catch (e) {
      throw Exception(e.toString()); // Handled by UI
    }
  }

  void updateCurrentUser(UserModel updatedUser) {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      state = AuthAuthenticated(user: updatedUser, token: currentState.token);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionManagerProvider),
    ref.watch(firebaseAuthServiceProvider),
  );
});

// Helper provider to get current role based on auth state
final currentUserRoleProvider = Provider<AppRole?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) {
    return state.user.role;
  }
  return null;
});

