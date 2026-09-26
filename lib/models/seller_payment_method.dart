class SellerPaymentMethod {
  final String id;
  final String sellerId;
  final String type; // 'yape', 'plin', 'efectivo', 'transferencia'
  final String? phoneNumber;
  final String? qrUrl;
  final String? accountHolder;

  SellerPaymentMethod({
    required this.id,
    required this.sellerId,
    required this.type,
    this.phoneNumber,
    this.qrUrl,
    this.accountHolder,
  });

  factory SellerPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SellerPaymentMethod(
      id: json['id'].toString(),
      sellerId: json['seller_id'] as String,
      type: json['type'] as String,
      phoneNumber: json['phone_number'] as String?,
      qrUrl: json['qr_url'] as String?,
      accountHolder: json['account_holder'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'type': type,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (qrUrl != null) 'qr_url': qrUrl,
      if (accountHolder != null) 'account_holder': accountHolder,
    };
  }

  String get displayName {
    switch (type.toLowerCase()) {
      case 'yape':
        return 'Yape';
      case 'plin':
        return 'Plin';
      case 'efectivo':
        return 'Efectivo en Campus';
      case 'transferencia':
        return 'Transferencia Bancaria';
      default:
        return type.toUpperCase();
    }
  }
}
