import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/order.dart';

class ReceiptService {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/ ',
    decimalDigits: 2,
  );
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Devuelve los bytes del PDF para previsualizarlo dentro de la app.
  static Future<Uint8List> buildOrderReceipt(Order order) {
    return _buildDocument(order).save();
  }

  /// Genera la constancia interna del pedido y abre el diálogo para
  /// compartirla o imprimirla como PDF.
  static Future<void> shareOrderReceipt(Order order) async {
    final doc = _buildDocument(order);
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'constancia_pedido_${_shortId(order.id)}.pdf',
    );
  }

  static String _shortId(String id) =>
      id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  static pw.Document _buildDocument(Order order) {
    final doc = pw.Document();
    final payment = order.latestPayment;
    final items = order.items.isNotEmpty ? order.items : null;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'UCSS MARKET',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Constancia interna de pedido',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Pedido N° ${_shortId(order.id)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    order.createdAt != null
                        ? _dateFormat.format(order.createdAt!)
                        : '—',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _personBlock(
                  'Vendedor',
                  order.seller?.fullName,
                  order.seller?.career,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _personBlock(
                  'Comprador',
                  order.buyer?.fullName,
                  order.buyer?.career,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Detalle del pedido',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const ['Artículo', 'Cant.', 'P. Unit.', 'Subtotal'],
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            data: items == null
                ? [
                    [
                      order.items.isNotEmpty
                          ? (order.items.first.productTitle ??
                              'Artículo UCSS Market')
                          : 'Artículo UCSS Market',
                      '1',
                      _currency.format(order.total),
                      _currency.format(order.total),
                    ],
                  ]
                : items
                    .map(
                      (item) => [
                        item.productTitle ?? 'Artículo UCSS Market',
                        '${item.quantity}',
                        _currency.format(item.unitPrice),
                        _currency.format(item.unitPrice * item.quantity),
                      ],
                    )
                    .toList(),
          ),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total: ${_currency.format(order.total)}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Entrega',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            order.deliverySpot != null
                ? '${order.deliverySpot!.name}'
                    '${order.deliverySpot!.locationDetails != null ? ' — ${order.deliverySpot!.locationDetails}' : ''}'
                : 'Punto de encuentro por coordinar',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Pago',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            payment != null
                ? 'Método: ${payment.methodLabel}   ·   '
                    'Monto: ${_currency.format(payment.amount)}   ·   '
                    'Estado: ${_paymentStatus(payment.status)}'
                : 'Sin pago registrado',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Text(
              'Este documento es una constancia interna generada automáticamente '
              'por UCSS Market. No constituye boleta ni factura de venta y carece '
              'de validez tributaria ante SUNAT. UCSS Market actúa únicamente como '
              'intermediario de coordinación entre estudiantes.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _personBlock(String role, String? name, String? career) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          role,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          name ?? 'Estudiante UCSS',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        if (career != null && career.isNotEmpty)
          pw.Text(
            career,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
      ],
    );
  }

  static String _paymentStatus(String status) {
    switch (status) {
      case 'aprobado':
        return 'Aprobado';
      case 'rechazado':
        return 'Rechazado';
      case 'pendiente':
        return 'Pendiente';
      case 'en_revision':
      default:
        return 'En revisión';
    }
  }
}
