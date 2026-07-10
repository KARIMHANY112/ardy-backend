import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppBottomNavScaffold(
      currentIndex: 4,
      title: 'Profile',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 28, backgroundColor: AppColors.sandy, child: Icon(Icons.person, color: AppColors.ink, size: 28)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ardy User', style: textTheme.titleMedium),
                        Text('user@example.com', style: textTheme.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
