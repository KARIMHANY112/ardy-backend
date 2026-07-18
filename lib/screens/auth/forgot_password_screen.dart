import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../state/auth_session.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/ardi_logo_card.dart';
import '../../widgets/labeled_input_field.dart';
import '../../widgets/primary_button.dart';

/// Forgot password — step 1 requests an emailed code, step 2 enters that
/// code plus a new password. Both steps live on one screen since it's a
/// short, linear flow.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your email')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<AuthSession>().requestPasswordReset(email);
      if (!mounted) return;
      setState(() => _codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('If that email is registered, a code was sent')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;
    if (code.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the code and a new password')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final session = context.read<AuthSession>();
      await session.resetPassword(email: _emailController.text.trim(), code: code, newPassword: newPassword);
      if (!mounted) return;
      context.go(session.user!.role == UserRole.owner ? '/dashboard/owner' : '/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s22, AppSpacing.s40, AppSpacing.s22, AppSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Icon(Icons.arrow_back, color: AppColors.ink),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              const ArdiLogoCard(light: false),
              const SizedBox(height: AppSpacing.s20),
              Text('Reset password', textAlign: TextAlign.center, style: AppFonts.cairo(size: 24, weight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.s8),
              Text(
                _codeSent ? 'Enter the code we sent to ${_emailController.text.trim()} and choose a new password.' : "Enter your email and we'll send you a reset code.",
                textAlign: TextAlign.center,
                style: AppFonts.tajawal(size: 13, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6)),
              ),
              const SizedBox(height: AppSpacing.s20),
              LabeledInputField(label: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
              if (_codeSent) ...[
                const SizedBox(height: AppSpacing.s12),
                LabeledInputField(label: 'Reset code', controller: _codeController, keyboardType: TextInputType.number),
                const SizedBox(height: AppSpacing.s12),
                LabeledInputField(label: 'New password', controller: _newPasswordController, obscureText: true),
              ],
              const SizedBox(height: AppSpacing.s20),
              PrimaryButton(
                label: _codeSent ? 'Reset password' : 'Send reset code',
                onPressed: _codeSent ? _resetPassword : _requestCode,
                loading: _submitting,
              ),
              if (_codeSent) ...[
                const SizedBox(height: AppSpacing.s16),
                Center(
                  child: GestureDetector(
                    onTap: _submitting ? null : _requestCode,
                    child: Text("Didn't get a code? Resend", style: AppFonts.tajawal(size: 12, weight: FontWeight.w600, color: AppColors.gold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
