import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../providers/auth_provider.dart';
import 'auth_widgets.dart';
import 'forgot_password_dialog.dart';
import 'widgets/brand_header.dart';
import 'widgets/premium_field.dart';
import 'widgets/primary_button.dart';

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
  final _phoneCtrl = TextEditingController();

  final _nameFocus = FocusNode();
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

  /// Se incrementa en cada cambio de modo para que los campos limpien el error
  /// que tengan pegado (ver [PremiumTextField.validationEpoch]).
  int _validationEpoch = 0;

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
    _phoneCtrl.dispose();
    _nameFocus.dispose();
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
    // Al iniciar sesión solo se verifica que no esté vacía: la política de
    // contraseñas applies únicamente al CREAR la cuenta, no a cada ingreso.
    if (_isSignUp && scorePassword(value) < 2) {
      return 'Combina letras y números para una contraseña más segura';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if ((v ?? '').isEmpty) {
      return _showRequired('confirm') ? 'Confirma tu contraseña' : null;
    }
    if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  void _setMode(bool signUp) {
    if (_isSignUp == signUp) return;
    _switchingMode = true;
    setState(() {
      _isSignUp = signUp;
      _submitted = false;
      _touched.clear();
      _termsError = false;
      _validationEpoch++;
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
    //
    // OJO: los validadores de los PremiumTextField devuelven `null` a propósito
    // (el error lo pinta el propio widget, no el FormField). Por eso
    // `Form.validate()` SIEMPRE devuelve true y su resultado no sirve para
    // decidir. La validez se calcula aquí con los mismos validadores.
    FocusNode? firstInvalid;
    var allValid = true;

    void check(bool isSignUpOnly, FocusNode node, String? error) {
      if (error == null) return;
      if (isSignUpOnly && !_isSignUp) return;
      allValid = false;
      firstInvalid ??= node;
    }

    if (_isSignUp) {
      check(true, _nameFocus, _validateName(_nameCtrl.text));
    }
    check(false, _emailFocus, _validateEmail(_emailCtrl.text));
    check(false, _passwordFocus, _validatePassword(_passwordCtrl.text));
    if (_isSignUp) {
      check(true, _confirmFocus, _validateConfirm(_confirmCtrl.text));
    }

    final termsOk = !_isSignUp || _acceptedTerms;
    if (!allValid || !termsOk) {
      // Dispara los validadores para que cada campo muestre su error.
      _formKey.currentState?.validate();
      firstInvalid?.requestFocus();
      return;
    }

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final fullName = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authControllerProvider.notifier);
      if (_isSignUp) {
        final hasSession = await authNotifier.signUp(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone.isNotEmpty ? phone : null,
        );
        if (mounted) {
          TextInput.finishAutofillContext();
          if (hasSession) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '¡Cuenta creada exitosamente!',
                  style: TextStyle(
                    color: _isDark
                        ? AppColors.darkBackground
                        : AppColors.onPrimary,
                  ),
                ),
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
        content: Text(
          message,
          style: TextStyle(
            color: _isDark ? AppColors.darkBackground : AppColors.onPrimary,
          ),
        ),
        backgroundColor: _isDark ? AppColors.darkError : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final sent = await showForgotPasswordDialog(
      context,
      initialEmail: _emailCtrl.text.trim(),
    );

    if (sent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Revisa tu correo para restablecer la contraseña.',
          ),
        ),
      );
    }
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
    final warningColor = isDark ? AppColors.darkWarning : AppColors.warning;

    if (_awaitingConfirmation) {
      return AuthConfirmationView(
        pendingEmail: _pendingEmail,
        onBackToLogin: () => setState(() {
          _awaitingConfirmation = false;
          _isSignUp = false;
          _submitted = false;
          _touched.clear();
          _acceptedTerms = false;
          _termsError = false;
          _validationEpoch++;
        }),
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
                BrandHeader(isDark: isDark),
                const SizedBox(height: 32),

                AuthModeSwitch(
                  isSignUp: _isSignUp,
                  isDark: isDark,
                  onChanged: _setMode,
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
                              PremiumTextField(
                                controller: _nameCtrl,
                                focusNode: _nameFocus,
                                label: 'Nombres y Apellidos',
                                hint: 'Ej. María Fernanda Ríos',
                                icon: CupertinoIcons.person,
                                accent: accent,
                                validationEpoch: _validationEpoch,
                                isDark: isDark,
                                capitalizeWords: true,
                                enabled: !_isLoading,
                                autofillHints: const [AutofillHints.name],
                                onSubmitted: (_) =>
                                    _emailFocus.requestFocus(),
                                validator: (v) => _validateName(v),
                              ),
                              const SizedBox(height: 14),
                            ],
                            PremiumTextField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              label: 'Correo Institucional',
                              hint: 'tu_codigo@ucss.pe',
                              icon: CupertinoIcons.mail,
                              accent: accent,
                                validationEpoch: _validationEpoch,
                              isDark: isDark,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_isLoading,
                              autofillHints: const [AutofillHints.email],
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                              validator: (v) => _validateEmail(v),
                            ),
                            const SizedBox(height: 12),
                            PremiumTextField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              label: 'Contraseña',
                              hint: 'Mínimo 6 caracteres',
                              icon: CupertinoIcons.lock,
                              accent: accent,
                                validationEpoch: _validationEpoch,
                              isDark: isDark,
                              obscureText: _obscurePassword,
                              enabled: !_isLoading,
                              showSuffix: true,
                              suffixTooltip: _obscurePassword
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onTapSuffix: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                              textInputAction: _isSignUp
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              autofillHints: [
                                _isSignUp
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              onSubmitted: (_) => _isSignUp
                                  ? _confirmFocus.requestFocus()
                                  : _handleSubmit(),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => _validatePassword(v),
                            ),
                            if (_isSignUp) ...[
                              const SizedBox(height: 8),
                              PasswordStrengthMeter(
                                password: _passwordCtrl.text,
                                textSecondary: textSecondary,
                                errorColor: errorColor,
                                successColor: successColor,
                                warningColor: warningColor,
                              ),
                              const SizedBox(height: 12),
                              PremiumTextField(
                                controller: _confirmCtrl,
                                focusNode: _confirmFocus,
                                label: 'Confirmar Contraseña',
                                icon: CupertinoIcons.lock_rotation,
                                accent: accent,
                                validationEpoch: _validationEpoch,
                                isDark: isDark,
                                obscureText: _obscureConfirm,
                                enabled: !_isLoading,
                                showSuffix: true,
                                suffixTooltip: _obscureConfirm
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onTapSuffix: () =>
                                    setState(() => _obscureConfirm = !_obscureConfirm),
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.newPassword],
                                onSubmitted: (_) => _phoneFocus.requestFocus(),
                                validator: (v) => _validateConfirm(v),
                              ),
                              const SizedBox(height: 12),
                              PremiumTextField(
                                controller: _phoneCtrl,
                                focusNode: _phoneFocus,
                                label: 'WhatsApp / Celular (opcional)',
                                hint: '999 888 777',
                                icon: CupertinoIcons.phone,
                                accent: accent,
                                validationEpoch: _validationEpoch,
                                isDark: isDark,
                                keyboardType: TextInputType.phone,
                                enabled: !_isLoading,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.telephoneNumber],
                                onSubmitted: (_) => _handleSubmit(),
                              ),
                            ],
                            Padding(
                              // Margen a la izquierda para que el checkbox no
                              // quede pegado al borde de la tarjeta.
                              padding: const EdgeInsets.only(left: 2, right: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Sin `SizedBox` forzado: el `Checkbox` por
                                  // defecto mide 40x40 con el recuadro de 18
                                  // centrado, lo que además da un área táctil
                                  // cómoda. Forzarlo a 24x24 con `compact`
                                  // descuadraba el recuadro.
                                  Checkbox(
                                    value: _acceptedTerms,
                                    onChanged: _isLoading
                                        ? null
                                        : (v) => setState(() {
                                              _acceptedTerms = v ?? false;
                                              if (_acceptedTerms) {
                                                _termsError = false;
                                              }
                                            }),
                                  ),
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
                            const SizedBox(height: 22),
                            PrimaryButton(
                              label: _isSignUp
                                  ? 'Registrarme en UCSS'
                                  : 'Ingresar al Campus',
                              onPressed: _handleSubmit,
                              isLoading: _isLoading,
                              isDark: isDark,
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
}
