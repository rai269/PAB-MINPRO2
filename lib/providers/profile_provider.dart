import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

class ProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  bool _isLoading = false;
  String? _dbError; // error DB tapi profile tetap ada (dari fallback)

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get dbError => _dbError;

  Future<void> loadProfile() async {
    if (_isLoading) return;

    _isLoading = true;
    _dbError = null;
    notifyListeners();

    try {
      // fetchOrCreateProfile selalu return non-null — tidak bisa gagal total
      _profile = await SupabaseService.fetchOrCreateProfile();
    } catch (e) {
      _dbError = e.toString();
      // Buat profil lokal minimal agar UI tidak stuck
      final user = SupabaseService.currentUser;
      if (user != null && _profile == null) {
        final email = user.email ?? '';
        final username =
            email.contains('@') ? email.split('@').first : 'User';
        _profile = UserProfile(
          id: user.id,
          username: username,
          bio: '',
          avatarUrl: null,
          createdAt: DateTime.now(),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateProfile({
    required String username,
    required String bio,
  }) async {
    // Jika masih null, buat dulu dari auth data
    if (_profile == null) {
      await loadProfile();
    }
    if (_profile == null) return 'Gagal memuat profil';

    final prevUsername = _profile!.username;
    final prevBio = _profile!.bio;

    _profile!.username = username;
    _profile!.bio = bio;
    notifyListeners();

    try {
      await SupabaseService.updateProfile(_profile!);
      _dbError = null;
      return null;
    } catch (e) {
      _profile!.username = prevUsername;
      _profile!.bio = prevBio;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> uploadAvatar(Uint8List bytes, String extension) async {
    if (_profile == null) {
      await loadProfile();
    }
    if (_profile == null) return 'Gagal memuat profil';

    final prevUrl = _profile!.avatarUrl;

    try {
      final url = await SupabaseService.uploadAvatar(
        userId: _profile!.id,
        bytes: bytes,
        extension: extension,
      );
      _profile!.avatarUrl = url;
      await SupabaseService.updateProfile(_profile!);
      notifyListeners();
      return null;
    } catch (e) {
      _profile!.avatarUrl = prevUrl;
      notifyListeners();
      return e.toString();
    }
  }

  void clearProfile() {
    _profile = null;
    _dbError = null;
    _isLoading = false;
    notifyListeners();
  }
}
