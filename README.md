# Kasku

Aplikasi pencatatan arus kas pribadi yang membantu mencatat pemasukan dan pengeluaran, melihat ringkasan keuangan, serta mengelola data secara lokal di perangkat.

## Fitur

- Catat, edit, dan hapus transaksi pemasukan maupun pengeluaran.
- Kelompokkan transaksi menggunakan kategori bawaan atau kategori buatan sendiri.
- Lihat saldo, ringkasan pemasukan dan pengeluaran bulanan, grafik pengeluaran per kategori, serta transaksi terbaru.
- Telusuri riwayat transaksi dan filter berdasarkan jenis transaksi dan bulan.
- Ekspor transaksi dan kategori ke file JSON, lalu bagikan atau simpan melalui fitur berbagi perangkat.
- Pulihkan data dari file JSON. Import akan mengganti data transaksi saat ini setelah dikonfirmasi.
- Gunakan tema terang atau gelap mengikuti pengaturan sistem.

## Privasi dan penyimpanan

Data transaksi disimpan secara lokal di perangkat. Kasku tidak memerlukan akun untuk mencatat transaksi. File backup dibuat saat pengguna memilih ekspor dan dapat dibagikan atau disimpan menggunakan aplikasi lain melalui fitur berbagi sistem operasi. Lokasi dan keamanan file backup setelah dibagikan bergantung pada layanan yang dipilih pengguna.

## Teknologi

- Flutter dan Dart
- Riverpod untuk state management
- Isar untuk penyimpanan lokal
- `fl_chart` untuk visualisasi pengeluaran

## Menjalankan dari source

Pastikan Flutter SDK yang mendukung batas Dart di `pubspec.yaml` sudah terpasang, lalu jalankan dari direktori proyek:

```sh
flutter pub get
flutter run
```

Untuk menjalankan pengujian:

```sh
flutter test
```

## Status platform

Proyek ini berisi konfigurasi platform Android. Dukungan dan proses rilis untuk platform lain belum dinyatakan di README ini.
