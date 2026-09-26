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

  /// Sube un comprobante de pago / voucher a la carpeta de vouchers
  static Future<String> uploadVoucherImage(XFile voucherFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión para subir el comprobante');
    }

    final bytes = await voucherFile.readAsBytes();
    final fileExt = _getFileExtension(voucherFile);
    final contentType = _getContentType(fileExt);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${user.id}/voucher_$timestamp.$fileExt';

    await _supabase.storage
        .from(SupabaseConfig.productImagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return _supabase.storage
        .from(SupabaseConfig.productImagesBucket)
        .getPublicUrl(path);
  }
}
