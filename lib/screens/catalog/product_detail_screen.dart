import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../checkout/checkout_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isFavorite = ref.watch(favoritesProvider).contains(product.id);
    final currentUserId = ref.watch(
      currentUserProvider.select((user) => user?.id),
    );
    final isOwner = currentUserId != null && currentUserId == product.sellerId;
    final images = product.images.isNotEmpty
        ? product.images.map((i) => i.imageUrl).toList()
        : [product.mainImageUrl];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrimary = isDark ? AppColors.darkText : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;
    final successColor = isDark ? AppColors.darkSuccess : AppColors.success;
    final errorColor = isDark ? AppColors.darkError : AppColors.error;
    final warnContainer = isDark
        ? AppColors.darkWarningContainer
        : AppColors.warningContainer;
    final onWarnContainer = isDark
        ? AppColors.onDarkWarningContainer
        : AppColors.onWarningContainer;
    final favoriteLabel = isFavorite
        ? 'Quitar de favoritos'
        : 'Guardar en favoritos';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detalle del Artículo'),
        actions: [
          IconButton(
            tooltip: favoriteLabel,
            icon: Icon(
              isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              color: isFavorite ? errorColor : textPrimary,
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(product.id);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Galería de Imágenes con indicador
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount:
                              images.isNotEmpty && images.first.isNotEmpty
                              ? images.length
                              : 1,
                          onPageChanged: (index) =>
                              setState(() => _currentImageIndex = index),
                          itemBuilder: (context, index) {
                            final url = images.isNotEmpty ? images[index] : '';
                            if (url.isEmpty) {
                              return _buildImageFallback(
                                borderColor,
                                textSecondary,
                              );
                            }
                            return Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _buildImageFallback(
                                    borderColor,
                                    textSecondary,
                                  ),
                            );
                          },
                        ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Semantics(
                              label:
                                  'Imagen ${_currentImageIndex + 1} de ${images.length}',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(images.length, (i) {
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentImageIndex == i
                                          ? accent
                                          : AppColors.onPrimary.withValues(
                                              alpha: 0.6,
                                            ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Precio y Badge de Stock
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'S/ ${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: accent,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (product.stock > 0
                                        ? successColor
                                        : errorColor)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                product.stock > 0
                                    ? '${product.stock} disponibles'
                                    : 'Agotado',
                                style: TextStyle(
                                  color: product.stock > 0
                                      ? successColor
                                      : errorColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Título
                        Text(
                          product.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Ficha del Estudiante Vendedor (UCSS)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: accent,
                                child: Text(
                                  product.seller?.fullName.isNotEmpty == true
                                      ? product.seller!.fullName[0]
                                            .toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.onDarkPrimary
                                        : AppColors.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            product.seller?.fullName ??
                                                'Estudiante UCSS',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          CupertinoIcons.checkmark_seal_fill,
                                          color: accent,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      product.seller?.career ??
                                          'Comunidad Estudiantil UCSS',
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

                        const SizedBox(height: 24),

                        // Descripción
                        Text(
                          'Descripción',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description.isNotEmpty
                              ? product.description
                              : 'Sin descripción adicional.',
                          style: TextStyle(
                            fontSize: 14,
                            color: textPrimary,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Seguridad de Entrega en Campus
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: warnContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.shield_lefthalf_fill,
                                color: isDark
                                    ? AppColors.darkSecondary
                                    : AppColors.secondary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Paga seguro y recibe en los puntos oficiales dentro del campus UCSS.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: onWarnContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barra Inferior de Acción Estilo iOS
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: borderColor, width: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    icon: Icon(
                      isOwner
                          ? CupertinoIcons.checkmark_seal_fill
                          : CupertinoIcons.cart_badge_plus,
                      size: 20,
                    ),
                    label: Text(
                      isOwner
                          ? 'Este es tu producto'
                          : 'Comprar y Coordinar Entrega',
                    ),
                    onPressed: (!isOwner && product.stock > 0)
                        ? () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) =>
                                    CheckoutScreen(product: product),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback(Color background, Color iconColor) {
    return Container(
      color: background,
      child: Center(
        child: Icon(CupertinoIcons.photo, size: 64, color: iconColor),
      ),
    );
  }
}
