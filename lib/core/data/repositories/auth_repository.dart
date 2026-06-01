// ── AuthRepository interface ───────────────────────────────────────────────────
// The UI layer ONLY depends on this contract — never on Supabase directly.
// Implementations: MockAuthRepository (dev) | SupabaseAuthRepository (prod)

import '../../network/api_exception.dart';
import '../dtos/auth_dto.dart';

abstract class AuthRepository {
  // ── Email + password sign-in ─────────────────────────────────────────────
  Future<Result<LoginResponseDto>> signInWithPassword(LoginRequestDto request);

  // ── Staff PIN sign-in ────────────────────────────────────────────────────
  Future<Result<StaffPinLoginResponseDto>> staffPinLogin(
    StaffPinLoginRequestDto request,
  );

  // ── Resolve app/tenant context after login ───────────────────────────────
  Future<Result<AppContextDto?>> resolveContext();

  // ── Change password (requires active session) ────────────────────────────
  Future<Result<void>> changePassword(String email, String newPassword);

  // ── Configure first login password setup ─────────────────────────────────
  Future<Result<void>> setFirstLoginPassword(String newPassword);

  // ── Sign out ─────────────────────────────────────────────────────────────
  Future<Result<void>> signOut();

  // ── Auth state stream (nullable = logged out) ────────────────────────────
  // Emits null when logged out, user-id string when logged in.
  Stream<String?> get authStateStream;

  // ── Currently authenticated user id ──────────────────────────────────────
  String? get currentUserId;

  // ── Currently authenticated staff member (null if admin or logged out) ───
  StaffDto? get currentStaff;

  // ── Restore persisted session (call once at app start) ────────────────────
  Future<void> restoreSession();
}
