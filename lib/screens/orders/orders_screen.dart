import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../providers/orders_provider.dart';
import 'receipt_screen.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  int _selectedSegment = 0; // 0: Mis Compras, 1: Mis Ventas

  @override
  Widget build(BuildContext context) {
    final myOrdersAsync = ref.watch(myOrdersProvider);
    final mySalesAsync = ref.watch(mySalesProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Mis Pedidos')),
      body: Column(
        children: [
          // Selector Segmentado
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSegmentedControl<int>(
                groupValue: _selectedSegment,
                selectedColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                unselectedColor: isDark ? AppColors.darkSurface : AppColors.surface,
                borderColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                children: {
                  0: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Mis Compras',
                      style: TextStyle(
                        color: _selectedSegment == 0
                            ? (isDark ? AppColors.darkBackground : AppColors.onPrimary)
                            : (isDark ? AppColors.darkText : AppColors.textPrimary),
                      ),
                    ),
                  ),
                  1: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Mis Ventas',
                      style: TextStyle(
                        color: _selectedSegment == 1
                            ? (isDark ? AppColors.darkBackground : AppColors.onPrimary)
                            : (isDark ? AppColors.darkText : AppColors.textPrimary),
                      ),
                    ),
                  ),
                },
                onValueChanged: (val) => setState(() => _selectedSegment = val),
              ),
            ),
          ),

          Expanded(
            child: _selectedSegment == 0
                ? _buildOrderList(myOrdersAsync, isBuyer: true)
                : _buildOrderList(mySalesAsync, isBuyer: false),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(
    AsyncValue<List<Order>> ordersAsync, {
    required bool isBuyer,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isBuyer ? CupertinoIcons.bag : CupertinoIcons.tag,
                  size: 56,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                const SizedBox(height: 14),
                Text(
                  isBuyer ? 'No tienes compras aún' : 'No tienes ventas registradas',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBuyer
                      ? 'Los productos que compres en el campus aparecerán aquí.'
                      : 'Cuando te compren un artículo, lo gestionarás aquí.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: isDark ? 0.2 : 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _copyOrderNumber(order),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pedido N° ${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              CupertinoIcons.doc_on_doc,
                              size: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(order.status),
                    ],
                  ),
                  const Divider(height: 16),
                  if (order.items.isNotEmpty) ...[
                    Text(
                      order.items.first.productTitle ?? 'Artículo UCSS Market',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cantidad: ${order.items.first.quantity} | Total: S/ ${order.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (order.deliverySpot != null)
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 14,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.deliverySpot!.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  if (order.latestPayment != null) ...[
                    const SizedBox(height: 12),
                    _buildPaymentInfo(order.latestPayment!, isDark),
                  ],
                  if (!isBuyer) ...[
                    const SizedBox(height: 12),
                    _buildSellerActions(order),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(CupertinoIcons.doc, size: 16),
                      label: const Text('Ver constancia de pedido (PDF)'),
                      onPressed: () => _openReceipt(order),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Center(child: Text('Error al cargar órdenes: $e')),
    );
  }

  void _copyOrderNumber(Order order) {
    Clipboard.setData(ClipboardData(text: order.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Número de pedido copiado'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmReject(Order order) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('¿Rechazar comprobante?'),
        content: const Text(
          'El pago se marcará como rechazado y el comprador deberá subir un nuevo comprobante.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Rechazar'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _rejectPayment(order);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _rejectPayment(Order order) async {
    try {
      await ref
          .read(orderActionsProvider.notifier)
          .rejectPayment(orderId: order.id);

      ref.invalidate(mySalesProvider);
      ref.invalidate(myOrdersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Comprobante rechazado. El comprador deberá pagar de nuevo.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo rechazar: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(
    Order order,
    String newStatus,
    String successMessage,
  ) async {
    try {
      await ref
          .read(orderActionsProvider.notifier)
          .updateOrderStatus(orderId: order.id, newStatus: newStatus);

      ref.invalidate(mySalesProvider);
      ref.invalidate(myOrdersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo actualizar: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openReceipt(Order order) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => OrderReceiptScreen(order: order),
      ),
    );
  }

  Widget _buildPaymentInfo(Payment payment, bool isDark) {
    final textPrimary = isDark ? AppColors.darkText : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bubbleColor = isDark
        ? AppColors.darkBackground
        : AppColors.background;
    final hasVoucher =
        payment.voucherUrl != null && payment.voucherUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.creditcard,
                size: 16,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pago: ${payment.methodLabel} · S/ ${payment.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              _buildPaymentBadge(payment.status),
            ],
          ),
          if (hasVoucher) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showVoucher(payment.voucherUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  payment.voucherUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    color: borderColor,
                    child: Icon(CupertinoIcons.photo, color: textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toca la imagen para ampliar el comprobante',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Sin comprobante adjunto',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final success = isDark ? AppColors.darkSuccess : AppColors.success;
    final warning = isDark ? AppColors.darkWarning : AppColors.warning;
    final error = isDark ? AppColors.darkError : AppColors.error;
    final neutral = isDark ? AppColors.darkPrimary : AppColors.primary;

    Color color;
    String label;
    switch (status) {
      case 'aprobado':
        color = success;
        label = 'Aprobado';
        break;
      case 'rechazado':
        color = error;
        label = 'Rechazado';
        break;
      case 'pendiente':
        color = warning;
        label = 'Pendiente';
        break;
      case 'en_revision':
      default:
        color = neutral;
        label = 'En revisión';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showVoucher(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              CupertinoIcons.photo,
              color: AppColors.onPrimary,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSellerActions(Order order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (order.status == 'pago_en_revision') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(CupertinoIcons.xmark, size: 16),
              label: const Text('Rechazar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.darkError : AppColors.error,
              ),
              onPressed: () => _confirmReject(order),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(CupertinoIcons.checkmark_circle_fill, size: 18),
              label: const Text('Confirmar pago'),
              onPressed: () => _updateStatus(order, 'pagado', 'Pago confirmado'),
            ),
          ),
        ],
      );
    }

    if (order.status == 'pagado') {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(CupertinoIcons.checkmark_seal_fill, size: 18),
          label: const Text('Marcar como entregado'),
          onPressed: () => _updateStatus(
            order,
            'entregado',
            'Pedido marcado como entregado',
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatusBadge(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final success = isDark ? AppColors.darkSuccess : AppColors.success;
    final warning = isDark ? AppColors.darkWarning : AppColors.warning;
    final error = isDark ? AppColors.darkError : AppColors.error;
    final neutral = isDark ? AppColors.darkPrimary : AppColors.primary;

    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'pagado':
      case 'entregado':
        bg = success.withValues(alpha: 0.15);
        fg = success;
        label = status == 'entregado' ? 'Entregado' : 'Pagado';
        break;
      case 'pago_en_revision':
        bg = warning.withValues(alpha: 0.15);
        fg = warning;
        label = 'En Revisión';
        break;
      case 'cancelado':
        bg = error.withValues(alpha: 0.15);
        fg = error;
        label = 'Cancelado';
        break;
      default:
        bg = neutral.withValues(alpha: 0.12);
        fg = neutral;
        label = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
