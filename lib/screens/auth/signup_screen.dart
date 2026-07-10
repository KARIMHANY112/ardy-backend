import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_role.dart';
import '../../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Owner accounts are created manually server-side, so signup only offers Buyer/Seller.
  UserRole _role = UserRole.buyer;
  bool _acceptedTerms = false;

  void _signUp() {
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
              Center(child: Image.asset('assets/green_logo.png', height: 96)),
              const SizedBox(height: 24),
              Text('Create your account', style: textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'مصنعك · أرضك · محلك',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.gold),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(30)),
                child: Row(
                  children: [UserRole.buyer, UserRole.seller].map((role) {
                    final selected = role == _role;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = role),
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
                            style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const TextField(decoration: InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 14),
              const TextField(decoration: InputDecoration(labelText: 'Phone number'), keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              const TextField(decoration: InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              const TextField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text('I agree to the Terms & Conditions'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _signUp, child: const Text('Sign Up')),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      children: [TextSpan(text: 'Log in', style: TextStyle(fontWeight: FontWeight.w700))],
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
