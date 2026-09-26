import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  /// URL base del proyecto Supabase (sin /rest/v1/ al final)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://koxavzmvmwflsnmmwvyq.supabase.co',
  );

  /// Clave pública anonKey de Supabase
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_B0v5ENiK-UySzHhMZrTAow_BF4viEVA',
  );

  /// Nombre del bucket público en Supabase Storage
  static const String productImagesBucket = 'product-images';

  /// Inicializa Supabase para la aplicación limpiando rutas
  static Future<void> initialize({
    String? customUrl,
    String? customAnonKey,
  }) async {
    String cleanUrl = (customUrl ?? supabaseUrl).trim();

    // El SDK de Flutter requiere la URL raíz, sin '/rest/v1/' ni slashes finales
    if (cleanUrl.contains('/rest/v1')) {
      cleanUrl = cleanUrl.replaceAll('/rest/v1/', '').replaceAll('/rest/v1', '');
    }
    while (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    final key = (customAnonKey ?? supabaseAnonKey).trim();

    await Supabase.initialize(url: cleanUrl, anonKey: key);
    debugPrint('⚡ Supabase inicializado con URL: $cleanUrl');
  }

  /// Instancia directa del cliente de Supabase
  static SupabaseClient get client => Supabase.instance.client;

  /// Método para verificar la conexión directa a la base de datos
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await client.from('categories').select().limit(3);
      return {
        'success': true,
        'message': '¡Conectado exitosamente con Supabase!',
        'categories_found': (response as List).length,
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al conectar: $e',
      };
    }
  }
}
