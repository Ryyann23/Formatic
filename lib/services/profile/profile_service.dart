import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:formatic/models/auth/user_profile.dart';
import 'package:http/http.dart' as http;

import '../core/supabase_config.dart';

class ProfileService {
  final client = SupabaseConfig.client;
  static const String _avatarBucket = 'avatars';

  // CONSULTAR PERFIL
  Future<UserProfile?> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromJson(response);
  }

  // CRIAR PERFIL
  Future<void> createProfile(UserProfile profile) async {
    await client.from('profiles').insert(profile.toJson());
  }

  // ATUALIZAR PARCIALMENTE
  Future<void> patchProfile(String userId, Map<String, dynamic> updates) async {
    await client.from('profiles').update(updates).eq('id', userId);
  }

  // DELETAR PERFIL
  Future<void> deleteProfile(String userId) async {
    await client.from('profiles').delete().eq('id', userId);
  }

  Future<String?> uploadAvatarFile(File file, String userId) async {
    final fileExt = file.path.split('.').last;
    final path =
        'avatars/$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final baseUrl = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (baseUrl == null || anonKey == null) {
      throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY not configured');
    }

    final uri = Uri.parse('$baseUrl/storage/v1/object/$_avatarBucket/$path');
    final bytes = await file.readAsBytes();

    final res = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $anonKey',
        'apikey': anonKey,
        'Content-Type': 'application/octet-stream',
      },
      body: bytes,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return '$baseUrl/storage/v1/object/public/$_avatarBucket/$path';
    } else {
      throw Exception('Storage upload failed (${res.statusCode}): ${res.body}');
    }
  }
}
