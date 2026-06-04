import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../network/api_exception.dart';
import '../../network/dio_client.dart';
import '../../constants/api_constants.dart';
import '../repositories/auth_repository.dart';
import '../dtos/auth_dto.dart';

class ApiAuthRepository implements AuthRepository {
  final DioClient _dioClient;
  final SupabaseClient _supabaseClient; // Used strictly for Auth SDK lifecycle

  String? _currentUserId;
  StaffDto? _currentStaff;
  final _authStateController = StreamController<String?>.broadcast();
  late final StreamSubscription<AuthState> _authSubscription;

  ApiAuthRepository(this._dioClient, this._supabaseClient) {
    _authSubscription = _supabaseClient.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      // If we are logged in as staff (custom token/session logic), ignore GoTrue auth events for now
      if (_currentUserId != null && _currentUserId!.startsWith('staff-')) {
        return;
      }

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        _currentUserId = session?.user.id;
        _currentStaff = null;
        _authStateController.add(_currentUserId);
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUserId = null;
        _currentStaff = null;
        _authStateController.add(null);
      }
    });
  }

  void dispose() {
    _authSubscription.cancel();
    _authStateController.close();
  }

  @override
  Stream<String?> get authStateStream => _authStateController.stream;

  @override
  String? get currentUserId =>
      _currentUserId ?? _supabaseClient.auth.currentUser?.id;

  @override
  StaffDto? get currentStaff => _currentStaff;

  @override
  Future<void> restoreSession() async {
    var session = _supabaseClient.auth.currentSession;
    if (session == null) {
      _clearLocalAuthState();
      debugPrint('[ApiAuth] No active session restored.');
      return;
    }

    if (session.isExpired) {
      if (session.refreshToken == null) {
        debugPrint('[ApiAuth] Expired session without refresh token — signing out.');
        await _signOutSilently();
        return;
      }
      try {
        final refreshed = await _supabaseClient.auth.refreshSession();
        session = refreshed.session;
        if (session == null) {
          debugPrint('[ApiAuth] Refresh returned no session — signing out.');
          await _signOutSilently();
          return;
        }
      } catch (e) {
        debugPrint('[ApiAuth] Failed to refresh expired session: $e');
        await _signOutSilently();
        return;
      }
    }

    _currentUserId = session.user.id;
    _currentStaff = null;
    _authStateController.add(_currentUserId);
    debugPrint('[ApiAuth] Restored admin session: $_currentUserId');
  }

  void _clearLocalAuthState() {
    _currentUserId = null;
    _currentStaff = null;
    _authStateController.add(null);
  }

  Future<void> _signOutSilently() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (_) {}
    _clearLocalAuthState();
  }

  @override
  Future<Result<LoginResponseDto>> signInWithPassword(
    LoginRequestDto request,
  ) async {
    try {
      // 1. Sign in using Supabase Auth SDK
      // Note: We are keeping Supabase SDK for Auth as requested by the user.
      final response = await _supabaseClient.auth.signInWithPassword(
        email: request.email,
        password: request.password,
      );

      final user = response.user;
      if (user == null) {
        return Failure(
          ApiFailure(
            'Authentication failed: user is null',
            ApiErrorCode.unauthorized,
          ),
        );
      }

      _currentUserId = user.id;
      _currentStaff = null;
      _authStateController.add(_currentUserId);

      // We can also call the backend login endpoint here if it does additional setup
      // but for now Supabase GoTrue acts as our JWT provider.

      return Success(
        LoginResponseDto(
          userId: user.id,
          email: user.email ?? request.email,
          accessToken: response.session?.accessToken,
          isSuccess: true,
        ),
      );
    } on AuthException catch (e) {
      return Failure(ApiFailure(e.message, ApiErrorCode.unauthorized));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<StaffPinLoginResponseDto>> staffPinLogin(
    StaffPinLoginRequestDto request,
  ) async {
    try {
      // Call Backend REST API for Staff Pin Login
      final res = await _dioClient.post(
        ApiConstants.login,
        data: {
          'tenantSlug': request.tenantSlug,
          'pin': request.pin,
          'type': 'staff_pin',
        },
      );

      if (res.data['success'] == true) {
        final staffData = res.data['data']['staff'];
        final staff = StaffDto.fromJson(staffData);

        _currentUserId = staff.id;
        _currentStaff = staff;
        _authStateController.add(_currentUserId);

        // Here we'd also expect a custom JWT to be returned by our backend
        // that we can feed to Supabase SDK if needed, or store securely.
        // For now, assume backend provides a token.
        if (res.data['data']['session'] != null) {
          final token = res.data['data']['session']['access_token'];
          await _supabaseClient.auth.setSession(token);
        }

        return Success(StaffPinLoginResponseDto(isSuccess: true, staff: staff));
      } else {
        return Failure(
          ApiFailure(
            'Invalid PIN or restaurant code.',
            ApiErrorCode.unauthorized,
          ),
        );
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<AppContextDto?>> resolveContext() async {
    try {
      debugPrint('[ApiAuth] 📡 Calling GET ${ApiConstants.currentTenant}');
      final res = await _dioClient.get(ApiConstants.currentTenant);
      debugPrint('[ApiAuth] 📡 Response received. Status: ${res.statusCode}');
      debugPrint('[ApiAuth] 📡 Response data: ${res.data}');

      if (res.data['success'] == true) {
        debugPrint('[ApiAuth] ✅ Success response, parsing context...');
        final context = AppContextDto.fromJson(res.data['data']);
        debugPrint('[ApiAuth] ✅ Context parsed successfully');
        return Success(context);
      }
      debugPrint('[ApiAuth] ⚠️ Success=false or missing, returning null');
      return const Success(null);
    } on ApiException catch (e) {
      debugPrint('[ApiAuth] ❌ ApiException: ${e.message} (code: ${e.code})');
      if (e.code == ApiErrorCode.unauthorized) {
        // Do not sign out here — bootstrap handles auth errors without clearing session.
        return Failure(ApiFailure(e.message, e.code));
      }
      return Failure(ApiFailure(e.message, e.code));
    } catch (e, stackTrace) {
      debugPrint('[ApiAuth] 💥 Unexpected error: $e');
      debugPrint('[ApiAuth] 💥 Stack trace: $stackTrace');
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> changePassword(String email, String newPassword) async {
    try {
      final res = await _dioClient.post(
        ApiConstants.changePassword,
        data: {
          'new_password': newPassword,
          'confirm_password': newPassword,
        },
      );

      if (res.data != null && res.data['success'] == true) {
        return const Success(null);
      } else {
        return Failure(
          ApiFailure(res.data?['message'] ?? 'Failed to update password'),
        );
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> setFirstLoginPassword(String newPassword) async {
    try {
      final res = await _dioClient.post(
        ApiConstants.setFirstLoginPassword,
        data: {
          'new_password': newPassword,
          'confirm_password': newPassword,
        },
      );

      if (res.data != null && res.data['success'] == true) {
        return const Success(null);
      } else {
        return Failure(
          ApiFailure(res.data?['message'] ?? 'Failed to configure password'),
        );
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    // Backend logout requires a valid JWT — skip if session was already cleared
    // (e.g. forced sign-out from Dio 401 handler during bootstrap failure).
    final session = _supabaseClient.auth.currentSession;
    if (session?.accessToken != null) {
      try {
        await _dioClient.post(ApiConstants.logout);
      } catch (_) {
        // Ignore network errors on logout
      }
    }

    try {
      await _supabaseClient.auth.signOut();
    } catch (_) {}

    _currentUserId = null;
    _currentStaff = null;
    _authStateController.add(null);
    return const Success(null);
  }
}
