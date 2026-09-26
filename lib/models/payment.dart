class Payment {
  final String id;
  final String orderId;
  final double amount;
  final String paymentMethod; // 'yape', 'plin', 'efectivo', 'transferencia'
  final String? voucherUrl;
  final String status; // 'en_revision', 'aprobado', 'rechazado'
  final DateTime? createdAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    this.voucherUrl,
    required this.status,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'].toString(),
      orderId: json['order_id'].toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod:
          (json['method_type'] ?? json['payment_method']) as String? ??
          'efectivo',
      voucherUrl: json['voucher_url'] as String?,
      status: json['status'] as String? ?? 'en_revision',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'payment_method': paymentMethod,
      if (voucherUrl != null) 'voucher_url': voucherUrl,
      'status': status,
    };
  }

  String get methodLabel {
    switch (paymentMethod.toLowerCase()) {
      case 'yape':
        return 'Yape';
      case 'plin':
        return 'Plin';
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta';
      case 'transferencia':
        return 'Transferencia';
      default:
        return paymentMethod.toUpperCase();
    }
  }
}
