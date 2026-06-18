import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/shell/presentation/app_shell.dart';
import 'app_theme.dart';

class GalaxyNovelsApp extends StatelessWidget {
  const GalaxyNovelsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مجرة الروايات',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AppShell(),
      ),
    );
  }
}
