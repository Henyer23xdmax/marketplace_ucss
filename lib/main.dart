import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/theme_constants.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Supabase con URL y Clave Pública de UCSS Marketplace
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Nota de Supabase: $e');
  }

  runApp(
    const ProviderScope(
      child: UcssMarketplaceApp(),
    ),
  );
}

class UcssMarketplaceApp extends ConsumerWidget {
  const UcssMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'UCSS Market',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}
