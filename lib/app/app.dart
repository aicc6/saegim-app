import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/app/routes/app_router.dart';
import 'package:saegim/core/providers/theme_provider.dart';
import 'package:saegim/core/theme/app_theme.dart';

class SaeGimApp extends ConsumerWidget {
  const SaeGimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: '새김',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.createRouter(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
    );
  }
}
