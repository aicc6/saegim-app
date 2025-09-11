import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegim/app/routes/app_router.dart';
import 'package:saegim/features/authentication/presentation/providers/auth_provider.dart';

class SaeGimApp extends StatelessWidget {
  const SaeGimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
          lazy: true, // 지연 생성으로 빌드 중 상태 변경 방지
        ),
      ],
      child: MaterialApp.router(
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
      ),
    );
  }
}
