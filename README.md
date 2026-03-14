# ToDo Pro — Mini Project 2

Aplikasi mobile **Todo List** berbasis Flutter dengan integrasi **Supabase** sebagai backend dan autentikasi. Dikembangkan dari Mini Project 1 dengan penambahan fitur full CRUD ke cloud, autentikasi user, manajemen profil, notifikasi deadline, dan tampilan yang dapat dikustomisasi.

---

## Fitur Utama

- **Autentikasi** — Register dan Login menggunakan Supabase Auth
- **CRUD Tugas** — Create, Read, Update, Delete tersimpan di Supabase
- **Prioritas Tugas** — Rendah / Sedang / Tinggi
- **Filter Tugas Otomatis** — Inbox, Hari Ini, Mendatang, Kalender, Arsip
- **Arsip Tugas** — Tugas diarsipkan tanpa dihapus permanen
- **Notifikasi Deadline** — Pengingat otomatis H-3, H-2, H-1 sebelum deadline
- **Edit Profil** — Ganti username, bio, dan foto profil (Supabase Storage)
- **Tema Dinamis** — Light Mode, Dark Mode, atau Ikuti Sistem
- **Validasi Form** — Pesan error spesifik per field
- **Dialog Konfirmasi** — Sebelum menghapus tugas
- **Snackbar Notifikasi** — Setiap berhasil tambah, edit, atau hapus
- **Pull-to-Refresh** — Perbarui data dengan tarik ke bawah
- **Badge Notifikasi** — Indikator merah jumlah tugas hari ini di navigasi

---

## Navigasi Aplikasi

Aplikasi menggunakan **4 tab** di bottom navigation bar:

| Tab | Isi |
|---|---|
| **Inbox** | Semua tugas aktif yang belum diarsipkan |
| **Kalender** | Tampilan kalender dengan penanda deadline per tanggal |
| **Lainnya** | Bottom sheet berisi Hari Ini, Mendatang, dan Arsip |
| **Profil** | Data user, pengaturan tema, dan logout |

Tab **Lainnya** membuka draggable bottom sheet yang bisa digeser ke atas/bawah atau ditutup dengan tap di luar area. Di dalamnya terdapat:
- ☀️ **Hari Ini** — Tugas dengan deadline hari ini (dengan badge merah jika ada)
- 🚀 **Mendatang** — Tugas deadline besok ke atas
- 📦 **Arsip** — Tugas yang telah diarsipkan

---

## Logika Filter Tugas

| Status Tugas | Inbox | Hari Ini | Mendatang | Kalender | Arsip |
|---|---|---|---|---|---|
| Deadline hari ini, aktif | ✅ | ✅ | ❌ | ✅ | ❌ |
| Deadline besok ke atas, aktif | ✅ | ❌ | ✅ | ✅ | ❌ |
| Deadline lampau, aktif | ✅ | ❌ | ❌ | ✅ | ❌ |
| Diarsipkan | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Struktur Direktori

```
minpro2/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── task.dart
│   │   └── user_profile.dart
│   ├── services/
│   │   ├── supabase_service.dart
│   │   └── notification_service.dart
│   ├── providers/
│   │   ├── task_provider.dart
│   │   ├── profile_provider.dart
│   │   └── theme_provider.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   └── ui_helpers.dart
│   ├── widgets/
│   │   └── task_card.dart
│   └── pages/
│       ├── auth/
│       │   ├── login_page.dart
│       │   └── register_page.dart
│       ├── main_navigation.dart
│       ├── inbox_page.dart
│       ├── today_page.dart
│       ├── upcoming_page.dart
│       ├── calendar_page.dart
│       ├── archive_page.dart
│       ├── task_form_page.dart
│       ├── task_detail_page.dart
│       ├── profile_page.dart
│       └── edit_profile_page.dart
├── .env                  # API key — JANGAN di-commit
├── .env.example          # Template aman untuk di-commit
├── .gitignore
└── pubspec.yaml
```

---

## Prasyarat

- [Flutter SDK](https://docs.flutter.dev/get-started/install) versi 3.10 ke atas
- Android Studio / VS Code
- Akun [Supabase](https://supabase.com) (gratis)

---

## Langkah 1 — Clone & Install Dependencies

```bash
git clone https://github.com/username/minpro2.git
cd minpro2
flutter pub get
```

---

## Langkah 2 — Setup Supabase

### 2.1 Buat project baru
1. Buka [https://supabase.com](https://supabase.com) dan login
2. Klik **New Project**, isi nama dan password database
3. Tunggu hingga selesai

### 2.2 Jalankan SQL berikut di SQL Editor

```sql
-- Tabel tasks
create table public.tasks (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  description text default '',
  priority text default 'medium' check (priority in ('low', 'medium', 'high')),
  deadline timestamptz not null,
  completed boolean default false,
  archived boolean default false,
  created_at timestamptz default now()
);

-- Tabel profiles
create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  username text default '',
  bio text default '',
  avatar_url text,
  created_at timestamptz default now()
);

-- RLS tasks
alter table public.tasks enable row level security;

create policy "Users can view own tasks" on public.tasks
  for select using (auth.uid() = user_id);

create policy "Users can insert own tasks" on public.tasks
  for insert with check (auth.uid() = user_id);

create policy "Users can update own tasks" on public.tasks
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users can delete own tasks" on public.tasks
  for delete using (auth.uid() = user_id);

-- RLS profiles
alter table public.profiles enable row level security;

create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);

create policy "Users can insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
```

### 2.3 Buat Storage Bucket
1. Buka menu **Storage** di sidebar Supabase
2. Klik **New bucket**, nama: `avatars`, centang **Public bucket**
3. Klik **Create bucket**
4. Jalankan SQL berikut:

```sql
create policy "Users can upload own avatar" on storage.objects
  for insert with check (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can update own avatar" on storage.objects
  for update using (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Anyone can view avatars" on storage.objects
  for select using (bucket_id = 'avatars');
```

### 2.4 Ambil API Key
1. Buka **Project Settings** → **API**
2. Salin **Project URL** dan **anon public key**

---

## Langkah 3 — Konfigurasi Environment

Buat file `.env` di root project:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

> File `.env` sudah ada di `.gitignore` dan tidak akan ter-upload ke GitHub.

---

## Langkah 4 — Konfigurasi Android

Buka `android/app/build.gradle.kts`, pastikan:

```kotlin
defaultConfig {
    minSdk = 21
    targetSdk = 35
}

compileOptions {
    isCoreLibraryDesugaringEnabled = true
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

---

## Langkah 5 — Jalankan Aplikasi

```bash
flutter run
```

Build APK release:

```bash
flutter build apk --release --split-per-abi
```

File APK tersedia di `build/app/outputs/flutter-apk/`.

---

## Cara Menggunakan Aplikasi

1. **Register** — Tap "Daftar" → isi email dan password
2. **Login** — Masukkan email dan password
3. **Tambah Tugas** — Tap tombol **+ Tambah** di Inbox → isi form → Simpan
4. **Lihat Detail** — Tap kartu tugas
5. **Edit Tugas** — Tap ikon pensil pada kartu tugas
6. **Selesaikan Tugas** — Tap lingkaran di kiri kartu
7. **Arsipkan Tugas** — Tap ikon arsip pada kartu
8. **Hapus Tugas** — Tap ikon sampah → konfirmasi dialog
9. **Hari Ini / Mendatang / Arsip** — Tap tab **Lainnya** di footer
10. **Edit Profil** — Halaman Profil → tap Edit Profil → ubah foto, username, bio
11. **Ganti Tema** — Halaman Profil → pilih Light / Dark / Ikuti Sistem
12. **Logout** — Halaman Profil → tap Keluar

---

## Troubleshooting

**`flutter pub get` gagal**
```bash
flutter clean && flutter pub get
```

**Login gagal / perlu konfirmasi email**

Supabase Dashboard → Authentication → Providers → Email → nonaktifkan **Confirm email**.

**Upload foto gagal**

Pastikan bucket `avatars` sudah dibuat sebagai **public** dan policy storage sudah dijalankan.

**Build Android gagal**

Pastikan `minSdk = 21` dan `coreLibraryDesugaring` sudah ditambahkan di `build.gradle.kts`.
