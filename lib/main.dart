import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'routes/app_router.dart';
import 'services/advisor_repository.dart';
import 'services/favorites_repository.dart';
import 'services/listings_repository.dart';
import 'services/users_repository.dart';
import 'state/auth_session.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthSession _session;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _session = AuthSession();
    // refreshListenable re-runs the router's redirect whenever the session
    // changes (login/logout), without tearing down navigation state.
    _router = buildAppRouter(_session);
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _session),
        Provider(create: (_) => ListingsRepository(_session.api)),
        Provider(create: (_) => FavoritesRepository(_session.api)),
        Provider(create: (_) => AdvisorRepository(_session.api)),
        Provider(create: (_) => UsersRepository(_session.api)),
      ],
      child: MaterialApp.router(
        title: 'ARDI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
