import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/order.dart';
import '../../services/receipt_service.dart';

class OrderReceiptScreen extends StatelessWidget {
  final Order order;

  const OrderReceiptScreen({super.key, required this.order});

  String get _fileName =>
      'constancia_pedido_${order.id.substring(0, 8).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Constancia de pedido')),
      body: PdfPreview(
        build: (format) => ReceiptService.buildOrderReceipt(order),
        pdfFileName: '$_fileName.pdf',
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowSharing: true,
        allowPrinting: true,
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.download),
            onPressed: (actionContext, build, format) async {
              final messenger = ScaffoldMessenger.of(actionContext);
              final errorColor = Theme.of(actionContext).colorScheme.error;
              try {
                final bytes = await build(format);
                final path = await FileSaver.instance.saveAs(
                  name: _fileName,
                  bytes: bytes,
                  fileExtension: 'pdf',
                  mimeType: MimeType.pdf,
                );
                if (path != null) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('PDF guardado en: $path'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('No se pudo descargar: $e'),
                    backgroundColor: errorColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
