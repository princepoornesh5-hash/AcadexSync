import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/role_enum.dart';
import '../../domain/models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../../services/session_manager.dart';
import '../../../notifications/data/repositories/api_notification_repository.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../analytics/presentation/providers/analytics_providers.dart';

// Providers for dependencies
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager(ref.watch(secureStorageProvider));
});

final apiAuthRepositoryProvider = Provider<ApiAuthRepository>((ref) {
  return ApiAuthRepository();
});

/// Production auth repository: Always uses the authoritative REST API repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ref.watch(apiAuthRepositoryProvider);
});

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SessionManager _sessionManager;
  final ApiClient _apiClient;
  final Ref? _ref;

  AuthNotifier(
    this._repository,
    this._sessionManager, [
    dynamic refOrClient,
    ApiClient? client,
  ])  : _ref = refOrClient is Ref ? refOrClient : null,
        _apiClient = refOrClient is ApiClient
            ? refOrClient
            : (client ?? apiClient),
        super(const AuthInitial()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    state = const AuthProfileLoading();
    final sw = Stopwatch()..start();
    debugPrint('[AUTH_RESTORE_START]');
    try {
      final token = await _sessionManager.getAccessToken() ?? await _apiClient.getToken();
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        debugPrint('[AUTH_RESTORE_END] (${sw.elapsedMilliseconds}ms): No token -> AuthUnauthenticated');
        state = const AuthUnauthenticated();
        return;
      }

      // Fast restore: check cached user profile first for instant UI transition
      final cachedUser = await _sessionManager.getUser();
      if (cachedUser != null && mounted) {
        debugPrint('[AUTH_RESTORE_END] (${sw.elapsedMilliseconds}ms): Fast-restored cached user ${cachedUser.name} (${cachedUser.role.displayName})');
        state = AuthAuthenticated(user: cachedUser, token: token);
      }

      // Background revalidation with remote backend
      final user = await _repository.getCurrentUser();
      if (!mounted) return;
      if (user != null) {
        if (user.accountStatus != AccountStatus.active) {
          state = AuthError(message: 'Your account is ${user.accountStatus.name}. Access denied.');
          await _repository.logout();
          await _sessionManager.clearSession();
          return;
        }
        await _sessionManager.saveSession(token: token, user: user);
        if (!mounted) return;
        state = AuthAuthenticated(user: user, token: token);
        await _manageFcmToken(true, user.id);
      } else if (cachedUser == null) {
        await _sessionManager.clearSession();
        if (!mounted) return;
        debugPrint('[AUTH_INIT] _restoreSession: User is null. Setting state to AuthUnauthenticated');
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      debugPrint('[AUTH_INIT] _restoreSession error: $e');
      if (state is! AuthAuthenticated) {
        await _sessionManager.clearSession();
        if (!mounted) return;
        state = const AuthUnauthenticated();
      }
    }
  }

  void _invalidateUserScopedCaches() {
    if (_ref == null) return;
    try {
      // Invalidate notifications & activity
      _ref.invalidate(notificationsProvider);
      _ref.invalidate(unreadNotificationCountProvider);
      
      // Invalidate user notes & personal schedules
      _ref.invalidate(userNotesProvider);
      _ref.invalidate(myFacultyAssignmentsProvider);
      _ref.invalidate(todayScheduleProvider);
      _ref.invalidate(currentStudentAcademicProfileProvider);
      
      // Invalidate role dashboard stats
      _ref.invalidate(studentStatsProvider);
      _ref.invalidate(facultyStatsProvider);
      _ref.invalidate(hodStatsProvider);
      _ref.invalidate(collegeAdminStatsProvider);
      _ref.invalidate(superAdminStatsProvider);
      
      // Invalidate reports & analytics
      _ref.invalidate(roleDashboardReportProvider);
      _ref.invalidate(myAttendanceReportProvider);
      _ref.invalidate(analyticsSummaryProvider);
      _ref.invalidate(trendChartProvider);
      _ref.invalidate(comparisonChartProvider);
      _ref.invalidate(insightsProvider);
      _ref.invalidate(recentReportsProvider);
    } catch (_) {}
  }

  Future<void> login(String identifier, String password) async {
    state = const AuthLoading();
    try {
      final user = await _repository.login(identifier, password);
      final token = await _sessionManager.getAccessToken() ?? await _apiClient.getToken() ?? 'token';
      
      await _sessionManager.saveSession(token: token, user: user);
      _invalidateUserScopedCaches();
      state = AuthAuthenticated(user: user, token: token);
      await _manageFcmToken(true, user.id);
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      state = AuthError(message: cleanMsg);
    }
  }

  Future<void> loginAsDevelopmentRole(AppRole role) async {
    state = const AuthLoading();
    try {
      final user = await _repository.loginAsDevelopmentRole(role);
      const token = 'dev-token';
      await _sessionManager.saveSession(token: token, user: user);
      _invalidateUserScopedCaches();
      state = AuthAuthenticated(user: user, token: token);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      final user = state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;
      if (user != null) {
        await _manageFcmToken(false, user.id);
      }
      await _repository.logout();
    } catch (_) {
      // Best effort remote logout
    } finally {
      await _sessionManager.clearSession();
      _invalidateUserScopedCaches();
      state = const AuthUnauthenticated();
    }
  }

  Future<void> logoutAll() async {
    state = const AuthLoading();
    try {
      final user = state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;
      if (user != null) {
        await _manageFcmToken(false, user.id);
      }
      await _repository.logoutAll();
    } catch (_) {
      // Best effort remote logout
    } finally {
      await _sessionManager.clearSession();
      _invalidateUserScopedCaches();
      state = const AuthUnauthenticated();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _repository.sendPasswordResetEmail(email);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  void updateCurrentUser(UserModel updatedUser) {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      state = AuthAuthenticated(user: updatedUser, token: currentState.token);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      throw Exception(cleanMsg);
    }
  }

  Future<void> _manageFcmToken(bool isLogin, String uid) async {
    try {
      final messaging = fcm.FirebaseMessaging.instance;
      
      if (isLogin) {
        if (!kIsWeb) {
          final settings = await messaging.requestPermission();
          if (settings.authorizationStatus != fcm.AuthorizationStatus.authorized) return;
        } else {
          await messaging.requestPermission();
        }
        
        final token = await messaging.getToken();
        if (token != null) {
          try {
            final platform = kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
            await ApiNotificationRepository().registerDeviceToken(deviceToken: token, platform: platform);
          } catch (_) {}
        }
      } else {
        final token = await messaging.getToken();
        if (token != null) {
          try {
            await ApiNotificationRepository().removeDeviceToken(token);
          } catch (_) {}
          await messaging.deleteToken();
        }
      }
    } catch (e) {
      debugPrint('FCM Error: $e');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionManagerProvider),
    ref,
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

final currentUserProvider = Provider<UserModel?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) {
    return state.user;
  }
  return null;
});

