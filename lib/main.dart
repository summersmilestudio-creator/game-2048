import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const Game2048App());
}

class Game2048App extends StatelessWidget {
  const Game2048App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF8EF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEDC22E)),
      ),
      home: const GameScreen(),
    );
  }
}
