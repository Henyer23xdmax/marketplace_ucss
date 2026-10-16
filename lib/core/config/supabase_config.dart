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

  /// Nombre del bucket público en Supabase Storage (imágenes de producto).
  static const String productImagesBucket = 'product-images';

  /// Bucket PRIVADO para los comprobantes de pago (Yape/Plin).
  ///
  /// No debe ser público: un comprobante expone nombre, monto, hora y número de
  /// operación. Se sirve mediante URLs firmadas de corta duración generadas en
  /// [StorageService.createVoucherSignedUrl].
  static const String vouchersBucket = 'payment-vouchers';

  /// Vigencia de las URLs firmadas de comprobantes, en segundos (15 minutos).
  static const int voucherSignedUrlTtl = 900;

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

    await Supabase.initialize(url: cleanUrl, publishableKey: key);
    debugPrint('⚡ Supabase inicializado con URL: $cleanUrl');
  }

  /// Instancia directa del cliente de Supabase
  static SupabaseClient get client => Supabase.instance.client;
}
