import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';

/// Cabecera de marca del login: insignia + logotipo + subtítulo.
///
/// Reemplaza al `Container` plano anterior por una composición con gradiente,
/// reflejo sutil y tracking amplio en el logotipo, que es lo que da el carácter
/// "premium" sin necesidad de cambiar la paleta institucional.
class BrandHeader extends StatelessWidget {
  final bool isDark;

  const BrandHeader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - t)),
              child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
            ),
          ),
          child: _BrandBadge(isDark: isDark),
        ),
        const SizedBox(height: 20),
        // Logotipo con tracking amplio: el detalle que hace que se lea como
        // "marca" y no como "un formulario más".
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDark
                ? [AppColors.darkPrimary, AppColors.darkSecondary]
                : [AppColors.primary, AppColors.secondary],
          ).createShader(bounds),
          child: Text(
            'UCSS MARKET',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 4.5,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Marketplace Oficial de Estudiantes UCSS',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: textSecondary, height: 1.4),
        ),
      ],
    );
  }
}

/// Insignia cuadrada con gradiente navy y borde luminoso.
class _BrandBadge extends StatelessWidget {
  final bool isDark;

  const _BrandBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1F3247), Color(0xFF10151C)]
              : const [Color(0xFF26456B), AppColors.primaryDark],
        ),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.secondary.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: isDark ? 0.4 : 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Reflejo diagonal: da sensación de cristal sin coste de imagen.
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Icon(
            CupertinoIcons.book_solid,
            color: isDark ? AppColors.darkSecondary : AppColors.secondary,
            size: 38,
          ),
        ],
      ),
    );
  }
}
