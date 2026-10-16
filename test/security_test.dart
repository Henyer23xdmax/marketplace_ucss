import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_ucss_ios/models/payment.dart';
import 'package:marketplace_ucss_ios/providers/auth_provider.dart';

void main() {
  group('Validación de dominio @ucss.pe (punto 4)', () {
    test('acepta correos institucionales', () {
      expect(isUcssEmail('estudiante@ucss.pe'), isTrue);
      expect(isUcssEmail('  estudiante@ucss.pe  '), isTrue,
          reason: 'debe tolerar espacios alrededor');
      expect(isUcssEmail('ESTUDIANTE@UCSS.PE'), isTrue,
          reason: 'el dominio no es sensible a mayúsculas');
    });

    test('rechaza correos no institucionales', () {
      expect(isUcssEmail('alguien@gmail.com'), isFalse);
      expect(isUcssEmail('profesor@ucss.edu.pe'), isFalse);
      expect(isUcssEmail('ucss.pe'), isFalse);
      expect(isUcssEmail(''), isFalse);
    });

    test('no acepta sufijo malicioso', () {
      // Un atacante podría intentar colar el dominio al final de otra cadena.
      expect(isUcssEmail('falso@ucss.pe.evil.com'), isFalse);
      expect(isUcssEmail('ucss.pe@evil.com'), isFalse);
    });
  });

  group('Payment.voucherRef (punto 1)', () {
    Payment build({String? path, String? url}) => Payment(
          id: 'p1',
          orderId: 'o1',
          amount: 25.0,
          paymentMethod: 'yape',
          voucherPath: path,
          voucherUrl: url,
          status: 'pendiente',
        );

    test('prefiere el path del bucket privado', () {
      final p = build(path: 'user-1/voucher.jpg', url: 'https://x/y.jpg');
      expect(p.voucherRef, 'user-1/voucher.jpg');
      expect(p.voucherIsPrivate, isTrue);
    });

    test('usa la URL absoluta en pagos legacy', () {
      final p = build(url: 'https://x/y.jpg');
      expect(p.voucherRef, 'https://x/y.jpg');
      expect(p.voucherIsPrivate, isFalse);
    });

    test('no hay referencia si nunca se subió comprobante', () {
      final p = build();
      expect(p.voucherRef, isNull);
      expect(p.voucherIsPrivate, isFalse);
    });

    test('un path vacío no cuenta como privado', () {
      final p = build(path: '');
      expect(p.voucherIsPrivate, isFalse);
    });
  });

  group('Payment.fromJson (punto 1)', () {
    test('lee voucher_path del JSON', () {
      final p = Payment.fromJson({
        'id': 'abc',
        'order_id': 'o1',
        'amount': 10,
        'method_type': 'plin',
        'voucher_path': 'u1/v.jpg',
        'status': 'pendiente',
      });

      expect(p.voucherPath, 'u1/v.jpg');
      expect(p.voucherIsPrivate, isTrue);
    });

    test('tolera pagos antiguos sin voucher_path', () {
      final p = Payment.fromJson({
        'id': 'abc',
        'order_id': 'o1',
        'amount': 10,
        'method_type': 'efectivo',
        'status': 'aprobado',
      });

      expect(p.voucherPath, isNull);
      expect(p.voucherIsPrivate, isFalse);
    });
  });
}
