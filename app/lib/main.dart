
import 'package:flutter/material.dart';
import 'providers/app_state.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://laucmoihhnrnegcgjpzh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxhdWNtb2loaG5ybmVnY2dqcHpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxODI2MDYsImV4cCI6MjEwMTc1ODYwNn0.BbArODhwKelbJwYWujH7uC4pYQmxxqVCpv7j3nDGbI8',
  );
  
  runApp(const ChronicoApp());
}

class ChronicoApp extends StatefulWidget {
  const ChronicoApp({super.key});

  @override
  State<ChronicoApp> createState() => _ChronicoAppState();
}

class _ChronicoAppState extends State<ChronicoApp> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, child) {
        return MaterialApp(
          title: 'Chronico',
          debugShowCheckedModeBanner: false,
          theme: ChronicoTheme.darkTheme,
          home: LoginScreen(appState: _appState),
        );
      },
    );
  }
}
