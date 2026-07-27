import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_dimens.dart';

/// Shared bottom tab bar (Home, Saved, Advisor, Profile) per the design
/// handoff. Wrap each of the top-level screens in this so navigation
/// between them is always visible. Screens build their own header inline in
/// [body] — none of them use a native AppBar in the design.
class AppBottomNavScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget body;
  final Color backgroundColor;

  const AppBottomNavScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
    this.backgroundColor = AppColors.sandy,
  });

  static const _routes = ['/home', '/favorites', '/advisor', '/profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: _BottomNav(currentIndex: currentIndex, onTap: (index) {
        if (index == currentIndex) return;
        context.go(_routes[index]);
      }),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _icons = [
    (outline: Icons.home_outlined, filled: Icons.home),
    (outline: Icons.favorite_border, filled: Icons.favorite),
    (outline: Icons.chat_bubble_outline, filled: Icons.chat_bubble),
    (outline: Icons.person_outline, filled: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [l10n.navHome, l10n.navSaved, l10n.navAdvisor, l10n.navProfile];
    return Container(
      color: AppColors.deepGreen,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s8, AppSpacing.s10, AppSpacing.s8, AppSpacing.s10),
          child: Row(
            children: List.generate(_icons.length, (index) {
              final item = _icons[index];
              final selected = index == currentIndex;
              final color = selected ? AppColors.gold : Colors.white.withValues(alpha: 0.5);
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(selected ? item.filled : item.outline, color: color, size: 22),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        labels[index],
                        style: AppFonts.tajawal(size: 10, weight: selected ? FontWeight.w700 : FontWeight.w600, color: selected ? Colors.white : color),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
