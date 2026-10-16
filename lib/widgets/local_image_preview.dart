import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Vista previa de una imagen local proveniente de `image_picker`.
///
/// Sustituye al patrón `kIsWeb ? Image.network(path) : Image.file(File(path))`,
/// que tenía dos problemas:
///
///   1. `Image.network(path)` está mal en web: `XFile.path` ahí es un `blob:`
///      URL, no una URL http, así que la imagen no carga.
///   2. Obliga a importar `dart:io`, que **no existe en web** y rompe el
///      build completo de la plataforma web.
///
/// Esta versión lee los bytes y usa `Image.memory`, que funciona igual en
/// iOS, Android y web sin importar `dart:io`.
class LocalImagePreview extends StatelessWidget {
  final XFile file;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;

  const LocalImagePreview({
    super.key,
    required this.file,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    // En móvil `XFile.path` es una ruta del sistema; en web es un `blob:` URL
    // que Flutter puede decodificar con `NetworkImage` directamente. Ambas
    // rutas se resuelven aquí sin `dart:io`.
    if (kIsWeb) {
      return Image.network(
        file.path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => placeholder ?? const SizedBox.shrink(),
      );
    }

    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: fit,
            width: width,
            height: height,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => placeholder ?? const SizedBox.shrink(),
          );
        }

        if (snapshot.hasError) {
          return placeholder ?? const SizedBox.shrink();
        }

        return placeholder ??
            SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
      },
    );
  }
}
