import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../state/auth_session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ardi_logo_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/labeled_input_field.dart';

/// Sign Up — direction 1a: large logo lockup, Terms checkbox. Every account
/// created here is a regular user who can both browse and list.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _acceptedTerms = false;
  bool _submitting = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill in all fields')));
      return;
    }
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the Terms & Privacy Policy')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final session = context.read<AuthSession>();
      await session.signup(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      // New signups are always buyers, pending owner approval.
      context.go('/home');
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
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ArdiLogoCard(),
              const SizedBox(height: 20),
              Text('Create your account', textAlign: TextAlign.center, style: AppFonts.cairo(size: 24, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'مصنعك · أرضك · محلك',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: AppFonts.tajawal(size: 12, weight: FontWeight.w400, color: AppColors.gold),
              ),
              const SizedBox(height: 20),
              LabeledInputField(label: 'Full name', controller: _nameController),
              const SizedBox(height: 12),
              LabeledInputField(label: 'Phone number', controller: _phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              LabeledInputField(label: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              LabeledInputField(label: 'Password', controller: _passwordController, obscureText: true),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: _acceptedTerms ? null : Border.all(color: AppColors.divider, width: 1.5),
                        color: _acceptedTerms ? AppColors.nileGreen : null,
                      ),
                      child: _acceptedTerms ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('I agree to the Terms & Privacy Policy', style: AppFonts.tajawal(size: 11, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(label: 'Sign Up', onPressed: _signUp, loading: _submitting),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: AppFonts.tajawal(size: 12, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6)),
                      children: [TextSpan(text: 'Log in', style: AppFonts.tajawal(size: 12, weight: FontWeight.w700, color: AppColors.gold))],
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
