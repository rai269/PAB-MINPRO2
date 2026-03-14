# ToDo Pro — Mini Project 2

Aplikasi mobile **Todo List** berbasis Flutter dengan integrasi **Supabase** sebagai backend database dan autentikasi. Merupakan pengembangan dari Mini Project 1 dengan penambahan fitur CRUD ke Supabase, Login/Register, Edit Profil (foto, username, bio), serta Light/Dark Mode.

---

## Fitur Lengkap

- **Login & Register** menggunakan Supabase Auth
- **CRUD Tugas** (Create, Read, Update, Delete) tersimpan di Supabase
- **Filter tab otomatis**: Inbox (semua aktif), Hari Ini, Mendatang, Kalender, Arsip
- **Arsip** — tugas yang diarsipkan hanya muncul di tab Arsip
- **Prioritas tugas** (Rendah / Sedang / Tinggi)
- **Edit Profil** — ganti username, bio, dan foto profil (tersimpan di Supabase Storage)
- **Light Mode & Dark Mode** dengan toggle di halaman Profil
- **Snackbar notifikasi** setiap berhasil tambah, edit, atau hapus
- **Dialog konfirmasi** sebelum menghapus tugas
- **Validasi form** dengan pesan error yang jelas
- **Pull-to-refresh** untuk memperbarui data
- **Sinkronisasi real-time** via Provider — semua tab update otomatis tanpa fetch ulang

---

## Logika Filter Tab

| Kondisi Deadline | Inbox | Hari Ini | Mendatang | Kalender | Arsip |
|---|---|---|---|---|---|
| Hari ini (8 Mar) | ✅ | ✅ | ❌ | ✅ | ❌ |
| Besok ke atas (9 Mar+) | ✅ | ❌ | ✅ | ✅ | ❌ |
| Kemarin/lampau | ✅ | ❌ | ❌ | ✅ | ❌ |
| Diarsipkan | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Struktur Direktori

```
minpro2/
├── lib/
│   ├── main.dart                        # Entry point, AuthGate, MultiProvider
│   ├── models/
│   │   ├── task.dart                    # Model Task
│   │   └── user_profile.dart            # Model UserProfile
│   ├── services/
│   │   └── supabase_service.dart        # Semua operasi ke Supabase (tasks + profiles + storage)
│   ├── providers/
│   │   ├── theme_provider.dart          # State tema light/dark
│   │   ├── task_provider.dart           # Single source of truth semua data tugas
│   │   └── profile_provider.dart        # State profil user
│   ├── theme/
│   │   └── app_theme.dart               # ThemeData light & dark
│   ├── widgets/
│   │   └── task_card.dart               # Komponen kartu tugas
│   └── pages/
│       ├── auth/
│       │   ├── login_page.dart          # Halaman login
│       │   └── register_page.dart       # Halaman registrasi
│       ├── main_navigation.dart         # Bottom navigation utama
│       ├── inbox_page.dart              # Semua tugas aktif (tidak diarsipkan)
│       ├── today_page.dart              # Tugas deadline hari ini
│       ├── upcoming_page.dart           # Tugas deadline besok ke atas
│       ├── calendar_page.dart           # Kalender dengan penanda per tanggal
│       ├── archive_page.dart            # Hanya tugas yang diarsipkan
│       ├── task_form_page.dart          # Form tambah & edit tugas
│       ├── task_detail_page.dart        # Detail tugas
│       ├── profile_page.dart            # Halaman profil
│       └── edit_profile_page.dart       # Edit username, bio, foto profil
├── .env                                 # API key (JANGAN di-commit!)
├── .env.example                         # Template .env aman untuk di-commit
├── .gitignore
└── pubspec.yaml
```

---

## Prasyarat

- [Flutter SDK](https://docs.flutter.dev/get-started/install) versi 3.10 ke atas
- Android Studio / VS Code
- Git
- Akun [Supabase](https://supabase.com) (gratis)

```bash
flutter --version
flutter doctor
```

---

## Langkah 1 — Setup Project Flutter

```bash
flutter create minpro2
cd minpro2
```

Salin semua file source code ke dalam folder project, lalu:

```bash
flutter pub get
```

---

## Langkah 2 — Setup Supabase

### 2.1 Buat project baru
1. Buka [https://supabase.com](https://supabase.com) dan login
2. Klik **"New Project"**, isi nama, password database, pilih region
3. Tunggu hingga selesai (~2 menit)

### 2.2 Buat tabel `tasks`
Buka **SQL Editor** → **New Query**, paste dan jalankan:

```sql
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
```

### 2.3 Buat tabel `profiles`
Masih di SQL Editor, jalankan:

```sql
create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  username text default '',
  bio text default '',
  avatar_url text,
  created_at timestamptz default now()
);
```

### 2.4 Aktifkan Row Level Security (RLS)

```sql
-- RLS untuk tabel tasks
alter table public.tasks enable row level security;

create policy "Users can view own tasks"
  on public.tasks for select
  using (auth.uid() = user_id);

create policy "Users can insert own tasks"
  on public.tasks for insert
  with check (auth.uid() = user_id);

create policy "Users can update own tasks"
  on public.tasks for update
  using (auth.uid() = user_id);

create policy "Users can delete own tasks"
  on public.tasks for delete
  using (auth.uid() = user_id);

-- RLS untuk tabel profiles
alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);
```

### 2.5 Buat Storage Bucket untuk foto profil
1. Buka menu **Storage** di sidebar Supabase
2. Klik **"New bucket"**
3. Isi nama bucket: `avatars`
4. Centang **"Public bucket"** agar foto bisa ditampilkan
5. Klik **"Create bucket"**

Kemudian buat policy storage di SQL Editor:

```sql
create policy "Users can upload own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can update own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Anyone can view avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');
```

### 2.6 Ambil API Key
1. Buka **Project Settings** → **API**
2. Salin **Project URL** dan **anon public** key

---

## Langkah 3 — Konfigurasi API Key (Aman)

Isi file `.env` di root project:

```env
SUPABASE_URL=https://abcdefghij.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

> ⚠️ File `.env` sudah ada di `.gitignore`. **Jangan pernah commit file ini!**

Pastikan `pubspec.yaml` mendaftarkan `.env` sebagai asset:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

---

## Langkah 4 — Konfigurasi Android

### 4.1 Set minimum SDK
Buka `android/app/build.gradle.kts`, pastikan `minSdk` minimal **21**:

```kotlin
defaultConfig {
    minSdk = 21
    targetSdk = 35
}
```

### 4.2 Izin untuk image_picker
Buka `android/app/src/main/AndroidManifest.xml`, tambahkan di dalam tag `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<!-- Untuk Android < 13 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
```

---

## Langkah 5 — Jalankan Aplikasi

```bash
flutter devices
flutter run
flutter build apk --release
```

---

## Cara Menggunakan Aplikasi

1. **Register**: Tap "Daftar" → isi email dan password
2. **Login**: Masukkan email dan password
3. **Tambah Tugas**: Tap tombol **+** di Inbox → isi Judul, Deskripsi, Deadline, Prioritas
4. **Edit Tugas**: Tap ikon pensil pada kartu tugas
5. **Hapus Tugas**: Tap ikon sampah → konfirmasi
6. **Arsipkan**: Tap ikon arsip — tugas hilang dari Inbox, Hari Ini, Mendatang; hanya muncul di tab Arsip
7. **Edit Profil**: Halaman Profil → tap ikon pensil / "Edit Profil" → ubah foto, username, bio
8. **Ganti Tema**: Halaman Profil → toggle Light/Dark Mode
9. **Logout**: Halaman Profil → tap "Keluar"

---

## Langkah 6 — Git Push Aman (Tanpa API Key)

### 6.1 Inisialisasi Git
```bash
git init
```

### 6.2 Verifikasi `.gitignore` sudah benar
```bash
cat .gitignore | grep "^\.env"
# Harus ada output: .env
```

### 6.3 Cek bahwa `.env` tidak ikut staged
```bash
git status
# File .env TIDAK boleh muncul di sini
```

Jika `.env` muncul, paksa hapus dari tracking:
```bash
git rm --cached .env
```

### 6.4 Commit dan push
```bash
git add .
git status          # verifikasi sekali lagi, .env tidak ada
git commit -m "feat: mini project 2 - todo app with supabase + edit profile"
git remote add origin https://github.com/username/minpro2.git
git push -u origin main
```

### 6.5 Verifikasi di GitHub
Buka repo di browser dan pastikan:
- `.env` **tidak ada**
- `.env.example` **ada** (berisi template kosong)
- Folder `lib/` dan `pubspec.yaml` **ada**

### Jika API Key Terlanjur Ter-push (Darurat)

```bash
# 1. Segera regenerate key di Supabase → Project Settings → API → Regenerate

# 2. Hapus dari history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all

# 3. Force push
git push origin --force --all

# 4. Update .env lokal dengan key baru
```

---

## Troubleshooting

**`flutter pub get` gagal**
```bash
flutter clean && flutter pub get
```

**Error `.env` tidak ditemukan**
Pastikan file `.env` ada di root project (sejajar dengan `pubspec.yaml`) dan sudah didaftarkan sebagai asset.

**Login gagal / email confirmation**
Di Supabase Dashboard → Authentication → Providers → Email → nonaktifkan "Confirm email" untuk testing.

**Upload foto gagal**
Pastikan bucket `avatars` sudah dibuat sebagai **public** dan policy storage sudah dijalankan.

**Tabel tidak ditemukan**
Jalankan ulang semua SQL di Langkah 2.2–2.4.

**Build Android gagal**
Pastikan `minSdk = 21` sudah diset di `build.gradle.kts`.

---

## Perbaikan & Fitur Baru (Update)

### Fix: Gagal Memperbarui Profil

Error ini disebabkan RLS policy Supabase yang terlalu ketat. Jalankan SQL berikut di SQL Editor Supabase untuk memperbaikinya:

```sql
-- Hapus policy lama jika ada
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;

-- Buat ulang dengan benar
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Pastikan upsert juga bisa
create policy "Users can upsert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);
```

Jika masih error, coba nonaktifkan RLS sementara untuk testing:
```sql
alter table public.profiles disable row level security;
```
Lalu aktifkan lagi setelah berhasil.

---

### Fitur: Tema Mengikuti Sistem

Di halaman **Profil**, tersedia 3 pilihan tema:
- **Ikuti Sistem** (default) — otomatis light/dark sesuai pengaturan OS
- **Light Mode** — selalu terang
- **Dark Mode** — selalu gelap

Pilihan tema tersimpan di `SharedPreferences` sehingga tetap ada setelah app ditutup.

---

### Fitur: Notifikasi Deadline (H-3, H-2, H-1)

Aplikasi secara otomatis menjadwalkan notifikasi lokal untuk setiap tugas aktif:

| Notifikasi | Waktu Kirim |
|---|---|
| H-3 | 3 hari sebelum deadline pukul 09.00 |
| H-2 | 2 hari sebelum deadline pukul 09.00 |
| H-1 | 1 hari sebelum deadline pukul 09.00 |

Notifikasi dibatalkan otomatis jika tugas dihapus, diselesaikan, atau diarsipkan.

#### Setup Android untuk Notifikasi

Pastikan `android/app/src/main/AndroidManifest.xml` sudah berisi permission berikut (sudah disertakan):
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

#### Catatan: Google Calendar Integration

Integrasi langsung dengan Google Calendar memerlukan OAuth2 + Google Calendar API key yang bersifat sensitif dan prosesnya panjang (verifikasi Google, OAuth consent screen, dll). Sebagai pengganti yang lebih ringan dan tidak memerlukan izin tambahan, aplikasi ini menggunakan **notifikasi lokal** yang sudah mencakup kebutuhan pengingat deadline.

