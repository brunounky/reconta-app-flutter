import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reconta_app/src/auth/presentation/auth_service.dart';
import 'package:reconta_app/src/auth/presentation/login_screen.dart';
import 'package:reconta_app/src/inicial/presentation/tela_opcoes.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return const TelaOpcoes();
        }
        return const LoginScreen();
      },
    );
  }
}
