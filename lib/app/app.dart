import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/auth_service.dart';
import '../core/services/theme_controller.dart';
import 'router.dart';
import 'theme.dart';

class BusinessHomeApp extends StatelessWidget {
  const BusinessHomeApp({
    super.key,
    required this.themeController,
    required this.authService,
  });

  final ThemeController themeController;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: authService),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp.router(
          title: 'BusinessHome',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
