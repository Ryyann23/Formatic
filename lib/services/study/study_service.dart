import 'package:formatic/models/study/study_metrics.dart';
import 'package:formatic/models/study/study_session.dart';

import '../core/supabase_config.dart';

class StudyService {
  final client = SupabaseConfig.client;

  Future<StudySession> startSession(StudySession session) async {
    final response = await client
        .from('study_sessions')
        .insert(session.toJson())
        .select()
        .single();

    return StudySession.fromJson(response);
  }

  Future<StudySession> completeSession(String sessionId) async {
    final response = await client
        .from('study_sessions')
        .update({'completed': true})
        .eq('id', sessionId)
        .select()
        .single();

    return StudySession.fromJson(response);
  }

  Future<StudyMetrics?> getTodayMetrics() async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await client
        .from('study_metrics')
        .select()
        .eq('date', today)
        .maybeSingle();

    return response != null ? StudyMetrics.fromJson(response) : null;
  }
}
