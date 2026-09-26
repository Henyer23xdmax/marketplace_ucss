import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main_scaffold.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final client = Supabase.instance.client;
      return StreamBuilder<AuthState>(
        stream: client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // Evalúa de inmediato si existe sesión activa sin bloquear la UI
          final session = snapshot.data?.session ?? client.auth.currentSession;
          if (session != null) {
            return const MainScaffold();
          }
          return const LoginScreen();
        },
      );
    } catch (_) {
      // En caso de retardo o desconexión de Supabase, muestra LoginScreen de inmediato
      return const LoginScreen();
    }
  }
}
