import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../state/auth_session.dart';
import '../theme/app_theme.dart';
import '../widgets/ardi_wordmark.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrapAndRoute();
  }

  Future<void> _bootstrapAndRoute() async {
    final session = context.read<AuthSession>();
    // Keep the splash on screen a beat even on a fast/local backend, and let
    // both the minimum delay and the session bootstrap race in parallel.
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      session.bootstrap(),
    ]);
    if (!mounted) return;

    final user = session.user;
    if (user == null) {
      context.go('/login');
    } else if (user.role == UserRole.owner) {
      context.go('/dashboard/owner');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.deepGreen,
      body: Center(
        child: ArdiWordmark(light: false, arabicSize: 40, latinSize: 15, letterSpacing: 5),
      ),
    );
  }
}
