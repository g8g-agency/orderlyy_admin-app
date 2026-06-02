import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/app_auth_provider.dart';
import '../../core/providers/repository_providers.dart';

class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String _errorMessage = '';

  // Real-time validation states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validatePasswordRealtime);
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_validatePasswordRealtime);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePasswordRealtime() {
    final value = _newPasswordController.text;
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(RegExp(r'[@$!%*?&]'));
    });
  }

  bool _isPasswordValid() {
    return _hasMinLength &&
        _hasUppercase &&
        _hasLowercase &&
        _hasNumber &&
        _hasSpecialChar;
  }

  Future<void> _handleSetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isPasswordValid()) {
      setState(() => _errorMessage = 'Please meet all password requirements');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.setFirstLoginPassword(_newPasswordController.text);

      if (result is Failure) {
        throw Exception(result.error.message);
      }

      // Refresh application context so is_first_login becomes false
      await ref.read(appContextProvider.notifier).resolveContext();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password configured. Welcome to your dashboard!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isMet ? Colors.green : AppTheme.secondary.withValues(alpha: 0.5),
            size: 16.r,
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: isMet ? AppTheme.onSurface : AppTheme.secondary,
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Icon + Title ─────────────────────────────────────────
                  Container(
                    width: 64.r,
                    height: 64.r,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 36.r,
                      color: AppTheme.primaryContainer,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Configure your password',
                    style: GoogleFonts.inter(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Please set up a strong, secure password for your first login.',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppTheme.secondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  
                  // Real-time Requirements panel
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppTheme.surfaceContainerHigh,
                        width: 1.w,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Requirements:',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        _buildRequirementRow('Minimum 8 characters', _hasMinLength),
                        _buildRequirementRow('At least 1 uppercase letter', _hasUppercase),
                        _buildRequirementRow('At least 1 lowercase letter', _hasLowercase),
                        _buildRequirementRow('At least 1 number', _hasNumber),
                        _buildRequirementRow('At least 1 special character (@\$!%*?&)', _hasSpecialChar),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── Form ─────────────────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error banner
                        if (_errorMessage.isNotEmpty) ...[
                          Container(
                            margin: EdgeInsets.only(bottom: 16.h),
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: const Color(0xFFEF4444),
                                  size: 16.r,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: const Color(0xFFEF4444),
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // New password
                        Text(
                          'New Password',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.secondary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: AppTheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: GoogleFonts.inter(
                              color: AppTheme.secondary.withValues(alpha: 0.5),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            filled: true,
                            fillColor: AppTheme.surface,
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.surfaceContainerHigh,
                                width: 2.w,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.surfaceContainerHigh,
                                width: 2.w,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.primaryContainer,
                                width: 2.w,
                              ),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscureNew = !_obscureNew),
                              icon: Icon(
                                _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppTheme.secondary,
                                size: 20.r,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Confirm password
                        Text(
                          'Confirm Password',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.secondary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: AppTheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: GoogleFonts.inter(
                              color: AppTheme.secondary.withValues(alpha: 0.5),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            filled: true,
                            fillColor: AppTheme.surface,
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.surfaceContainerHigh,
                                width: 2.w,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.surfaceContainerHigh,
                                width: 2.w,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.primaryContainer,
                                width: 2.w,
                              ),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppTheme.secondary,
                                size: 20.r,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please confirm your password';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleSetPassword(),
                        ),
                        SizedBox(height: 28.h),

                        SizedBox(
                          width: double.infinity,
                          height: 52.h,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryContainer,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 20.r,
                                    height: 20.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Save Password & Continue',
                                    style: GoogleFonts.inter(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
