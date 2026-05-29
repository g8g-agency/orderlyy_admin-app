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
    // For admin users, the Supabase SDK automatically restores the session.
    // In the future, we could call an API endpoint to validate the session.
    final session = _supabaseClient.auth.currentSession;
    if (session != null) {
      _currentUserId = session.user.id;
      _currentStaff = null;
      _authStateController.add(_currentUserId);
      debugPrint('[ApiAuth] Restored admin session: $_currentUserId');
    } else {
      _currentUserId = null;
      _currentStaff = null;
      _authStateController.add(null);
      debugPrint('[ApiAuth] No active session restored.');
    }
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
      final res = await _dioClient.get(ApiConstants.currentTenant);

      if (res.data['success'] == true) {
        return Success(AppContextDto.fromJson(res.data['data']));
      }
      return const Success(null);
    } on ApiException catch (e) {
      if (e.code == ApiErrorCode.unauthorized) {
        await signOut();
        return const Success(null);
      }
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> changePassword(String email, String newPassword) async {
    try {
      // Assuming backend has a change-password route or we use Supabase GoTrue directly
      final res = await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (res.user == null) {
        return Failure(ApiFailure('Failed to update password'));
      }
      return const Success(null);
    } on AuthException catch (e) {
      return Failure(ApiFailure(e.message, ApiErrorCode.unauthorized));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _dioClient.post(ApiConstants.logout);
    } catch (_) {
      // Ignore network errors on logout
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
