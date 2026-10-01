# 📱 Surat Izin Mahasiswa Politeknik IDN

Aplikasi resmi pengajuan dan penerbitan formulir permohonan izin tidak masuk kelas untuk mahasiswa Politeknik IDN Bogor.

---

## ✨ Fitur Utama

- **📝 Formulir Lengkap Sesuai Format Resmi**:
  - Biodata Mahasiswa (Nama, NIM, Jurusan/Prodi, No. Handphone)
  - Rentang Tanggal Izin & Pilihan Kategori Izin (Sakit di Asrama, Sakit Pulang ke Rumah, dsb.)
  - Alasan/Keterangan Izin terperinci
  - Nama Mentor / Pembina Asrama

- **✍️ Tanda Tangan Digital Langsung**:
  - Canvas tanda tangan interaktif terintegrasi langsung di aplikasi
  - Fitur bersihkan dan ulangi tanda tangan dengan mudah

- **📄 Ekspor PDF Standar Politeknik IDN**:
  - Pratinjau langsung sebelum dicetak/dikirim
  - Format resmi lengkap dengan kop surat dan logo Politeknik IDN
  - Cetak atau simpan sebagai dokumen PDF berkualitas tinggi

- **🔄 Deteksi & Pembaruan Aplikasi Otomatis (GitHub Releases)**:
  - Otomatis memeriksa versi terbaru saat aplikasi dibuka
  - Tombol manual di AppBar untuk mengecek pembaruan kapan saja
  - Menampilkan catatan rilis (changelog) dan tombol unduh langsung APK terbaru

---

## 🚀 Memulai (Pengembangan)

### Prasyarat:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi stable terbaru)
- Android SDK / Java JDK 17
- Git

### Menjalankan Aplikasi di Mode Debug:
```bash
# Unduh dependensi
flutter pub get

# Jalankan aplikasi
flutter run
```

### Menjalankan Pengujian:
```bash
flutter test
```

### Membuat Berkas APK Rilis:
```bash
flutter build apk --release
```
Berkas APK akan berada di `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📦 Alur Rilis Otomatis (CI/CD)

Proyek ini telah dikonfigurasi dengan GitHub Actions (`.github/workflows/release.yml`).
Untuk mempublikasikan rilis baru:
1. Buat tag Git baru dengan awalan `v` (misal: `v1.0.0`):
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. GitHub Actions akan secara otomatis menjalankan pengujian, mengompilasi APK rilis, dan mempublikasikannya ke **GitHub Releases**.
3. Aplikasi pengguna akan otomatis mendeteksi rilis baru ini saat terhubung ke internet.

---

## 📄 Lisensi
Hak Cipta © 2026 Mahasiswa Politeknik IDN Bogor.
