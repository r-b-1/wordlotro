import 'package:flutter/material.dart';

import 'game/views/game_screen.dart';

void main() {
  runApp(const WordlotroApp());
}

class WordlotroApp extends StatelessWidget {
  const WordlotroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordlotro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8A838),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
