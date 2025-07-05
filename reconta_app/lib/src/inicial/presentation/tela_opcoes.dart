import 'package:flutter/material.dart';

class TelaOpcoes extends StatelessWidget {
  const TelaOpcoes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opções'),
      ),
      body: const Center(
        child: Text('Bem-vindo à Tela de Opções!'),
      ),
    );
  }
}
