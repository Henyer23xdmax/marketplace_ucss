import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _careerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _careerFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _phoneFocus = FocusNode();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  bool _termsError = false;
  bool _awaitingConfirmation = false;
  String _pendingEmail = '';

  bool _submitted = false;
  final Set<String> _touched = {};
  bool _switchingMode = false;

  static final _emailRegExp = RegExp(r'^[^@\s]+@ucss\.pe$');

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onFieldChanged);
    _nameFocus.addListener(() => _onBlur('name', _nameFocus));
    _emailFocus.addListener(() => _onBlur('email', _emailFocus));
    _passwordFocus.addListener(() => _onBlur('password', _passwordFocus));
    _confirmFocus.addListener(() => _onBlur('confirm', _confirmFocus));
  }

  @override
  void dispose() {
    _passwordCtrl.removeListener(_onFieldChanged);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    _careerCtrl.dispose();
    _phoneCtrl.dispose();
    _nameFocus.dispose();
    _careerFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _onBlur(String field, FocusNode node) {
    if (_switchingMode) return;
    if (node.hasFocus) return;
    if (_touched.contains(field)) return;
    setState(() => _touched.add(field));
    // Revalida solo los campos ya tocados (los no tocados devuelven null).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formKey.currentState?.validate();
    });
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  bool _showRequired(String field) => _submitted || _touched.contains(field);

  // ----------------------------------------------------------
  // Validaciones (inline, se conectan a cada campo)
  // ----------------------------------------------------------
  String? _validateName(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) {
      return _showRequired('name') ? 'Ingresa tus nombres y apellidos' : null;
    }
    if (value.length < 3) return 'El nombre es demasiado corto';
    return null;
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim().toLowerCase();
    if (value.isEmpty) {
      return _showRequired('email')
          ? 'Ingresa tu correo institucional'
          : null;
    }
    if (!_emailRegExp.hasMatch(value)) {
      return 'Usa tu correo institucional @ucss.pe';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) {
      return _showRequired('password') ? 'Ingresa tu contraseña' : null;
    }
    if (value.length < 6) return 'Debe tener al menos 6 caracteres';
    return null;
  }

  String? _validateConfirm(String? v) {
    if ((v ?? '').isEmpty) {
      return _showRequired('confirm') ? 'Confirma tu contraseña' : null;
    }
    if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  int get _passwordScore {
    final value = _passwordCtrl.text;
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

  void _setMode(bool signUp) {
    if (_isSignUp == signUp) return;
    _switchingMode = true;
    setState(() {
      _isSignUp = signUp;
      _submitted = false;
      _touched.clear();
      _termsError = false;
    });
    _formKey.currentState?.reset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (signUp ? _nameFocus : _emailFocus).requestFocus();
      _switchingMode = false;
    });
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _submitted = true;
      _termsError = _isSignUp && !_acceptedTerms;
    });

    // Enfoca el primer campo inválido en orden visual.
    FocusNode? firstInvalid;
    if (_isSignUp && _validateName(_nameCtrl.text) != null) {
      firstInvalid ??= _nameFocus;
    }
    if (_validateEmail(_emailCtrl.text) != null) {
      firstInvalid ??= _emailFocus;
    }
    if (_validatePassword(_passwordCtrl.text) != null) {
      firstInvalid ??= _passwordFocus;
    }
    if (_isSignUp && _validateConfirm(_confirmCtrl.text) != null) {
      firstInvalid ??= _confirmFocus;
    }

    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid || (_isSignUp && !_acceptedTerms)) {
      firstInvalid?.requestFocus();
      return;
    }

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final fullName = _nameCtrl.text.trim();
    final career = _careerCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authControllerProvider.notifier);
      if (_isSignUp) {
        final hasSession = await authNotifier.signUp(
          email: email,
          password: password,
          fullName: fullName,
          career: career.isNotEmpty ? career : null,
          phone: phone.isNotEmpty ? phone : null,
        );
        if (mounted) {
          TextInput.finishAutofillContext();
          if (hasSession) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('¡Cuenta creada exitosamente!'),
                backgroundColor: _isDark
                    ? AppColors.darkSuccess
                    : AppColors.success,
              ),
            );
          } else {
            setState(() {
              _awaitingConfirmation = true;
              _pendingEmail = email;
            });
          }
        }
      } else {
        await authNotifier.signIn(email: email, password: password);
        if (mounted) TextInput.finishAutofillContext();
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _isDark ? AppColors.darkError : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    await showCupertinoDialog(
      context: context,
      builder: (ctx) {
        String? error;
        bool sending = false;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return CupertinoAlertDialog(
              title: const Text('Recuperar contraseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  const Text(
                    'Te enviaremos un enlace a tu correo institucional.',
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    placeholder: 'tu_codigo@ucss.pe',
                    textInputAction: TextInputAction.done,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
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
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                CupertinoDialogAction(
                  onPressed: sending
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim().toLowerCase();
                          if (!_emailRegExp.hasMatch(email)) {
                            setLocal(() => error = 'Usa tu correo @ucss.pe');
                            return;
                          }
                          setLocal(() {
                            sending = true;
                            error = null;
                          });
                          try {
                            await ref
                                .read(authControllerProvider.notifier)
                                .resetPassword(email: email);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Revisa tu correo para restablecer la contraseña.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setLocal(() {
                              sending = false;
                              error = e.toString().replaceAll(
                                'Exception: ',
                                '',
                              );
                            });
                          }
                        },
                  child: sending
                      ? const CupertinoActivityIndicator()
                      : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
    emailCtrl.dispose();
  }

  void _showInfoDialog(String title, String body) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(body),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Entendido'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 250);
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrimary = isDark ? AppColors.darkText : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;
    final successColor = isDark ? AppColors.darkSuccess : AppColors.success;
    final errorColor = isDark ? AppColors.darkError : AppColors.error;

    if (_awaitingConfirmation) {
      return _buildConfirmationView(
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        accent: accent,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Insignia / Logo UCSS (entrada fade + escala)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.scale(
                      scale: 0.95 + 0.05 * t,
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                      border: isDark
                          ? Border.all(color: AppColors.darkBorder)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withValues(
                            alpha: isDark ? 0.3 : 0.15,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.book_solid,
                        color: isDark
                            ? AppColors.darkSecondary
                            : AppColors.secondary,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'UCSS MARKET',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Marketplace Oficial de Estudiantes UCSS',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
                const SizedBox(height: 28),

                // Selector Segmentado Estilo iOS
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: !_isSignUp,
                          label: 'Iniciar Sesión',
                          child: GestureDetector(
                            onTap: () => _setMode(false),
                            child: AnimatedContainer(
                              duration: animDuration,
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isSignUp
                                    ? surfaceColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isSignUp
                                    ? [
                                        BoxShadow(
                                          color: AppColors.shadow.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Iniciar Sesión',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: !_isSignUp
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: !_isSignUp
                                      ? textPrimary
                                      : textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: _isSignUp,
                          label: 'Crear Cuenta',
                          child: GestureDetector(
                            onTap: () => _setMode(true),
                            child: AnimatedContainer(
                              duration: animDuration,
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isSignUp
                                    ? surfaceColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isSignUp
                                    ? [
                                        BoxShadow(
                                          color: AppColors.shadow.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Crear Cuenta',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: _isSignUp
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: _isSignUp
                                      ? textPrimary
                                      : textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tarjeta de Formulario iOS
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedSize(
                    duration: animDuration,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          children: [
                            if (_isSignUp) ...[
                              TextFormField(
                                controller: _nameCtrl,
                                focusNode: _nameFocus,
                                textCapitalization:
                                    TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                enabled: !_isLoading,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                autofillHints: const [AutofillHints.name],
                                onFieldSubmitted: (_) =>
                                    _careerFocus.requestFocus(),
                                validator: _validateName,
                                decoration: InputDecoration(
                                  labelText: 'Nombres y Apellidos',
                                  prefixIcon: Icon(
                                    CupertinoIcons.person,
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _careerCtrl,
                                focusNode: _careerFocus,
                                textCapitalization:
                                    TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                enabled: !_isLoading,
                                onFieldSubmitted: (_) =>
                                    _emailFocus.requestFocus(),
                                decoration: InputDecoration(
                                  labelText: 'Carrera / Facultad',
                                  hintText:
                                      'Ej. Ing. de Sistemas, Enfermería...',
                                  prefixIcon: Icon(
                                    CupertinoIcons.building_2_fill,
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              enabled: !_isLoading,
                              autofocus: !_isSignUp,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              autofillHints: const [AutofillHints.email],
                              onFieldSubmitted: (_) =>
                                  _passwordFocus.requestFocus(),
                              validator: _validateEmail,
                              decoration: InputDecoration(
                                labelText: 'Correo Institucional',
                                hintText: 'tu_codigo@ucss.pe',
                                prefixIcon: Icon(
                                  CupertinoIcons.mail,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              obscureText: _obscurePassword,
                              enabled: !_isLoading,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              textInputAction: _isSignUp
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              autofillHints: [
                                _isSignUp
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              onFieldSubmitted: (_) => _isSignUp
                                  ? _confirmFocus.requestFocus()
                                  : _handleSubmit(),
                              validator: _validatePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: Icon(
                                  CupertinoIcons.lock,
                                  color: accent,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Mostrar contraseña'
                                      : 'Ocultar contraseña',
                                  icon: Icon(
                                    _obscurePassword
                                        ? CupertinoIcons.eye_slash
                                        : CupertinoIcons.eye,
                                    color: textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () =>
                                        _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                            ),
                            if (_isSignUp) ...[
                              const SizedBox(height: 8),
                              _buildPasswordStrength(
                                textSecondary: textSecondary,
                                errorColor: errorColor,
                                successColor: successColor,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmCtrl,
                                focusNode: _confirmFocus,
                                obscureText: _obscureConfirm,
                                enabled: !_isLoading,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                onFieldSubmitted: (_) =>
                                    _phoneFocus.requestFocus(),
                                validator: _validateConfirm,
                                decoration: InputDecoration(
                                  labelText: 'Confirmar Contraseña',
                                  prefixIcon: Icon(
                                    CupertinoIcons.lock_rotation,
                                    color: accent,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _obscureConfirm
                                        ? 'Mostrar contraseña'
                                        : 'Ocultar contraseña',
                                    icon: Icon(
                                      _obscureConfirm
                                          ? CupertinoIcons.eye_slash
                                          : CupertinoIcons.eye,
                                      color: textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscureConfirm = !_obscureConfirm,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneCtrl,
                                focusNode: _phoneFocus,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                enabled: !_isLoading,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                onFieldSubmitted: (_) => _handleSubmit(),
                                decoration: InputDecoration(
                                  labelText: 'WhatsApp / Celular (Opcional)',
                                  hintText: '999 888 777',
                                  prefixIcon: Icon(
                                    CupertinoIcons.phone,
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Términos y privacidad
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _acceptedTerms,
                                    activeColor: accent,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: _isLoading
                                        ? null
                                        : (v) => setState(() {
                                              _acceptedTerms = v ?? false;
                                              if (_acceptedTerms) {
                                                _termsError = false;
                                              }
                                            }),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          'Acepto los ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _showInfoDialog(
                                            'Términos y Condiciones',
                                            'El uso de UCSS Market es exclusivo para estudiantes con correo @ucss.pe. Las transacciones se realizan entre estudiantes y la plataforma actúa como intermediario de coordinación, no como vendedor. (Texto de ejemplo)',
                                          ),
                                          child: Text(
                                            'Términos',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: accent,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: accent,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          ' y la ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _showInfoDialog(
                                            'Política de Privacidad',
                                            'Tus datos (nombre, correo institucional, carrera y celular) se usan solo para operar el marketplace dentro del campus. No se comparten con terceros. (Texto de ejemplo)',
                                          ),
                                          child: Text(
                                            'Política de Privacidad',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: accent,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_termsError) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Debes aceptar los términos y la política de privacidad',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: errorColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _handleSubmit,
                                child: AnimatedSwitcher(
                                  duration: animDuration,
                                  child: _isLoading
                                      ? CupertinoActivityIndicator(
                                          key: const ValueKey('loading'),
                                          color: isDark
                                              ? AppColors.onDarkPrimary
                                              : AppColors.onPrimary,
                                        )
                                      : Text(
                                          _isSignUp
                                              ? 'Registrarme en UCSS'
                                              : 'Ingresar al Campus',
                                          key: const ValueKey('label'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            if (!_isSignUp) ...[
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : _showForgotPasswordDialog,
                                child: const Text('¿Olvidaste tu contraseña?'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nota de seguridad institucional
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_shield_fill,
                      size: 16,
                      color: successColor,
                    ),
                    Text(
                      'Comunidad exclusiva para estudiantes UCSS',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationView({
    required Color textPrimary,
    required Color textSecondary,
    required Color accent,
  }) {
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
                  'Enviamos un enlace de confirmación a $_pendingEmail.\nConfírmalo y luego inicia sesión.',
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
                    onPressed: () => setState(() {
                      _awaitingConfirmation = false;
                      _isSignUp = false;
                      _submitted = false;
                      _touched.clear();
                      _acceptedTerms = false;
                    }),
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

  Widget _buildPasswordStrength({
    required Color textSecondary,
    required Color errorColor,
    required Color successColor,
  }) {
    final score = _passwordScore;
    final labels = ['Muy débil', 'Débil', 'Aceptable', 'Fuerte'];
    final color = score <= 1
        ? errorColor
        : (score == 2 ? AppColors.warning : successColor);

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
