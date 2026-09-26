import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final danger = isDark ? AppColors.darkError : AppColors.error;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Mi Perfil UCSS')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tarjeta de Identidad Estudiantil UCSS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                        child: Text(
                          (profileAsync.value?.fullName.isNotEmpty == true
                                  ? profileAsync.value!.fullName[0]
                                  : 'U')
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkBackground : AppColors.onPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark_alt,
                          color: AppColors.onPrimary,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profileAsync.value?.fullName ?? 'Estudiante UCSS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkText : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'alumno@ucss.pe',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimary.withValues(alpha: 0.15)
                          : AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          size: 14,
                          color: isDark ? AppColors.darkPrimary : AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Estudiante Verificado UCSS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profileAsync.value?.career != null &&
                      profileAsync.value!.career!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      profileAsync.value!.career!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Opciones de Configuración Estilo iOS
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                    title: const Text(
                      'Tema Oscuro',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      isDark ? 'Modo noche activo (Slate Oscuro)' : 'Modo claro activo',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    trailing: CupertinoSwitch(
                      value: isDark,
                      activeTrackColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                      onChanged: (enabled) {
                        ref.read(themeModeProvider.notifier).toggleTheme(enabled);
                      },
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: Icon(
                      CupertinoIcons.qrcode,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                    title: const Text('Métodos de Cobro (Vendedor)'),
                    subtitle: const Text(
                      'Configura tu número o QR de Yape / Plin',
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      size: 18,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    onTap: () => _showPaymentMethodsInfo(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: Icon(
                      CupertinoIcons.shield_lefthalf_fill,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                    title: const Text('Normas de Seguridad en Campus'),
                    subtitle: const Text(
                      'Pautas para entregas en Los Olivos y sedes',
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      size: 18,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    onTap: () => _showSafetyGuidelines(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: Icon(
                      CupertinoIcons.info_circle,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                    title: const Text('Acerca de UCSS Market'),
                    subtitle: const Text('Versión 1.0.0'),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      size: 18,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botón Cerrar Sesión
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.square_arrow_right,
                      color: danger,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: danger,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: const Text('¿Cerrar Sesión?'),
                      content: const Text(
                        'Tendrás que volver a ingresar con tu correo @ucss.pe.',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('Cancelar'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text('Cerrar Sesión'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            ref.read(authControllerProvider.notifier).signOut();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodsInfo(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: 260,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Métodos de Cobro Estudiantil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Tus datos de Yape y Plin se gestionan directamente con la tabla `seller_payment_methods`. Cuando un compañero te compra, puede ver tu número o QR para hacer el abono seguro.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  child: const Text('Entendido'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSafetyGuidelines(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pautas de Seguridad UCSS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Concreta siempre tus intercambios dentro del campus (Cafetería, Pabellón B, Biblioteca).\n'
                '2. Revisa el estado del producto (libros, tecnología, uniformes) antes de finalizar.\n'
                '3. Toda transacción queda registrada con la orden en el sistema para tu respaldo académico.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  child: const Text('Aceptar'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
