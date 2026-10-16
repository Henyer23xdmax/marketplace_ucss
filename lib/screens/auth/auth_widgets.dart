import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Calcula la fuerza de una contraseña de 0 a 4.
///
/// Extraído de `login_screen.dart` para poder testearlo sin montar widgets.
int scorePassword(String value) {
  var score = 0;
  if (value.length >= 6) score++;
  if (value.length >= 10) score++;
  if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
    score++;
  }
  if (RegExp(r'[0-9]').hasMatch(value) ||
      RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
    score++;
  }
  return score;
}

/// Barra de fuerza de la contraseña, visible solo en el registro.
class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  final Color textSecondary;
  final Color errorColor;
  final Color successColor;
  final Color warningColor;

  const PasswordStrengthMeter({
    super.key,
    required this.password,
    required this.textSecondary,
    required this.errorColor,
    required this.successColor,
    required this.warningColor,
  });

  @override
  Widget build(BuildContext context) {
    final score = scorePassword(password);
    const labels = ['Muy débil', 'Débil', 'Aceptable', 'Fuerte'];
    final color = score <= 1
        ? errorColor
        : (score == 2 ? warningColor : successColor);

    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < score
                        ? color
                        : textSecondary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          labels[score.clamp(0, 3)],
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}

/// Pantalla mostrada tras registrarse, cuando Supabase exige confirmar el
/// correo antes de iniciar sesión.
class AuthConfirmationView extends StatelessWidget {
  final String pendingEmail;
  final VoidCallback onBackToLogin;

  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const AuthConfirmationView({
    super.key,
    required this.pendingEmail,
    required this.onBackToLogin,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.mail_solid, size: 56, color: accent),
                const SizedBox(height: 16),
                Text(
                  'Revisa tu correo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enviamos un enlace de confirmación a $pendingEmail.\n'
                  'Confírmalo y luego inicia sesión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: onBackToLogin,
                    child: const Text('Volver a iniciar sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
