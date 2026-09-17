import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/app_usage_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/language_service.dart';
import '../core/services/theme_controller.dart';
import '../shared/widgets/ai_assistant.dart';
import 'router.dart';
import 'theme.dart';

class BusinessHomeApp extends StatefulWidget {
  const BusinessHomeApp({super.key, required this.themeController, required this.authService});

  final ThemeController themeController;
  final AuthService authService;

  @override
  State<BusinessHomeApp> createState() => _BusinessHomeAppState();
}

class _BusinessHomeAppState extends State<BusinessHomeApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Fondan qaytganda ham belgi yuboriladi (soatiga bir marta cheklangan).
    if (state == AppLifecycleState.resumed) {
      unawaited(AppUsageService.instance.ping());
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = widget.themeController;
    final authService = widget.authService;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: authService),
      ],
      // Til o'zgarganda butun daraxt qayta chiziladi — matnlar `t()` orqali o'qiladi.
      child: ListenableBuilder(
        listenable: LanguageService.instance,
        builder: (context, _) => Consumer<ThemeController>(
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
      ),
    );
  }
}
