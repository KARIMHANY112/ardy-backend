import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_role.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _role = UserRole.buyer;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    // Stub: no backend call yet — routes straight to the role's dashboard.
    switch (_role) {
      case UserRole.buyer:
        context.go('/dashboard/buyer');
      case UserRole.seller:
        context.go('/dashboard/seller');
      case UserRole.owner:
        context.go('/dashboard/owner');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset('assets/green_logo.png', height: 96),
              ),
              const SizedBox(height: 24),
              Text('Welcome back', style: textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              _RoleToggle(value: _role, onChanged: (role) => setState(() => _role = role)),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Phone or email'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _login, child: const Text('Log In')),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text.rich(
                    TextSpan(
                      text: 'New to ARDI? ',
                      children: [TextSpan(text: 'Create account', style: TextStyle(fontWeight: FontWeight.w700))],
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

/// Buyer/Seller/Owner segmented toggle used on both Login and Sign Up.
class _RoleToggle extends StatelessWidget {
  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  const _RoleToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.sandy,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: UserRole.values.map((role) {
          final selected = role == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.nileGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  role.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
