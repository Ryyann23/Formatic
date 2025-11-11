import 'package:formatic/models/tasks/task.dart';

import '../core/supabase_config.dart';

class TaskService {
  final client = SupabaseConfig.client;

  Future<Task> createTask(Task task) async {
    final response = await client
        .from('tasks')
        .insert(task.toJson())
        .select()
        .single();

    return Task.fromJson(response);
  }

  Future<List<Task>> getTasks() async {
    final response = await client
        .from('tasks')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => Task.fromJson(e)).toList();
  }

  Future<Task> updateTask(Task task) async {
    final response = await client
        .from('tasks')
        .update(task.toJson())
        .eq('id', task.id)
        .select()
        .single();

    return Task.fromJson(response);
  }

  Future<void> deleteTask(String taskId) async {
    await client.from('tasks').delete().eq('id', taskId);
  }
}
