import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'core/ui.dart';
import 'data/store.dart';
import 'features/budget.dart';
import 'features/dashboard.dart' deferred as dash;
import 'features/module_screen.dart';
import 'features/modules.dart' as mod;
import 'features/settings.dart';
import 'features/shell.dart';
import 'features/welcome.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final results = await Future.wait([
    SharedPreferences.getInstance(),
    Firebase.initializeApp(options: DefaultFirebaseOptions.web),
  ]);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 50 * 1024 * 1024,
  );
  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(results[0] as SharedPreferences),
      ],
      child: const KnotsApp(),
    ),
  );
}

CustomTransitionPage<void> _fade(GoRouterState s, Widget child) =>
    CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, a, _, c) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: c,
      ),
    );

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<Session?>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, n) => auth.value = n);
  ref.onDispose(auth.dispose);

  GoRoute r(String path, Widget Function() w) =>
      GoRoute(path: path, pageBuilder: (c, s) => _fade(s, w()));

  return GoRouter(
    refreshListenable: auth,
    redirect: (c, s) {
      final has = ref.read(sessionProvider) != null;
      final onWelcome = s.matchedLocation == '/welcome';
      if (!has) return onWelcome ? null : '/welcome';
      if (onWelcome) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        pageBuilder: (c, s) => _fade(s, const WelcomePage()),
      ),
      ShellRoute(
        builder: (c, s, child) => Shell(child: child),
        routes: [
          r('/', () => const _Lazy()),
          r('/expenses', () => ModuleScreen(mod.expenses)),
          r('/budget', () => const BudgetScreen()),
          r('/tasks', () => ModuleScreen(mod.tasks)),
          r('/guests', () => ModuleScreen(mod.guests)),
          r('/food', () => ModuleScreen(mod.menu)),
          r('/gifts', () => ModuleScreen(mod.gifts)),
          r('/vendors', () => ModuleScreen(mod.vendors)),
          r('/shopping', () => ModuleScreen(mod.purchases)),
          r('/more', () => const MorePage()),
          r('/settings', () => const SettingsPage()),
        ],
      ),
    ],
  );
});

/// Dashboard (and fl_chart) loads as a separate chunk so first paint stays fast.
class _Lazy extends StatefulWidget {
  const _Lazy();
  @override
  State<_Lazy> createState() => _LazyState();
}

class _LazyState extends State<_Lazy> {
  late final Future<void> _f = dash.loadLibrary();
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _f,
    builder: (c, snap) => snap.connectionState == ConnectionState.done
        ? dash.DashboardPage()
        : const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Skeleton(height: 190),
                SizedBox(height: 14),
                Skeleton(height: 80),
              ],
            ),
          ),
  );
}

class KnotsApp extends ConsumerWidget {
  const KnotsApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Knots',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    themeMode: ref.watch(themeProvider),
    routerConfig: ref.watch(routerProvider),
  );
}
