import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('orders')
        .select(
          '*, order_items (*, products (*)), delivery_spots (*), payments (*), seller_profile:profiles!orders_seller_id_fkey (*)',
        )
        .eq('buyer_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('Error cargando compras: $e');
    return [];
  }
});

final mySalesProvider = FutureProvider<List<Order>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('orders')
        .select(
          '*, order_items (*, products (*)), delivery_spots (*), payments (*), buyer_profile:profiles!orders_buyer_id_fkey (*)',
        )
        .eq('seller_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('Error cargando ventas: $e');
    return [];
  }
});

/// Firma de la RPC `process_order_payment` en PostgreSQL.
///
/// El monto y el método se resuelven SIEMPRE en el servidor a partir de los
/// ítems de la orden; el cliente solo indica que adjunta comprobante.
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

  /// Registra el pago invocando la RPC `process_order_payment`.
  ///
  /// El monto **no** se envía desde el dispositivo: la función SQL lo calcula
  /// desde `orders.total_amount`, de modo que un cliente modificado no puede
  /// registrar un pago de S/ 0.01 por una orden de S/ 500.
  ///
  /// [voucherPath] es el path dentro del bucket privado `payment-vouchers`.
  Future<void> processPayment({
    required String orderId,
    required String paymentMethod,
    String? voucherPath,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Debes iniciar sesión para pagar');
      }

      await Supabase.instance.client.rpc(
        'process_order_payment',
        params: {
          'p_order_id': orderId,
          'p_payment_method': paymentMethod,
          'p_voucher_path': voucherPath,
        },
      );

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
  ///
  /// Solo el vendedor de la orden puede ejecutar esta transición. La
  /// comprobación se hace en el cliente (evita un round-trip inútil) y la
  /// garantía real está en la política RLS `orders_seller_update` del servidor.
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
          .select('status, seller_id')
          .eq('id', orderId)
          .single();

      // Autorización: solo el vendedor de la orden puede cambiar su estado.
      // Sin esto, cualquier usuario autenticado con el id de la orden podía
      // aprobar pagos o marcar entregas ajenas.
      if (current['seller_id'] != user.id) {
        throw Exception('Solo el vendedor de esta orden puedeActualizarla');
      }

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
          .eq('id', orderId)
          .eq('seller_id', user.id);

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
  ///
  /// Solo el vendedor de la orden puede rechazar el pago.
  Future<void> rejectPayment({required String orderId}) async {
    state = const AsyncValue.loading();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Debes iniciar sesión');
      }

      final current = await Supabase.instance.client
          .from('orders')
          .select('status, seller_id')
          .eq('id', orderId)
          .single();

      if (current['seller_id'] != user.id) {
        throw Exception('Solo el vendedor de esta orden puede rechazar el pago');
      }

      if ((current['status'] as String?) != 'pago_en_revision') {
        throw Exception('La orden no está en revisión de pago');
      }

      await Supabase.instance.client
          .from('payments')
          .update({'status': 'rechazado'})
          .eq('order_id', orderId);

      await Supabase.instance.client
          .from('orders')
          .update({'status': 'pendiente_pago', 'paid_amount': 0})
          .eq('id', orderId)
          .eq('seller_id', user.id);

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

/// URL firmada de corta duración para un comprobante de pago.
///
/// El bucket `payment-vouchers` es privado, así que la imagen solo se puede
/// renderizar con una URL firmada válida. La URL expira en 15 minutos, por lo
/// que conviene refrescar el provider si la vista lleva mucho tiempo abierta.
final voucherSignedUrlProvider =
    FutureProvider.family<String?, String>((ref, voucherPath) async {
      if (voucherPath.isEmpty) return null;
      return StorageService.createVoucherSignedUrl(voucherPath);
    });
