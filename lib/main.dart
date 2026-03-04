// =============================================================================
// FILE: lib/main.dart
// PURPOSE: App entry point — Enterprise SaaS Architecture Wiring
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import 'design_system/design_system.dart';
import 'routes/app_router.dart';
import 'shared/widgets/inactivity_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: SaaSAppRoot()));
}

class SaaSAppRoot extends StatelessWidget {
  const SaaSAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return p.MultiProvider(
      providers: [
        p.ChangeNotifierProvider(
          create: (_) => ThemeNotifier(initial: ThemeMode.system),
        ),
      ],
      child: const SchoolErpAdminApp(),
    );
  }
}

class SchoolErpAdminApp extends ConsumerWidget {
  const SchoolErpAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = p.Provider.of<ThemeNotifier>(context);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Vidyron One — Management Platform',
      debugShowCheckedModeBanner: false,

      // ── SaaS Design System Integration ─────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeNotifier.mode,

      // ── Global Router ──────────────────────────────────────────────────────
      routerConfig: router,

      builder: (context, child) {
        return InactivityWrapper(child: child ?? const SizedBox());
      },
    );
  }
}
