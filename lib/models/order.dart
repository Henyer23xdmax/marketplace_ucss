import 'delivery_spot.dart';
import 'payment.dart';
import 'profile.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final String? productTitle;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.productTitle,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'].toString(),
      orderId: json['order_id'].toString(),
      productId: json['product_id'].toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      productTitle: json['products']?['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}

class Order {
  final String id;
  final String buyerId;
  final String sellerId;
  final String? deliverySpotId;
  final String status; // 'pendiente_pago', 'pago_en_revision', 'pagado', 'entregado', 'cancelado'
  final double total;
  final double paidAmount;
  final double balanceDue;
  final DateTime? createdAt;
  final List<OrderItem> items;
  final DeliverySpot? deliverySpot;
  final Profile? seller;
  final Profile? buyer;
  final List<Payment> payments;

  Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.deliverySpotId,
    required this.status,
    required this.total,
    required this.paidAmount,
    required this.balanceDue,
    this.createdAt,
    this.items = const [],
    this.deliverySpot,
    this.seller,
    this.buyer,
    this.payments = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> parsedItems = [];
    if (json['order_items'] != null && json['order_items'] is List) {
      parsedItems = (json['order_items'] as List)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    DeliverySpot? spot;
    if (json['delivery_spots'] != null && json['delivery_spots'] is Map<String, dynamic>) {
      spot = DeliverySpot.fromJson(json['delivery_spots'] as Map<String, dynamic>);
    }

    Profile? sellerProf;
    if (json['seller_profile'] != null && json['seller_profile'] is Map<String, dynamic>) {
      sellerProf = Profile.fromJson(json['seller_profile'] as Map<String, dynamic>);
    }

    Profile? buyerProf;
    if (json['buyer_profile'] != null && json['buyer_profile'] is Map<String, dynamic>) {
      buyerProf = Profile.fromJson(json['buyer_profile'] as Map<String, dynamic>);
    }

    List<Payment> parsedPayments = [];
    if (json['payments'] != null && json['payments'] is List) {
      parsedPayments = (json['payments'] as List)
          .map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList();
      parsedPayments.sort((a, b) {
        final da = a.createdAt;
        final db = b.createdAt;
        if (da == null || db == null) return 0;
        return da.compareTo(db);
      });
    }

    return Order(
      id: json['id'].toString(),
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      deliverySpotId: json['delivery_spot_id']?.toString(),
      status: json['status'] as String? ?? 'pendiente_pago',
      total: (json['total_amount'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (json['balance_due'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      items: parsedItems,
      deliverySpot: spot,
      seller: sellerProf,
      buyer: buyerProf,
      payments: parsedPayments,
    );
  }

  Payment? get latestPayment => payments.isNotEmpty ? payments.last : null;

  String get statusLabel {
    switch (status) {
      case 'pendiente_pago':
        return 'Pendiente de Pago';
      case 'pago_en_revision':
        return 'Pago en Revisión';
      case 'pagado':
        return 'Pagado';
      case 'entregado':
        return 'Entregado en Campus';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }
}
