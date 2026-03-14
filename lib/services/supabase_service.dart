import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/user_profile.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;

  static Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async => await _client.auth.signOut();

  static Future<List<Task>> fetchTasks() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Task.fromMap(e)).toList();
  }

  static Future<Task> createTask(Task task) async {
    // Pakai toInsertMap() — sertakan user_id
    final data = await _client
        .from('tasks')
        .insert(task.toInsertMap())
        .select()
        .single();
    return Task.fromMap(data);
  }

  static Future<Task> updateTask(Task task) async {
    // Pakai toUpdateMap() — tanpa user_id agar tidak konflik RLS
    final data = await _client
        .from('tasks')
        .update(task.toUpdateMap())
        .eq('id', task.id)
        .select()
        .single();
    return Task.fromMap(data);
  }

  static Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  static Future<UserProfile> fetchOrCreateProfile() async {
    final user = currentUser!;
    final userId = user.id;
    final email = user.email ?? '';
    final defaultUsername = email.contains('@') ? email.split('@').first : 'User';

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) return UserProfile.fromMap(data);

      final inserted = await _client
          .from('profiles')
          .upsert({'id': userId, 'username': defaultUsername, 'bio': '', 'avatar_url': null})
          .select()
          .single();
      return UserProfile.fromMap(inserted);
    } catch (_) {
      return UserProfile(
        id: userId,
        username: defaultUsername,
        bio: '',
        avatarUrl: null,
        createdAt: DateTime.now(),
      );
    }
  }

  static Future<void> updateProfile(UserProfile profile) async {
    await _client.from('profiles').upsert({
      'id': profile.id,
      'username': profile.username,
      'bio': profile.bio,
      'avatar_url': profile.avatarUrl,
    });
  }

  static Future<String?> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = '$userId/avatar.$extension';
    await _client.storage.from('avatars').uploadBinary(
      path, bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    final url = _client.storage.from('avatars').getPublicUrl(path);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }
}
