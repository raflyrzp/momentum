# Momentum

**Momentum** adalah aplikasi *habit tracker* mobile berbasis **Flutter** dengan sistem gamifikasi RPG yang elegan dan *dark-mode first*. Dirancang *offline-first* menggunakan SQLite (Drift), Momentum menggabungkan psikologi pembentukan kebiasaan (**66-Day Habit Mastery** & aturan **Never Miss Twice**) dengan umpan balik sensorik (*long-press to charge*, *haptic feedback*, *particle burst*) serta dukungan **Home-Screen Widget interaktif Android (Jetpack Glance)** dan **pengingat lokal**.

---

## Daftar Isi

- [Fitur Utama & Mekanika Gamifikasi](#fitur-utama--mekanika-gamifikasi)
- [Tech Stack](#tech-stack)
- [Sistem Desain](#sistem-desain)
- [Arsitektur & Struktur Proyek](#arsitektur--struktur-proyek)
- [Skema Database](#skema-database)
- [Panduan Setup dari 0](#panduan-setup-dari-0)
- [Code Generation (Drift & Riverpod)](#code-generation-drift--riverpod)
- [Pengujian & Analisis Kode](#pengujian--analisis-kode)
- [Build Rilis (Production)](#build-rilis-production)
- [Mode Debug & Simulasi Waktu](#mode-debug--simulasi-waktu)
- [Troubleshooting](#troubleshooting)

---

## Fitur Utama & Mekanika Gamifikasi

### 1. 4 Pilar Atribut RPG
Setiap kebiasaan terikat pada satu dari empat pilar atribut yang memiliki XP dan level masing-masing, sekaligus berkontribusi ke level global:

| Pilar | Fokus | Warna |
| :--- | :--- | :--- |
| **Vitality** | Fisik & kesehatan | `#FB7185` (Rose) |
| **Intellect** | Kognitif & belajar | `#818CF8` (Indigo) |
| **Discipline** | Eksekusi & produktivitas | `#FBBF24` (Amber) |
| **Mindfulness** | Mental & ketenangan | `#2DD4BF` (Teal) |

### 2. Sistem XP & Leveling
- **Base XP:** `10 XP` setiap kali menyelesaikan kebiasaan.
- **Bonus Streak:** `+10%` untuk setiap kelipatan 7 periode streak, maksimal `+50%` (`15 XP` per penyelesaian pada streak 35+).
- **Kurva Level Kuadratik:** Total XP untuk mencapai level $L$ dihitung dengan rumus:
  $$\text{XP}(L) = 50 \times (L - 1) \times L$$
  *(Level 1 = 0 XP, Level 2 = 100 XP, Level 3 = 300 XP, Level 4 = 600 XP, dst.)*

### 3. Momentum Shield (*Never Miss Twice*)
- Melindungi streak saat satu periode terjadwal terlewat secara tidak sengaja, selama streak sedang berjalan, periode sebelumnya tidak terlewat, dan shield dalam kondisi terisi penuh.
- Melewatkan dua periode berturut-turut tetap memutus streak.
- **Isi ulang otomatis:** Shield kembali penuh setelah **7 kali penyelesaian**.

### 4. 66-Day Habit Mastery
Mengacu pada riset pembentukan kebiasaan (Lally et al.), progres penguasaan dihitung berdasarkan **total hari kebiasaan diselesaikan** (tidak reset saat satu hari terlewat):
- **Fragile (Hari 1–21):** Kebiasaan masih rapuh, fokus menjaga ritme.
- **Building (Hari 22–65):** Fondasi kebiasaan mulai terbentuk.
- **Forged (Hari 66+):** Kebiasaan telah menjadi otomatis.

### 5. Critical Focus Drop (Variable Reward)
Setiap penyelesaian memiliki peluang **12%** memicu hadiah acak:
- **Bonus XP (50% dari drop):** Tambahan `+5` hingga `+25 XP`.
- **Focus Insight (30% dari drop):** Kutipan refleksi singkat tentang konsistensi.
- **Badge Fragment (20% dari drop):** Kumpulkan **4 fragmen** untuk membentuk **1 Badge Langka**.

### 6. Interaksi *Long-Press to Charge*
- Menyelesaikan kebiasaan dilakukan dengan menahan tombol selama **800 ms** hingga cincin terisi penuh, memicu *haptic feedback* dan efek *particle burst*.
- Mencegah ketukan tidak sengaja dan menyediakan tombol **Urungkan (Undo)** pada snackbar selama 4 detik.

### 7. Frekuensi Fleksibel & Pengelolaan Kebiasaan
- **Setiap hari** (`daily`)
- **Hari tertentu** (`weekdays`, disimpan dalam 7-bit mask Senin–Minggu)
- **Target mingguan** (`timesPerWeek`, mis. 3× seminggu; streak dihitung per minggu)
- **Arsip vs Hapus Permanen:** Mengarsipkan kebiasaan menyembunyikannya dari daftar aktif namun **tetap mempertahankan XP**. Menghapus permanen menghapus seluruh riwayat dan XP terkait.

### 8. Statistik & Visualisasi
- **Radar Chart Keseimbangan Pilar** (`fl_chart`) untuk memantau distribusi 4 atribut.
- **Contribution Heatmap 1 Tahun** untuk melihat konsistensi harian selama setahun penuh.
- **Detail Kebiasaan:** Progres *Mastery Bar*, status *Momentum Shield*, streak saat ini/terbaik, dan heatmap per kebiasaan.

### 9. Pengingat Lokal & Android Home-Screen Widget
- **Notifikasi Lokal:** Pengingat per kebiasaan mengikuti zona waktu perangkat secara otomatis (`flutter_local_notifications` + `timezone` + `flutter_timezone`), mendukung jadwal harian maupun hari tertentu.
- **Widget Home-Screen Android:** Dibangun dengan **Jetpack Glance (Compose)** dan `home_widget`. Pengguna dapat mencentang kebiasaan langsung dari layar utama tanpa membuka aplikasi melalui callback latar (`momentum://complete?id=<habitId>`) dengan database yang dibagikan antar-isolate (`shareAcrossIsolates: true`).

---

## Tech Stack

| Kategori | Paket / Teknologi | Kegunaan |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart `^3.13.3`) | UI lintas platform (Android & iOS) |
| **State Management** | `flutter_riverpod` (`^3.5.0`), `riverpod_annotation` (`^4.0.8`) | Reactive state & dependency injection |
| **Database Lokal** | `drift` (`^2.35.4`), `drift_flutter` (`^0.3.1`), `path_provider` | SQLite type-safe & reactive streams |
| **Visualisasi** | `fl_chart` (`^1.3.1`) | Radar chart keseimbangan pilar |
| **Animasi** | `flutter_animate` (`^4.5.2`) | Transisi kartu & animasi deklaratif |
| **Home Widget** | `home_widget` (`^0.10.0`), Jetpack Glance (Kotlin/Compose) | Widget layar utama Android interaktif |
| **Notifikasi** | `flutter_local_notifications` (`^23.0.2`), `timezone`, `flutter_timezone` | Pengingat lokal terjadwal sesuai zona waktu |
| **Codegen & Lint** | `build_runner`, `drift_dev`, `riverpod_generator`, `flutter_lints` | Generasi kode database/provider & static analysis |

---

## Sistem Desain

Aplikasi menggunakan tema **Dark-Mode First** (Material 3):

- **Palet Warna (`lib/core/theme/app_colors.dart`):**
  - Background (Deep Obsidian): `#0F1115`
  - Surface (Slate Charcoal): `#181B22`
  - Surface High: `#20242D`
  - Primary (Electric Indigo): `#6366F1`
  - Reward (Emerald Mint): `#10B981`
  - Streak (Amber Flame): `#F59E0B`
  - Shield (Cyan Frost): `#06B6D4`
  - Text (Snow / Slate): `#F8FAFC` / `#94A3B8`
  - Danger: `#F87171`
- **Tipografi (`assets/fonts/`):**
  - `PlusJakartaSans` (Regular, Medium, SemiBold, Bold) untuk teks UI.
  - `JetBrainsMono` (Regular, Medium, Bold) dengan `FontFeature.tabularFigures()` untuk angka presisi (XP, level, streak, statistik).

---

## Arsitektur & Struktur Proyek

Proyek menerapkan pemisahan tanggung jawab berbasis layer (`core`, `domain`, `data`, `services`, `features`). Logika inti di `domain/` ditulis murni (pure Dart) tanpa dependensi database agar mudah diuji.

```text
mobile/
├── android/
│   └── app/
│       ├── build.gradle.kts                   # Config Gradle (compileSdk 37, Java 17, Compose, desugaring)
│       └── src/main/kotlin/dev/momentum/momentum/
│           ├── MainActivity.kt                # Entry point Android
│           ├── MomentumWidget.kt              # UI Widget Home-Screen (Jetpack Glance)
│           └── MomentumWidgetReceiver.kt      # Broadcast receiver widget
├── assets/
│   └── fonts/                                 # PlusJakartaSans & JetBrainsMono (.ttf)
├── ios/                                       # Konfigurasi proyek iOS (Runner)
├── lib/
│   ├── main.dart                              # Bootstrap app, init notifikasi & callback home widget
│   ├── app.dart                               # MomentumApp & HomeShell (Bottom Navigation + sync widget)
│   ├── core/
│   │   ├── day.dart                           # Utilitas tanggal lokal & konversi dayKey (yyyymmdd)
│   │   └── theme/
│   │       ├── app_colors.dart                # Token warna & border radius
│   │       └── app_theme.dart                 # Konfigurasi Material 3 ThemeData & monoStyle
│   ├── domain/                                # Pure business logic (tanpa dependensi DB/UI)
│   │   ├── drop_roller.dart                   # Sistem Critical Focus Drop & daftar insight
│   │   ├── frequency.dart                     # Model frekuensi (daily, weekdays bitmask, timesPerWeek)
│   │   ├── mastery.dart                       # Kalkulasi 66-Day Habit Mastery (Fragile/Building/Forged)
│   │   ├── pillar.dart                        # Enum 4 pilar RPG
│   │   ├── streak_calculator.dart             # Algoritma streak & Momentum Shield (Never Miss Twice)
│   │   └── xp_engine.dart                     # Rumus XP, bonus streak, & kurva level kuadratik
│   ├── data/                                  # Persistence, repository, & Riverpod providers
│   │   ├── db/
│   │   │   ├── database.dart                  # Definisi tabel Drift (Habits, Completions)
│   │   │   └── database.g.dart                # Generated file Drift
│   │   ├── dashboard.dart                     # Agregasi data mentah menjadi Dashboard & HabitView
│   │   ├── habit_repository.dart              # CRUD kebiasaan, transaksi penyelesaian, & undo
│   │   ├── providers.dart                     # Provider Riverpod & HabitActions
│   │   └── providers.g.dart                   # Generated file Riverpod
│   ├── services/
│   │   ├── home_widget_service.dart           # Sinkronisasi data & background callback home widget
│   │   └── notification_service.dart          # Penjadwalan & pembatalan notifikasi lokal
│   └── features/                              # Layer presentasi (berbasis fitur)
│       ├── today/
│       │   ├── today_screen.dart              # Layar utama "Hari Ini", header XP, & menu debug
│       │   ├── habit_card.dart                # Kartu kebiasaan + status streak & shield
│       │   ├── charge_button.dart             # Tombol long-press 800ms dengan cincin progres
│       │   ├── particle_burst.dart            # Efek partikel saat selesai
│       │   └── reward_sheet.dart              # Bottom sheet saat level up / Critical Focus Drop
│       ├── habit_form/
│       │   └── habit_form_sheet.dart          # Modal tambah & ubah kebiasaan
│       ├── habit_detail/
│       │   ├── habit_detail_screen.dart       # Detail kebiasaan, arsip, hapus, & riwayat
│       │   └── mastery_bar.dart               # Visualisasi progres 66-Day Mastery
│       └── stats/
│           ├── stats_screen.dart              # Layar Statistik global
│           ├── pillar_radar.dart              # Radar chart 4 pilar
│           └── contribution_heatmap.dart      # Heatmap aktivitas 1 tahun
├── test/                                      # Unit, repository, & widget tests
│   ├── data/habit_repository_test.dart
│   ├── domain/rewards_test.dart
│   ├── domain/streak_calculator_test.dart
│   └── widgets/charge_button_test.dart
├── analysis_options.yaml                      # Aturan Flutter lints
└── pubspec.yaml                               # Manifest paket, SDK, dan aset font
```

---

## Skema Database

Database lokal bernama `momentum` (SQLite via Drift, `schemaVersion = 1`) dengan `PRAGMA foreign_keys = ON` dan `shareAcrossIsolates: true`.

### Tabel `habits`
| Kolom | Tipe | Keterangan |
| :--- | :--- | :--- |
| `id` | `INTEGER` (PK, Auto) | ID unik kebiasaan |
| `name` | `TEXT` (1–60 char) | Nama kebiasaan |
| `pillar` | `TEXT` (Enum) | `vitality`, `intellect`, `discipline`, `mindfulness` |
| `frequency_type` | `TEXT` (Enum) | `daily`, `weekdays`, `timesPerWeek` |
| `weekdays_mask` | `INTEGER` (Default `0x7F`) | Bitmask hari (`bit 0 = Senin` s.d. `bit 6 = Minggu`) |
| `times_per_week` | `INTEGER` (Default `3`) | Target mingguan untuk tipe `timesPerWeek` |
| `reminder_minutes` | `INTEGER` (Nullable) | Menit sejak tengah malam (`null` = tanpa pengingat) |
| `created_at` | `DATETIME` | Waktu pembuatan |
| `archived_at` | `DATETIME` (Nullable) | Waktu arsip (`null` = aktif) |

### Tabel `completions`
| Kolom | Tipe | Keterangan |
| :--- | :--- | :--- |
| `id` | `INTEGER` (PK, Auto) | ID unik log penyelesaian |
| `habit_id` | `INTEGER` (FK → `habits.id`) | `ON DELETE CASCADE` |
| `day` | `INTEGER` | Tanggal lokal format `yyyymmdd` |
| `completed_at` | `DATETIME` | Timestamp penyelesaian |
| `xp` | `INTEGER` | XP dasar + bonus streak yang didapat |
| `bonus_xp` | `INTEGER` (Default `0`) | Bonus XP dari Critical Focus Drop |
| `drop_type` | `TEXT` (Enum) | `none`, `bonusXp`, `insight`, `badgeFragment` |

- **Unique Constraint:** `(habit_id, day)` — satu kebiasaan hanya dapat dicatat selesai satu kali per hari lokal.

---

## Panduan Setup dari 0

### 1. Prasyarat Lingkungan

Pastikan tools berikut sudah terpasang di mesin Anda:

- **Flutter SDK** dengan **Dart SDK `^3.13.3`** (cek dengan `flutter --version`).
- **Git**.
- **Untuk Android:**
  - **JDK 17** (wajib sesuai konfigurasi `JavaVersion.VERSION_17` di Gradle).
  - **Android Studio** + **Android SDK Platform API 37** (`compileSdk = 37` diwajibkan oleh `flutter_local_notifications` v23).
  - Emulator Android atau perangkat fisik dengan *USB Debugging* aktif.
- **Untuk iOS (khusus macOS):**
  - **Xcode** terbaru + Command Line Tools.
  - **CocoaPods** (`sudo gem install cocoapods`).

### 2. Clone Repository

```bash
git clone <url-repository-anda>
cd mobile
```

### 3. Verifikasi Instalasi Flutter

```bash
flutter doctor -v
```

Pastikan tidak ada error pada bagian **Flutter**, **Android toolchain** (termasuk lisensi Android: jalankan `flutter doctor --android-licenses` bila diminta), atau **Xcode** (jika target iOS).

### 4. Instal Dependensi

```bash
flutter pub get
```

Jika menjalankan di iOS, instal dependensi CocoaPods:

```bash
cd ios && pod install && cd ..
```

### 5. Pastikan File Generated Terbaru

File `*.g.dart` sudah disertakan di repository, namun sangat disarankan menjalankan code generator untuk memastikan sinkronisasi:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Jalankan Aplikasi

Periksa perangkat/emulator yang tersedia:

```bash
flutter devices
```

Jalankan aplikasi pada perangkat terpilih:

```bash
flutter run
```

Atau spesifik ke satu device ID:

```bash
flutter run -d <device_id>
```

### 7. Mencoba Home-Screen Widget (Android)
1. Setelah aplikasi terpasang di Android, buka **Menu Debug** (ikon kumbang di pojok kanan atas layar *Hari Ini* pada build debug) lalu pilih **Pasang widget**, atau
2. Tekan lama pada layar utama Android → **Widgets** → cari **Momentum** → seret ke home screen.

---

## Code Generation (Drift & Riverpod)

Setiap kali Anda mengubah skema tabel di `lib/data/db/database.dart` atau anotasi `@riverpod` di `lib/data/providers.dart`, jalankan salah satu perintah berikut:

```bash
# Build sekali jalan
dart run build_runner build --delete-conflicting-outputs

# Mode watch (otomatis rebuild saat file disimpan)
dart run build_runner watch --delete-conflicting-outputs
```

---

## Pengujian & Analisis Kode

### Menjalankan Semua Unit & Widget Test

```bash
flutter test
```

Cakupan pengujian saat ini:
- `test/domain/streak_calculator_test.dart` — Validasi streak harian, hari tertentu, mingguan, dan mekanisme *Momentum Shield*.
- `test/domain/rewards_test.dart` — Validasi rumus XP, level kuadratik, 66-Day Mastery, dan *Critical Focus Drop*.
- `test/data/habit_repository_test.dart` — Validasi operasi database Drift (CRUD, complete, undo, arsip, cascade delete).
- `test/widgets/charge_button_test.dart` — Validasi interaksi *long-press to charge* dan pembatalan ketukan singkat.

### Menjalankan Static Analysis

```bash
flutter analyze
```

---

## Build Rilis (Production)

> **Catatan:** Sebelum merilis ke Play Store / App Store, perbarui `applicationId` dan tambahkan konfigurasi *release signing* pada `android/app/build.gradle.kts` (saat ini masih menggunakan `signingConfigs.getByName("debug")`).

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (macOS)

```bash
flutter build ipa --release
```

---

## Mode Debug & Simulasi Waktu

Pada build debug (`kDebugMode`), tersedia ikon **Menu Debug** di pojok kanan atas layar **Hari Ini** untuk mempermudah pengujian tanpa menunggu pergantian hari:
- **Maju 1 hari / Mundur 1 hari / Kembali ke hari ini:** Menggeser `dayOffsetProvider` untuk menguji transisi streak, pengaktifan *Momentum Shield*, dan *Mastery*.
- **Tes notifikasi:** Meminta izin notifikasi dan mengirim notifikasi uji seketika.
- **Pasang widget:** Memicu dialog launcher Android untuk memasang widget *Hari Ini*.

---

## Troubleshooting

- **Gagal build Android terkait `compileSdk` / API 37:**
  Buka **Android Studio → Settings → Languages & Frameworks → Android SDK**, lalu instal **Android SDK Platform API 37** beserta Build-Tools terbaru.
- **Error versi Java saat menjalankan Gradle:**
  Proyek mensyaratkan **JDK 17**. Pastikan `JAVA_HOME` mengarah ke JDK 17 atau atur melalui `flutter config --jdk-dir="<path-ke-jdk-17>"`.
- **Error `*.g.dart` tidak sinkron atau simbol tidak ditemukan:**
  Jalankan `flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs`.
- **Notifikasi tidak muncul di Android 13+:**
  Pastikan izin `POST_NOTIFICATIONS` telah diberikan. Izin akan diminta secara otomatis saat pengguna pertama kali menyalakan pengingat pada form kebiasaan atau saat menekan **Tes notifikasi** di Menu Debug.
- **Widget Android tidak merespons ketukan:**
  Pastikan aplikasi tidak dibatasi oleh optimasi baterai agresif dari vendor OEM agar isolate latar dapat memproses URI `momentum://complete?id=<habitId>`.
