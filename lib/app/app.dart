import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/auth_service.dart';
import '../core/services/theme_controller.dart';
import '../shared/widgets/ai_assistant.dart';
import 'router.dart';
import 'theme.dart';

class BusinessHomeApp extends StatelessWidget {
  const BusinessHomeApp({super.key, required this.themeController, required this.authService});

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
          // Saytda `app.component.ts` shabloni `<app-ai-assistant />` ni router'dan tashqarida
          // chizadi — ya'ni suzuvchi tugma **har bir sahifada** turadi, faqat bosh sahifada emas.
          builder: (context, child) => Stack(children: [?child, const AiAssistant()]),
        ),
      ),
    );
  }
}
