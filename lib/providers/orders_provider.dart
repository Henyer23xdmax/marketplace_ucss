import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import 'auth_provider.dart';

final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('orders')
        .select('''
          *,
          order_items (*, products (*)),
          delivery_spots (*),
          payments (*),
          seller_profile:profiles!orders_seller_id_fkey (*)
        ''')
        .eq('buyer_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

final mySalesProvider = FutureProvider<List<Order>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('orders')
        .select('''
          *,
          order_items (*, products (*)),
          delivery_spots (*),
          payments (*),
          buyer_profile:profiles!orders_buyer_id_fkey (*)
        ''')
        .eq('seller_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

class OrderActionsNotifier extends StateNotifier<AsyncValue<void>> {
  OrderActionsNotifier() : super(const AsyncValue.data(null));

  /// Invoca la función RPC `create_market_order` con reserva y bloqueo pesimista en PostgreSQL
  Future<String> createMarketOrder({
    required String sellerId,
    required String? deliverySpotId,
    required String productId,
    required int quantity,
    required double unitPrice,
    String? deliveryNotes,
    String? clientRequestId,
  }) async {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    final validSpotId = (deliverySpotId != null && uuidRegex.hasMatch(deliverySpotId))
        ? deliverySpotId
        : null;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Debes iniciar sesión para realizar un pedido');
      }

      if (user.id == sellerId) {
        throw Exception('No puedes comprar un producto publicado por ti mismo');
      }

      // Si el producto seleccionado es de la lista de muestra local (ej. 'm2', 'm4')
      if (!uuidRegex.hasMatch(productId)) {
        throw Exception(
          'Este es un artículo de muestra local. Para probar compras en tu base de datos real, ve a la pestaña "Vender" y publica tu primer producto real.',
        );
      }

      // Invocación exacta según la firma SQL de public.create_market_order:
      // (p_buyer_id UUID, p_product_id UUID, p_quantity INT, p_delivery_spot_id UUID, p_delivery_notes TEXT)
      final response = await Supabase.instance.client.rpc(
        'create_market_order',
        params: {
          'p_buyer_id': user.id,
          'p_product_id': productId,
          'p_quantity': quantity,
          'p_delivery_spot_id': validSpotId,
          'p_delivery_notes': deliveryNotes,
          'p_client_request_id': clientRequestId,
        },
      );

      state = const AsyncValue.data(null);

      if (response is Map && response['order_id'] != null) {
        return response['order_id'].toString();
      }
      return response.toString();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Registra el pago en la tabla `payments` y actualiza la orden
  Future<void> processPayment({
    required String orderId,
    required double amount,
    required String paymentMethod,
    String? voucherUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Inserción en tabla payments:
      // columnas: order_id, method_type, amount, status, voucher_url
      final status = paymentMethod == 'efectivo' ? 'aprobado' : 'pendiente';

      await Supabase.instance.client.from('payments').insert({
        'order_id': orderId,
        'method_type': paymentMethod, // 'yape', 'plin', 'efectivo', 'tarjeta'
        'amount': amount,
        'status': status,
        'voucher_url': voucherUrl,
      });

      // Actualizar paid_amount y status en la orden
      final newOrderStatus =
          paymentMethod == 'efectivo' ? 'pagado' : 'pago_en_revision';

      await Supabase.instance.client.from('orders').update({
        'status': newOrderStatus,
        'paid_amount': amount,
      }).eq('id', orderId);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Transiciones válidas de estado de una orden (flujo del vendedor).
  static const Map<String, String> _allowedTransitions = {
    'pago_en_revision': 'pagado',
    'pagado': 'entregado',
  };

  /// Actualiza el estado de una orden validando la transición.
  ///   pago_en_revision -> pagado     (el vendedor aprueba el voucher)
  ///   pagado           -> entregado  (el vendedor entrega el producto)
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Debes iniciar sesión');
      }

      final current = await Supabase.instance.client
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .single();

      final currentStatus = current['status'] as String?;
      if (currentStatus == null ||
          _allowedTransitions[currentStatus] != newStatus) {
        throw Exception(
          'Transición de estado no permitida ($currentStatus → $newStatus)',
        );
      }

      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      // Al aprobar el pago, marca también el comprobante como aprobado
      if (newStatus == 'pagado') {
        await Supabase.instance.client
            .from('payments')
            .update({'status': 'aprobado'})
            .eq('order_id', orderId);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// El vendedor rechaza el comprobante: marca el pago como rechazado y
  /// devuelve la orden a `pendiente_pago` para que el comprador vuelva a pagar.
  Future<void> rejectPayment({required String orderId}) async {
    state = const AsyncValue.loading();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Debes iniciar sesión');
      }

      final current = await Supabase.instance.client
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .single();

      if ((current['status'] as String?) != 'pago_en_revision') {
        throw Exception('La orden no está en revisión de pago');
      }

      await Supabase.instance.client
          .from('payments')
          .update({'status': 'rechazado'})
          .eq('order_id', orderId)
          .inFilter('status', ['pendiente', 'en_revision']);

      await Supabase.instance.client
          .from('orders')
          .update({'status': 'pendiente_pago', 'paid_amount': 0})
          .eq('id', orderId);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final orderActionsProvider =
    StateNotifierProvider<OrderActionsNotifier, AsyncValue<void>>((ref) {
  return OrderActionsNotifier();
});
