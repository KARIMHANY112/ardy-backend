import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../state/auth_session.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/ardi_logo_card.dart';
import '../../widgets/labeled_input_field.dart';
import '../../widgets/primary_button.dart';

/// Log In — direction 1a: large logo lockup (dark card), right-aligned
/// "Forgot password?".
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.enterEmailAndPassword)));
      return;
    }

    setState(() => _submitting = true);
    try {
      final session = context.read<AuthSession>();
      await session.login(email, password);
      if (!mounted) return;
      context.go(session.user!.role == UserRole.owner ? '/dashboard/owner' : '/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong(e.toString()))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s22, AppSpacing.s40, AppSpacing.s22, AppSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ArdiLogoCard(light: false),
              const SizedBox(height: AppSpacing.s20),
              Text(l10n.welcomeBack, textAlign: TextAlign.center, style: AppFonts.cairo(size: 24, weight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.s20),
              LabeledInputField(label: l10n.phoneOrEmail, controller: _emailController),
              const SizedBox(height: AppSpacing.s12),
              LabeledInputField(label: l10n.password, controller: _passwordController, obscureText: true),
              const SizedBox(height: AppSpacing.s8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.go('/forgot-password'),
                  child: Text(l10n.forgotPassword, style: AppFonts.tajawal(size: 12, weight: FontWeight.w600, color: AppColors.gold)),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              PrimaryButton(label: l10n.logIn, onPressed: _login, loading: _submitting),
              const SizedBox(height: AppSpacing.s16),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/signup'),
                  child: Text.rich(
                    TextSpan(
                      text: l10n.newToArdiPrefix,
                      style: AppFonts.tajawal(size: 12, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6)),
                      children: [TextSpan(text: l10n.createAccount, style: AppFonts.tajawal(size: 12, weight: FontWeight.w700, color: AppColors.gold))],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
