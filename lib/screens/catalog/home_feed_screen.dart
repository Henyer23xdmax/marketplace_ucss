import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final productsAsync = ref.watch(productsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.building_2_fill,
              size: 18,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
            const SizedBox(width: 6),
            const Text(
              'UCSS Los Olivos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.location_solid,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
            tooltip: 'Puntos de Entrega UCSS',
            onPressed: () => _showDeliverySpotsModal(context, ref),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Buscador estilo adaptable
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: CupertinoSearchTextField(
                placeholder: 'Buscar libros, guías, tecnología...',
                            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
                style: TextStyle(color: isDark ? AppColors.darkText : AppColors.textPrimary),
                placeholderStyle: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                itemColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              ),
            ),
          ),

          // Banner del Campus UCSS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkSurface, AppColors.darkBackground]
                        : [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Entregas Seguras en Campus',
                            style: TextStyle(
                              color: AppColors.onPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Coordina en cafetería, biblioteca o pabellón B entre clases.',
                            style: TextStyle(
                              color: AppColors.onPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.shield_lefthalf_fill,
                        color: isDark ? AppColors.darkPrimary : AppColors.secondary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Carrusel Horizontal de Categorías
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: categoriesAsync.when(
                data: (categories) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isAll = selectedCategory == null;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('Todos'),
                            selected: isAll,
                            selectedColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.border,
                              width: 0.8,
                            ),
                            labelStyle: TextStyle(
                              color: isAll
                                  ? (isDark ? AppColors.darkBackground : AppColors.onPrimary)
                                  : (isDark ? AppColors.darkText : AppColors.textPrimary),
                              fontWeight: isAll
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            onSelected: (_) {
                              ref
                                      .read(selectedCategoryProvider.notifier)
                                      .state =
                                  null;
                            },
                          ),
                        );
                      }

                      final cat = categories[index - 1];
                      final isSelected = selectedCategory == cat.id;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            cat.cupertinoIcon,
                            size: 16,
                            color: isSelected
                                ? (isDark ? AppColors.darkBackground : AppColors.onPrimary)
                                : (isDark ? AppColors.darkPrimary : AppColors.primary),
                          ),
                          label: Text(cat.name),
                          selected: isSelected,
                          selectedColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                                      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
                          side: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                            width: 0.8,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (isDark ? AppColors.darkBackground : AppColors.onPrimary)
                                : (isDark ? AppColors.darkText : AppColors.textPrimary),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                          onSelected: (_) {
                            ref.read(selectedCategoryProvider.notifier).state =
                                isSelected ? null : cat.id;
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Cuadrícula de Productos
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.search,
                        size: 50,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay artículos disponibles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sé el primero de tu carrera en publicar.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(product: product),
                          ),
                        );
                      },
                    );
                  }, childCount: products.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator(radius: 14)),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(child: Text('Error al cargar catálogo: $err')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  void _showDeliverySpotsModal(BuildContext context, WidgetRef ref) {
    final spotsAsync = ref.read(deliverySpotsProvider);

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Puntos de Entrega UCSS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Listo'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Zonas recomendadas y seguras dentro del campus para concretar tus intercambios y compras:',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: spotsAsync.when(
                  data: (spots) => ListView.separated(
                    itemCount: spots.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final spot = spots[i];
                      return ListTile(
                        leading: Icon(
                          CupertinoIcons.location_fill,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                        ),
                        title: Text(
                          spot.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: spot.locationDetails != null
                            ? Text(spot.locationDetails!)
                            : null,
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CupertinoActivityIndicator()),
                  error: (_, _) =>
                      const Text('No se pudieron cargar los puntos'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
