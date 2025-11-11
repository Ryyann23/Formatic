import 'package:formatic/models/assistant/ai_history.dart';

import '../core/supabase_config.dart';

class AiHistoryService {
  final client = SupabaseConfig.client;

  Future<List<AiHistory>> getUserHistory(String userId) async {
    final response = await client
        .from('ai_history')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => AiHistory.fromJson(e)).toList();
  }

  Future<void> addHistory(AiHistory history) async {
    await client.from('ai_history').insert(history.toJson());
  }
}
