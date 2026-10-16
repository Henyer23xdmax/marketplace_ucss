import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';

class StorageService {
  static final _supabase = Supabase.instance.client;

  /// Sube una imagen capturada con ImagePicker al bucket de productos
  static String _getFileExtension(XFile file) {
    final name = file.name;
    if (name.contains('.')) {
      final ext = name.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext)) {
        return ext;
      }
    }

    final mime = file.mimeType;
    if (mime != null && mime.contains('/')) {
      final ext = mime.split('/').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext)) {
        return ext;
      }
    }

    return 'jpg';
  }

  static String _getContentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Sube una imagen capturada con ImagePicker al bucket de productos
  /// Ruta: {user_id}/{timestamp}.{ext}
  static Future<String> uploadProductImage(XFile imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión para subir imágenes');
    }

    final bytes = await imageFile.readAsBytes();
    final fileExt = _getFileExtension(imageFile);
    final contentType = _getContentType(fileExt);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${user.id}/$timestamp.$fileExt';

    await _supabase.storage
        .from(SupabaseConfig.productImagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    final publicUrl = _supabase.storage
        .from(SupabaseConfig.productImagesBucket)
        .getPublicUrl(path);

    return publicUrl;
  }

  /// Sube un comprobante de pago / voucher al bucket PRIVADO `payment-vouchers`.
  /// Ruta: {user_id}/voucher_{orderId}_{timestamp}.{ext}
  ///
  /// Devuelve el *path* relativo dentro del bucket, no una URL. El path se
  /// persiste en `payments.voucher_path` y se convierte en una URL firmada de
  /// corta duración con [createVoucherSignedUrl] en el momento de visualizarlo.
  static Future<String> uploadVoucherImage(
    XFile voucherFile, {
    String? orderId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión para subir el comprobante');
    }

    final bytes = await voucherFile.readAsBytes();
    final fileExt = _getFileExtension(voucherFile);
    final contentType = _getContentType(fileExt);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final orderPart = (orderId != null && orderId.isNotEmpty)
        ? '${orderId}_'
        : '';
    final path = '${user.id}/voucher_$orderPart$timestamp.$fileExt';

    await _supabase.storage
        .from(SupabaseConfig.vouchersBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    return path;
  }

  /// Genera una URL firmada de corta duración para un comprobante almacenado en
  /// el bucket privado. Devuelve `null` si no se pudo firmar.
  ///
  /// La política RLS de `storage.objects` permite firmar comprobantes solo a las
  /// partes involucradas en la orden (comprador y vendedor).
  static Future<String?> createVoucherSignedUrl(String path) async {
    try {
      return await _supabase.storage
          .from(SupabaseConfig.vouchersBucket)
          .createSignedUrl(path, SupabaseConfig.voucherSignedUrlTtl);
    } catch (_) {
      return null;
    }
  }
}
