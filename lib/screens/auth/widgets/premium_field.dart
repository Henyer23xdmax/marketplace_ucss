import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';

/// Campo de texto del formulario de acceso, con foco animado.
///
/// Sustituye al `TextFormField` + `InputDecoration` estándar: el indicador de
/// foco y el borde cambian de color con transición en lugar de saltar de golpe,
/// que es la diferencia que más se percibe entre "un formulario" y "una app".
class PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String? hint;
  final IconData icon;
  final Color accent;
  final bool isDark;
  final bool obscureText;
  final bool enabled;
  final bool capitalizeWords;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTapSuffix;
  final String? suffixTooltip;
  final bool showSuffix;

  /// Contador de "generación de validación". Se incrementa cuando el formulario
  /// cambia de modo (login <-> registro) para forzar a este campo a olvidar
  /// cualquier error anterior.
  ///
  /// Es necesario porque `Form.reset()` solo limpia el estado interno del
  /// FormField; no toca el [ValueNotifier] propio de este widget, así que sin
  /// esto los errores de "Iniciar Sesión" se quedarían visibles al pasar a
  /// "Crear Cuenta".
  final int validationEpoch;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    required this.accent,
    required this.isDark,
    this.hint,
    this.obscureText = false,
    this.enabled = true,
    this.capitalizeWords = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTapSuffix,
    this.suffixTooltip,
    this.showSuffix = false,
    this.validationEpoch = 0,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  bool _focused = false;

  /// Error visible. Es un [ValueNotifier] porque el `validator` de
  /// `TextFormField` corre durante el build y no admite `setState`.
  final ValueNotifier<String?> _errorText = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant PremiumTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      widget.focusNode?.addListener(_onFocusChange);
    }
    if (oldWidget.validationEpoch != widget.validationEpoch) {
      _errorText.value = null;
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    _errorText.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final focused = widget.focusNode?.hasFocus ?? false;
    if (focused != _focused) setState(() => _focused = focused);
  }

  Color get _errorColor =>
      widget.isDark ? AppColors.darkError : AppColors.error;

  Color _borderColor(String? error) {
    if (error != null) return _errorColor;
    if (_focused) return widget.accent;
    return widget.isDark ? AppColors.darkBorder : AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 220);

    return ValueListenableBuilder<String?>(
      valueListenable: _errorText,
      builder: (context, error, _) => _buildField(context, error, duration),
    );
  }

  Widget _buildField(BuildContext context, String? error, Duration duration) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.darkBackground.withValues(alpha: 0.55)
                : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _borderColor(error),
              width: _focused ? 1.6 : 1.0,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            autocorrect: false,
            enableSuggestions: !widget.obscureText,
            textCapitalization: widget.capitalizeWords
                ? TextCapitalization.words
                : TextCapitalization.none,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            validator: (v) {
              // El validador se ejecuta DURANTE el build, así que no puede
              // llamar a setState. Se notifica el cambio con un ValueNotifier,
              // que es seguro en esa fase.
              final result = widget.validator?.call(v);
              // Solo se muestra el error en rojo cuando el campo pierde el foco
              // o ya se intentó enviar; antes solo el borde se tiñe.
              final show = result != null && (!_focused || _errorText.value != null);
              final nextError = show ? result : null;
              if (nextError != _errorText.value) {
                _errorText.value = nextError;
              }
              return null;
            },
            onFieldSubmitted: widget.onSubmitted,
            onChanged: widget.onChanged,
            style: TextStyle(
              fontSize: 15,
              color: widget.isDark ? AppColors.darkText : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              // El `inputDecorationTheme` global define `filled: true` con un
              // `fillColor` opaco. Ese fill lo pinta InputDecorator como un
              // RECTÁNGULO de esquinas rectas, que sobresale por encima de las
              // esquinas redondeadas del AnimatedContainer y hace que el borde
              // se vea partido. Aquí el fondo lo pone el contenedor.
              filled: false,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: widget.isDark
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
                    : AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 15,
              ),
              prefixIcon: Padding(
                // El `contentPadding` ya aporta 16 px a la izquierda, así que
                // aquí solo se deja un margen mínimo: 18 px en total antes del
                // ícono. Con 14 px extra se llegaba a 30 px y se veía un hueco.
                padding: const EdgeInsets.only(left: 2, right: 10),
                child: AnimatedSwitcher(
                  duration: duration,
                  child: Icon(
                    widget.icon,
                    key: ValueKey(_focused),
                    size: 20,
                    color: _focused
                        ? widget.accent
                        : (widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary),
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              suffixIcon: widget.showSuffix
                  ? IconButton(
                      tooltip: widget.suffixTooltip,
                      onPressed: widget.onTapSuffix,
                      icon: Icon(
                        widget.obscureText
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        size: 20,
                        color: widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
        // Etiqueta flotante: sube cuando el campo tiene foco o contenido.
        AnimatedSize(
          duration: duration,
          curve: Curves.easeOut,
          child: (_focused || widget.controller.text.isNotEmpty)
              ? Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _focused
                          ? widget.accent
                          : (widget.isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // Mensaje de error, alineado al inicio y cerca del campo que lo causa.
        AnimatedSize(
          duration: duration,
          curve: Curves.easeOut,
          child: error == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_circle_fill,
                        size: 13,
                        color: _errorColor,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          error,
                          style: TextStyle(
                            fontSize: 12,
                            color: _errorColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
