import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tg_store/core/config/environment.dart';
import 'package:tg_store/core/theme/app_theme.dart';
import 'package:tg_store/admin_panel/presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.setEnvironment(Environment.development);
  
  runApp(const AdminPanelApp());
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AdminApp(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
    );
  }
}

