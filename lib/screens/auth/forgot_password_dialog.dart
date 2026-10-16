import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../providers/auth_provider.dart';

/// Diálogo de recuperación de contraseña.
///
/// Se extrajo de `login_screen.dart` porque era un bloque autocontenido de ~90
/// líneas que solo dependía del correo actual y del provider de autenticación.
///
/// Devuelve `true` si el correo se envió, `false` si el usuario canceló o
/// hubo un error.
Future<bool> showForgotPasswordDialog(
  BuildContext context, {
  required String initialEmail,
}) async {
  final sent = await showCupertinoDialog<bool>(
    context: context,
    builder: (_) => _ForgotPasswordDialog(initialEmail: initialEmail),
  );
  return sent ?? false;
}

class _ForgotPasswordDialog extends ConsumerStatefulWidget {
  final String initialEmail;

  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  ConsumerState<_ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<_ForgotPasswordDialog> {
  late final TextEditingController _emailCtrl =
      TextEditingController(text: widget.initialEmail);

  String? _error;
  bool _sending = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (!isUcssEmail(email)) {
      setState(() => _error = 'Usa tu correo $kUcssEmailDomain');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).resetPassword(email: email);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Recuperar contraseña'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          const Text('Te enviaremos un enlace a tu correo institucional.'),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            placeholder: 'tu_codigo@ucss.pe',
            textInputAction: TextInputAction.done,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 12,
                color: _isDark ? AppColors.darkError : AppColors.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        CupertinoDialogAction(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const CupertinoActivityIndicator()
              : const Text('Enviar'),
        ),
      ],
    );
  }
}
