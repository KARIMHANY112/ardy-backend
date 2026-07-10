import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared bottom tab bar (Home, Saved, Advisor, Post, Profile) per the design handoff.
/// Wrap each of the 5 top-level screens in this so navigation between them is always visible.
class AppBottomNavScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget body;
  final String? title;
  final List<Widget>? actions;

  const AppBottomNavScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
    this.title,
    this.actions,
  });

  static const _routes = ['/home', '/favorites', '/advisor', '/post-listing', '/profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null ? null : AppBar(title: Text(title!), actions: actions),
      body: SafeArea(child: body),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) return;
          context.go(_routes[index]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Advisor'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), activeIcon: Icon(Icons.add_box), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
