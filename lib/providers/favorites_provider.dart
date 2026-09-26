import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_provider.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  return FavoritesNotifier(userId);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this._userId) : super({}) {
    if (_userId != null) loadFavorites();
  }

  final String? _userId;

  Future<void> loadFavorites() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('favorites')
          .select('product_id')
          .eq('user_id', userId);

      final ids = (response as List)
          .map((row) => row['product_id'].toString())
          .toSet();
      state = ids;
    } catch (_) {}
  }

  Future<void> toggleFavorite(String productId) async {
    final userId = _userId;
    if (userId == null) return;

    final isFav = state.contains(productId);
    if (isFav) {
      state = {...state}..remove(productId);
      try {
        await Supabase.instance.client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId);
      } catch (_) {}
    } else {
      state = {...state, productId};
      try {
        await Supabase.instance.client.from('favorites').insert({
          'user_id': userId,
          'product_id': productId,
        });
      } catch (_) {}
    }
  }

  bool isFavorite(String productId) => state.contains(productId);
}
