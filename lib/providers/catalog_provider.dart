import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/delivery_spot.dart';
import '../models/product.dart';
import '../services/storage_service.dart';

import 'package:image_picker/image_picker.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  List<dynamic>? rawList;

  // 1. Intentar con 'categories'
  try {
    final res = await Supabase.instance.client.from('categories').select();
    if (res.isNotEmpty) {
      rawList = res;
    }
  } catch (e) {
    debugPrint('Nota categories Supabase: $e');
  }

  // 2. Si no encontró, intentar en español con 'categorias'
  if (rawList == null || rawList.isEmpty) {
    try {
      final res = await Supabase.instance.client.from('categorias').select();
      if (res.isNotEmpty) {
        rawList = res;
      }
    } catch (e) {
      debugPrint('Nota categorias Supabase: $e');
    }
  }

  // 3. Si no encontró, intentar singular 'category'
  if (rawList == null || rawList.isEmpty) {
    try {
      final res = await Supabase.instance.client.from('category').select();
      if (res.isNotEmpty) {
        rawList = res;
      }
    } catch (e) {
      debugPrint('Nota category Supabase: $e');
    }
  }

  if (rawList != null && rawList.isNotEmpty) {
    final list = rawList
        .map((cat) => Category.fromJson(cat as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  // 4. Si la base de datos devuelve lista vacía por RLS o no responde,
  // proveer las categorías oficiales de UCSS para no bloquear al usuario
  return _defaultUcssCategories;
});

final List<Category> _defaultUcssCategories = [
  Category(
    id: 'b0000000-0000-0000-0000-000000000001',
    name: 'Libros y Fotocopias',
    description: 'Libros académicos, separatas y material de lectura',
  ),
  Category(
    id: 'b0000000-0000-0000-0000-000000000002',
    name: 'Tecnología y Laptops',
    description: 'Calculadoras científicas, laptops, periféricos y cables',
  ),
  Category(
    id: 'b0000000-0000-0000-0000-000000000003',
    name: 'Útiles y Maquetas',
    description: 'Materiales de arquitectura, medicina, ingeniería y dibujo',
  ),
  Category(
    id: 'b0000000-0000-0000-0000-000000000004',
    name: 'Ropa y Uniformes',
    description:
        'Mandiles de laboratorio, uniformes de enfermería y polos UCSS',
  ),
  Category(
    id: 'b0000000-0000-0000-0000-000000000005',
    name: 'Snacks y Alimentos',
    description: 'Snacks, postres y bebidas para el campus',
  ),
  Category(
    id: 'b0000000-0000-0000-0000-000000000006',
    name: 'Otros Artículos',
    description: 'Mochilas, termos, estuches y más',
  ),
];

final deliverySpotsProvider = FutureProvider<List<DeliverySpot>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('delivery_spots')
        .select()
        .order('name');

    final list = (response as List)
        .map((spot) => DeliverySpot.fromJson(spot as Map<String, dynamic>))
        .toList();
    if (list.isNotEmpty) return list;
  } catch (e) {
    debugPrint('Nota delivery_spots Supabase: $e');
  }

  return [];
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();

  var query = Supabase.instance.client
      .from('products')
      .select(
        '*, product_images (*), seller:profiles!products_seller_id_fkey (*), category:categories (*)',
      )
      .eq('status', 'disponible')
      .gt('stock', 0);

  if (selectedCategory != null) {
    query = query.eq('category_id', selectedCategory);
  }

  final response = await query.order('created_at', ascending: false);
  var products = (response as List)
      .map((item) => Product.fromJson(item as Map<String, dynamic>))
      .toList();

  if (searchQuery.isNotEmpty) {
    products = products.where((p) {
      return p.title.toLowerCase().contains(searchQuery) ||
          p.description.toLowerCase().contains(searchQuery);
    }).toList();
  }

  return products;
});

class ProductCreationNotifier extends StateNotifier<AsyncValue<void>> {
  ProductCreationNotifier() : super(const AsyncValue.data(null));

  Future<void> createProduct({
    required String title,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    required List<XFile> imageFiles,
  }) async {
    state = const AsyncValue.loading();
    String? productId;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Debes iniciar sesión para publicar un producto');
      }

      // 1. Insertar producto en la tabla `products`
      final productResponse = await Supabase.instance.client
          .from('products')
          .insert({
            'seller_id': user.id,
            'category_id': categoryId,
            'title': title.trim(),
            'description': description.trim(),
            'price': price,
            'stock': stock,
            'status': 'disponible',
          })
          .select()
          .single();

      productId = productResponse['id'].toString();

      // 2. Subir imágenes a Storage y asociar en `product_images`
      for (int i = 0; i < imageFiles.length; i++) {
        final publicUrl = await StorageService.uploadProductImage(
          imageFiles[i],
        );
        await Supabase.instance.client.from('product_images').insert({
          'product_id': productId,
          'image_url': publicUrl,
          'display_order': i,
        });
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      // Compensación: si el producto ya se insertó pero falló la subida de
      // imágenes, elimínalo para no dejar publicaciones huérfanas o parciales.
      if (productId != null) {
        try {
          await Supabase.instance.client
              .from('product_images')
              .delete()
              .eq('product_id', productId);
          await Supabase.instance.client
              .from('products')
              .delete()
              .eq('id', productId);
        } catch (cleanupError) {
          debugPrint('No se pudo revertir el producto $productId: $cleanupError');
        }
      }
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final productCreationProvider =
    StateNotifierProvider<ProductCreationNotifier, AsyncValue<void>>((ref) {
      return ProductCreationNotifier();
    });
