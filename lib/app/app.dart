import 'package:flutter/material.dart';
import 'package:saegim/app/routes/app_router.dart';

class SaeGimApp extends StatelessWidget {
  const SaeGimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '새김',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.createRouter(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB2C5B8), // sage-100
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'System',
      ),
    );
  }
}
