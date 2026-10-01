import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/validators.dart';

/// Login screen - email-only OTP login via Supabase
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isBypassLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: _emailController.text.trim(),
        shouldCreateUser: true,
      );
      if (mounted) {
        context.push(AppRoutes.otp, extra: _emailController.text.trim());
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = _friendlyAuthError(e.message));
    } catch (e) {
      setState(
          () => _errorMessage = 'Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyAuthError(String message) {
    if (message.contains('rate limit')) {
      return 'Too many requests. Please wait a moment before trying again.';
    }
    if (message.contains('invalid')) {
      return 'Invalid email address. Please check and try again.';
    }
    return 'Unable to send OTP. Please try again.';
  }

  // ── DEV BYPASS ──────────────────────────────────────────────────────────
  // Signs in with email + password — skips OTP entirely.
  // Visible only in debug builds. To activate:
  //   Supabase dashboard → Authentication → Users → Add user
  //   Email: dev@medtrack.test   Password: DevPass@123
  static const _devEmail = 'dev@medtrack.test';
  static const _devPassword = 'DevPass@123';

  Future<void> _devBypass() async {
    setState(() { _isBypassLoading = true; _errorMessage = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _devEmail,
        password: _devPassword,
      );
      if (mounted) context.go(AppRoutes.home);
    } on AuthException catch (e) {
      setState(() => _errorMessage =
          'Dev bypass failed: ${e.message}\n'
          'Go to Supabase → Authentication → Users → Add user\n'
          'Email: $_devEmail   Password: $_devPassword');
    } catch (_) {
      setState(() => _errorMessage = 'Dev bypass: network error.');
    } finally {
      if (mounted) setState(() => _isBypassLoading = false);
    }
  }
  // ────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Logo + branding
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.local_pharmacy_rounded,
                        size: 38,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('MedTrack', style: AppTextStyles.display),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome Back',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.grey500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to your pharmacy account',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email Address', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      onFieldSubmitted: (_) => _sendOtp(),
                      decoration: const InputDecoration(
                        hintText: 'your@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validators.email,
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 16,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: 'Send OTP',
                      icon: Icons.send_rounded,
                      onPressed: _sendOtp,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Terms
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTextStyles.caption,
                      children: [
                        const TextSpan(
                            text: 'By continuing, you agree to our '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── DEV BYPASS (debug builds only) ──────────────────
              if (kDebugMode) _buildDevBypass(),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevBypass() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFB26A00).withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.developer_mode_rounded,
                      size: 14, color: Color(0xFFB26A00)),
                  SizedBox(width: 6),
                  Text(
                    'DEV BYPASS — debug build only',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB26A00),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Signs in as dev@medtrack.test (password: DevPass@123)\n'
                'Create this user in Supabase → Authentication → Users first.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Color(0xFFB26A00),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isBypassLoading ? null : _devBypass,
                  icon: _isBypassLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFB26A00),
                          ),
                        )
                      : const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('Skip OTP — Dev Login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB26A00),
                    side: const BorderSide(color: Color(0xFFB26A00)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
