# Marketing KBM App

Platform Penjualan & Pemasaran Internal KBM Group. Aplikasi ini dirancang untuk memudahkan tim marketing dalam mengelola penjualan, katalog produk, dan laporan harian.

## Fitur Utama

- **Katalog Produk Dinamis**: Menampilkan daftar produk dengan harga dan stok real-time (Support Dark Mode).
- **Dashboard Admin**: Manajemen produk (Tambah/Edit/Hapus) dan pengaturan global (Bonus, Target).
- **Link in Bio**: Fitur unik untuk setiap marketer membagikan link personal mereka.
- **Biometric Login**: Akses cepat dan aman menggunakan sidik jari atau Face ID.
- **Multi-Platform**: Mendukung Android dan Web (PWA Ready).

## Teknologi

- **Framework**: Flutter (Dart)
- **Backend Service**: Firebase (Firestore, Auth, Storage, Hosting)
- **State Management**: Provider
- **Storage**: Cloudflare R2 (untuk aset gambar hemat biaya)

## Cara Menjalankan

### Persiapan

1.  Pastikan Flutter SDK terinstall.
2.  Clone repository ini.
3.  Buat file `.env` di root folder (lihat `.env.example`).

### Menjalankan Aplikasi

```bash
# Install dependencies
flutter pub get

# Run (Debug)
flutter run

# Build Web Release
flutter build web --release

# Build APK Release
flutter build apk --release
```

## Struktur Project

- `lib/src/features`: Fitur-fitur utama (Auth, Catalog, Home, Profile).
- `lib/src/core`: Komponen inti (Services, Models, Theme, Utils).
- `assets/`: Gambar dan file statis.

## Kontak

Tim IT KBM Group
