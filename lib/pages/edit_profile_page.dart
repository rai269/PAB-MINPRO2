import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  bool _isLoading = false;
  Uint8List? _pickedImageBytes;
  String? _pickedExtension;

  @override
  void initState() {
    super.initState();
    // Ambil langsung dari provider — dijamin non-null setelah loadProfile
    final profile = context.read<ProfileProvider>().profile;
    _usernameController = TextEditingController(text: profile?.username ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    setState(() {
      _pickedImageBytes = bytes;
      _pickedExtension = ext.isEmpty ? 'jpg' : ext;
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final provider = context.read<ProfileProvider>();

    try {
      // Upload avatar dulu jika ada foto baru
      if (_pickedImageBytes != null && _pickedExtension != null) {
        final err = await provider.uploadAvatar(
          _pickedImageBytes!,
          _pickedExtension!,
        );
        if (err != null) {
          _showSnack('Gagal upload foto: $err', isError: true);
          return;
        }
      }

      // Simpan username & bio
      final err = await provider.updateProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (err != null) {
        _showSnack('Gagal menyimpan: $err', isError: true);
        return;
      }

      _showSnack('Profil berhasil diperbarui');
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;
    final cs = Theme.of(context).colorScheme;

    // Jika masih loading pertama kali
    if (provider.isLoading && profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: cs.primary.withValues(alpha: 0.1),
                      backgroundImage: _pickedImageBytes != null
                          ? MemoryImage(_pickedImageBytes!) as ImageProvider
                          : (profile?.avatarUrl != null
                              ? NetworkImage(profile!.avatarUrl!.split('?').first)
                              : null),
                      child: (_pickedImageBytes == null &&
                              (profile?.avatarUrl == null))
                          ? Icon(Icons.person, size: 56, color: cs.primary)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap foto untuk mengubah',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),

              // Tampilkan warning jika DB bermasalah tapi masih bisa jalan
              if (provider.dbError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Koneksi database bermasalah. Perubahan mungkin tidak tersimpan.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Username wajib diisi';
                  }
                  if (v.trim().length < 3) {
                    return 'Username minimal 3 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.info_outline),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
