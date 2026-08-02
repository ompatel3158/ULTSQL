import 'package:flutter/material.dart';
import 'src/ui/editor_screen.dart';

void main() {
  runApp(const HybridSqlApp());
}

class HybridSqlApp extends StatelessWidget {
  const HybridSqlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antigravity Hybrid SQL Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF181825),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFCBA6F7),
          secondary: Color(0xFF89B4FA),
          surface: Color(0xFF1E1E2E),
        ),
      ),
      home: const EditorScreen(),
    );
  }
}
