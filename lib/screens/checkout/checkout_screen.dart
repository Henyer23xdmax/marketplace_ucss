import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/theme_constants.dart';
import '../../models/product.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/orders_provider.dart';
import '../../services/storage_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final Product product;

  const CheckoutScreen({super.key, required this.product});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _quantity = 1;
  String? _selectedSpotId;
  String _paymentMethod = 'yape'; // 'yape', 'plin', 'efectivo'
  XFile? _voucherImage;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  late final String _clientRequestId;

  @override
  void initState() {
    super.initState();
    _clientRequestId =
        'chk-${DateTime.now().microsecondsSinceEpoch}-${widget.product.id}';
  }

  Future<void> _pickVoucher() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (photo != null) {
      setState(() => _voucherImage = photo);
    }
  }

  Future<void> _processOrder() async {
    final spots = ref.read(deliverySpotsProvider).asData?.value ?? [];
    final spotId =
        _selectedSpotId ?? (spots.isNotEmpty ? spots.first.id : null);

    if (spotId == null) {
      _showSnack(
        'No se encontraron puntos de entrega disponibles en la base de datos',
        isError: true,
      );
      return;
    }

    if ((_paymentMethod == 'yape' || _paymentMethod == 'plin') &&
        _voucherImage == null) {
      _showSnack(
        'Para pagos con Yape/Plin debes adjuntar la captura del comprobante',
        isError: true,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final total = widget.product.price * _quantity;

      // Si es un producto de demostración local (mock inicial)
      if (widget.product.id.startsWith('c0000000-')) {
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          _showOrderSuccessDialog(
            'DEMO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          );
        }
        return;
      }

      // 1. Crear Orden con RPC `create_market_order` (bloqueo pesimista y reserva)
      final orderId = await ref
          .read(orderActionsProvider.notifier)
          .createMarketOrder(
            sellerId: widget.product.sellerId,
            deliverySpotId: spotId,
            productId: widget.product.id,
            quantity: _quantity,
            unitPrice: widget.product.price,
            clientRequestId: _clientRequestId,
          );

      // 2. Si subió voucher, enviarlo a Supabase Storage
      String? voucherUrl;
      if (_voucherImage != null) {
        voucherUrl = await StorageService.uploadVoucherImage(_voucherImage!);
      }

      // 3. Procesar Pago con RPC `process_order_payment`
      await ref
          .read(orderActionsProvider.notifier)
          .processPayment(
            orderId: orderId,
            amount: total,
            paymentMethod: _paymentMethod,
            voucherUrl: voucherUrl,
          );

      // Invalida catálogo y órdenes para refrescar stock y lista de compras
      ref.invalidate(productsProvider);
      ref.invalidate(myOrdersProvider);

      if (mounted) {
        _showOrderSuccessDialog(orderId);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          'Error al procesar el pedido: ${e.toString().replaceAll("Exception: ", "")}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showOrderSuccessDialog(String orderId) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('¡Pedido Confirmado! 🎉'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Tu orden ha sido registrada exitosamente.\n\nPuedes coordinar los detalles finales de la entrega en el punto seleccionado del campus.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Entendido'),
            onPressed: () {
              Navigator.of(ctx).pop(); // cierra diálogo
              Navigator.of(context).pop(); // regresa a detalle
              Navigator.of(context).pop(); // regresa a catálogo
            },
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isError
        ? (isDark ? AppColors.darkError : AppColors.error)
        : (isDark ? AppColors.darkSuccess : AppColors.success);
    final foreground = isDark && !isError
        ? AppColors.darkBackground
        : AppColors.onPrimary;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: foreground)),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final spotsAsync = ref.watch(deliverySpotsProvider);
    final total = product.price * _quantity;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrimary = isDark ? AppColors.darkText : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;
    final successColor = isDark ? AppColors.darkSuccess : AppColors.success;
    final inputBubbleColor = isDark
        ? AppColors.darkBackground
        : AppColors.background;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Confirmar Pedido')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen del Producto
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: product.mainImageUrl.isNotEmpty
                          ? Image.network(
                              product.mainImageUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(color: borderColor),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'S/ ${product.price.toStringAsFixed(2)} c/u',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Selector de Cantidad
                  Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        minimumSize: const Size(44, 44),
                        child: Semantics(
                          button: true,
                          label: 'Disminuir cantidad',
                          child: Icon(
                            CupertinoIcons.minus_circle,
                            color: _quantity > 1 ? accent : textSecondary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '$_quantity',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _quantity < product.stock
                            ? () => setState(() => _quantity++)
                            : null,
                        minimumSize: const Size(44, 44),
                        child: Semantics(
                          button: true,
                          label: 'Aumentar cantidad',
                          child: Icon(
                            CupertinoIcons.plus_circle,
                            color: _quantity < product.stock
                                ? accent
                                : textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 1. Punto de Encuentro en Campus UCSS
            Text(
              '1. Punto de Encuentro en Campus',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: spotsAsync.when(
                data: (spots) {
                  if (spots.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 12,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.location_slash,
                            size: 38,
                            color: textSecondary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No hay puntos de entrega registrados en Supabase',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Debes insertar los registros en la tabla delivery_spots o habilitar permisos RLS en Supabase.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CupertinoButton.filled(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: const Text(
                              'Reintentar carga',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () => ref.refresh(deliverySpotsProvider),
                          ),
                        ],
                      ),
                    );
                  }

                  final effectiveSelectedId = _selectedSpotId ?? spots.first.id;

                  return Column(
                    children: spots.map((spot) {
                      final isSelected = effectiveSelectedId == spot.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSpotId = spot.id),
                        child: Semantics(
                          button: true,
                          selected: isSelected,
                          label: 'Punto de entrega ${spot.name}',
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accent.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? accent : borderColor,
                                width: isSelected ? 1.4 : 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                  color: isSelected ? accent : textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        spot.name,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          fontSize: 14,
                                          color: textPrimary,
                                        ),
                                      ),
                                      if (spot.locationDetails != null)
                                        Text(
                                          spot.locationDetails!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Error al cargar puntos: $err',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. Método de Pago
            Text(
              '2. Método de Pago Estudiantil',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildPaymentRadio(
                    'yape',
                    'Yape',
                    AppColors.yapePurple,
                    CupertinoIcons.qrcode,
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildPaymentRadio(
                    'plin',
                    'Plin',
                    AppColors.plinCyan,
                    CupertinoIcons.qrcode,
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildPaymentRadio(
                    'efectivo',
                    'Efectivo contra entrega',
                    successColor,
                    CupertinoIcons.money_dollar,
                  ),

                  if (_paymentMethod == 'yape' || _paymentMethod == 'plin') ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: inputBubbleColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _paymentMethod == 'yape'
                                    ? CupertinoIcons.qrcode
                                    : CupertinoIcons.phone,
                                size: 18,
                                color: _paymentMethod == 'yape'
                                    ? AppColors.yapePurple
                                    : AppColors.plinCyan,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Comprobante / Voucher de $_paymentMethod',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_voucherImage == null)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  CupertinoIcons.camera,
                                  size: 18,
                                ),
                                label: const Text('Adjuntar Comprobante'),
                                onPressed: _pickVoucher,
                              ),
                            )
                          else
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: kIsWeb
                                        ? Image.network(
                                            _voucherImage!.path,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(_voucherImage!.path),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Voucher cargado correctamente',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _pickVoucher,
                                  child: const Text('Cambiar'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Resumen de Totales
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal:',
                        style: TextStyle(color: textSecondary),
                      ),
                      Text(
                        'S/ ${total.toStringAsFixed(2)}',
                        style: TextStyle(color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Costo de Entrega en Campus:',
                        style: TextStyle(color: textSecondary),
                      ),
                      Text(
                        'Gratis (Punto UCSS)',
                        style: TextStyle(
                          color: successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 20, color: borderColor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total a Pagar:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'S/ ${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botón de Confirmación
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isProcessing ? null : _processOrder,
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoActivityIndicator(
                            color: isDark
                                ? AppColors.onDarkPrimary
                                : AppColors.onPrimary,
                          ),
                          const SizedBox(width: 10),
                          const Text('Confirmando orden en Supabase...'),
                        ],
                      )
                    : Text(
                        'Confirmar Orden (S/ ${total.toStringAsFixed(2)})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRadio(
    String value,
    String title,
    Color color,
    IconData icon,
  ) {
    final isSelected = _paymentMethod == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      label: title,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: Icon(
          isSelected
              ? CupertinoIcons.checkmark_circle_fill
              : CupertinoIcons.circle,
          color: isSelected ? accent : textSecondary,
        ),
        onTap: () => setState(() => _paymentMethod = value),
      ),
    );
  }
}
