import 'package:formatic/models/flashcards/flashcard.dart';

import '../core/supabase_config.dart';

class FlashcardService {
  final client = SupabaseConfig.client;

  Future<List<Flashcard>> getUserFlashcards(String userId) async {
    final response = await client
        .from('flashcards')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Flashcard.fromJson(e)).toList();
  }

  Future<void> createFlashcard({
    required String userId,
    required String question,
    required String answer,
  }) async {
    await client.from('flashcards').insert({
      'user_id': userId,
      'question': question,
      'answer': answer,
    });
  }

  Future<void> updateFlashcard(Flashcard flashcard) async {
    await client
        .from('flashcards')
        .update(flashcard.toJson())
        .eq('id', flashcard.id);
  }

  Future<void> deleteFlashcard(String flashcardId) async {
    await client.from('flashcards').delete().eq('id', flashcardId);
  }
}
