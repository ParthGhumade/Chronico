import 'package:flutter/material.dart';
import 'providers/app_state.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
          home: MainNavigationScreen(appState: _appState),
        );
      },
    );
  }
}
