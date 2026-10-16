import 'package:flutter/cupertino.dart';

import '../../../core/constants/theme_constants.dart';

/// Botón principal del login: gradiente navy, sombra coloreada y animación de
/// pulsación.
///
/// El gradiente es lo que separa visualmente el botón del resto de la tarjeta;
/// un `FilledButton` plano se pierde contra un fondo claro.
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDark;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.isDark,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 140);
    final enabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: duration,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: duration,
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: widget.isDark
                        ? const [Color(0xFF26456B), Color(0xFF1F3247)]
                        : const [Color(0xFF26456B), AppColors.primaryDark],
                  )
                : null,
            color: enabled
                ? null
                : (widget.isDark ? AppColors.darkSurface : AppColors.border),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: (widget.isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary)
                          .withValues(alpha: _pressed ? 0.18 : 0.32),
                      blurRadius: _pressed ? 8 : 18,
                      offset: Offset(0, _pressed ? 3 : 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: duration,
              child: widget.isLoading
                  ? const CupertinoActivityIndicator(
                      key: ValueKey('loading'),
                      color: AppColors.onPrimary,
                    )
                  : Text(
                      widget.label,
                      key: const ValueKey('label'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: enabled
                            ? AppColors.onPrimary
                            : (widget.isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector segmentado entre "Iniciar Sesión" y "Crear Cuenta".
///
/// Se reemplaza el `GestureDetector` suelto por uno con indicador deslizante:
/// el estado actual se ve de un vistazo y el movimiento comunica que son dos
/// modos del mismo formulario.
class AuthModeSwitch extends StatelessWidget {
  final bool isSignUp;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const AuthModeSwitch({
    super.key,
    required this.isSignUp,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 260);

    final textPrimary = isDark ? AppColors.darkText : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.border,
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / 2;

          return Stack(
            children: [
              // Indicador deslizante
              AnimatedPositioned(
                duration: duration,
                curve: Curves.easeOutCubic,
                left: isSignUp ? segmentWidth : 0,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: 0.10),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _segment(
                    label: 'Iniciar Sesión',
                    selected: !isSignUp,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () => onChanged(false),
                  ),
                  _segment(
                    label: 'Crear Cuenta',
                    selected: isSignUp,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () => onChanged(true),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? textPrimary : textSecondary,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
