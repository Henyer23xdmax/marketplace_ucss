import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user ?? Supabase.instance.client.auth.currentUser;
});

final userProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      return Profile(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] as String? ?? 'Estudiante UCSS',
      );
    }
    return Profile.fromJson(data);
  } catch (e) {
    return Profile(
      id: user.id,
      email: user.email ?? '',
      fullName: user.userMetadata?['full_name'] as String? ?? 'Estudiante UCSS',
    );
  }
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController() : super(const AsyncValue.data(null));

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      if (!email.trim().toLowerCase().endsWith('@ucss.pe')) {
        throw Exception('Acceso denegado: Se requiere correo institucional @ucss.pe');
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Devuelve `true` si se creó una sesión (sin confirmación de correo),
  /// o `false` si Supabase exige confirmar el correo antes de iniciar sesión.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? career,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      if (!email.trim().toLowerCase().endsWith('@ucss.pe')) {
        throw Exception('Solo estudiantes UCSS con correo @ucss.pe pueden registrarse');
      }

      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          if (career != null && career.isNotEmpty) 'career': career.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        },
      );

      // Si el trigger de Supabase no actualiza carrera o teléfono, intentamos actualizar el perfil
      if (response.user != null && (career != null || phone != null)) {
        try {
          await Supabase.instance.client.from('profiles').update({
            if (career != null) 'career': career.trim(),
            if (phone != null) 'phone': phone.trim(),
          }).eq('id', response.user!.id);
        } catch (_) {}
      }

      state = const AsyncValue.data(null);
      return response.session != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    state = const AsyncValue.loading();
    try {
      if (!email.trim().toLowerCase().endsWith('@ucss.pe')) {
        throw Exception('Usa tu correo institucional @ucss.pe');
      }

      await Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController();
});
