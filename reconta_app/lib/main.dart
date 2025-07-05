import 'package:flutter/material.dart';
import 'package:reconta_app/src/inicial/presentation/tela_opcoes.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TelaOpcoes(),
    );
  }
}
