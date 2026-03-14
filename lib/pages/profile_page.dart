import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/profile_provider.dart';
import '../services/supabase_service.dart';
import '../utils/ui_helpers.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;
    final user = SupabaseService.currentUser;
    final cs = Theme.of(context).colorScheme;

    // URL tanpa timestamp agar tidak flicker saat tema berubah
    // Timestamp hanya ditambah saat upload baru (di provider)
    final avatarUrl = profile?.avatarUrl != null
        ? profile!.avatarUrl!.split('?').first
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: profileProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: profileProvider.isLoading
                ? null
                : () => context.read<ProfileProvider>().loadProfile(),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(
                  context, smoothRoute(const EditProfilePage()));
              if (context.mounted) {
                context.read<ProfileProvider>().loadProfile();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ProfileProvider>().loadProfile(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: cs.primary.withValues(alpha: 0.1),
                // Pakai URL tanpa timestamp - stabil saat tema berubah
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, size: 52, color: cs.primary)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                profile?.username.isNotEmpty == true
                    ? profile!.username
                    : (user?.email?.split('@').first ?? 'User'),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                user?.email ?? '',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
            if (profile?.bio.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  profile!.bio,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                      context, smoothRoute(const EditProfilePage()));
                  if (context.mounted) {
                    context.read<ProfileProvider>().loadProfile();
                  }
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Profil'),
              ),
            ),
            const Divider(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'TAMPILAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _ThemeOption(
              icon: Icons.brightness_auto,
              label: 'Ikuti Sistem',
              subtitle: 'Otomatis sesuai pengaturan perangkat',
              selected: themeProvider.themeMode == ThemeMode.system,
              onTap: () => themeProvider.setTheme(ThemeMode.system),
            ),
            _ThemeOption(
              icon: Icons.light_mode,
              label: 'Light Mode',
              subtitle: 'Selalu tampilan terang',
              selected: themeProvider.themeMode == ThemeMode.light,
              onTap: () => themeProvider.setTheme(ThemeMode.light),
            ),
            _ThemeOption(
              icon: Icons.dark_mode,
              label: 'Dark Mode',
              subtitle: 'Selalu tampilan gelap',
              selected: themeProvider.themeMode == ThemeMode.dark,
              onTap: () => themeProvider.setTheme(ThemeMode.dark),
            ),

            const Divider(height: 32),
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('Keluar'),
                    content: const Text('Yakin ingin keluar dari akun?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red),
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) await SupabaseService.signOut();
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Keluar',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: Colors.red),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        hapticLight();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? cs.primary
                : Colors.grey.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? cs.primary : Colors.grey, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? cs.primary : null,
                      )),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: cs.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
