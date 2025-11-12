import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

class AuthService {
  final SupabaseClient client = SupabaseConfig.client;

  Future<AuthResponse> signUp(
    String email,
    String password,
    String username, {
    String? phone,
    String? avatarUrl,
  }) async {
    // O perfil é criado automaticamente pelo trigger do banco
    // Passamos o username nos metadados para o trigger usar
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
    );

    return response;
  }

  Future<void> deleteUserAccount() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    await client.rpc('delete_user_complete', params: {'user_id': userId});
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async => await client.auth.signOut();

  User? get currentUser => client.auth.currentUser;
}
