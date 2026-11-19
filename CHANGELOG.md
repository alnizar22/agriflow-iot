# Changelog

Semua perubahan dan pembaruan pada aplikasi **IRIGASI BAWANG (Allimation / AGRIFLOW)** didokumentasikan di berkas ini.

Proyek ini dikembangkan oleh **EVA YUNIZAR SUGIARTO** (NIM: **STI202202907**) - Program Studi Teknik Informatika, **STMIK Widya Utama, Purwokerto** (2026).

---

## [1.0.1] - 2026-11-20 (Revisi Pra-Seminar Hasil)

### 🚀 Ditambahkan (Added)
- **Deteksi Status Hardware Prototype Real-Time**:
  - Banner peringatan informatif bernuansa *amber* pada halaman Beranda saat aplikasi terhubung ke broker MQTT namun prototype ESP32 belum dinyalakan (*"Prototype Belum Dinyalakan - Silakan nyalakan alat prototype ESP32 untuk menerima data telemetri"*).
  - Tampilan status placeholder bersih (`-- %`, `--°C`, `--%`, `--`) pada *Moisture Gauge* dan 3 *Mini Status Cards* ketika alat prototype belum aktif.
  - Status badge dinamis `"MENUNGGU ALAT"` pada Circular Gauge dan subteks `"Menunggu Alat"` pada kartu sensor.
  - Subheader status pada halaman Kontrol yang menginformasikan status siaga hardware (*"MENUNGGU HARDWARE - Silakan nyalakan daya prototype ESP32"*).
  - Flag spesifik `hasSoilData` pada model `SensorData` untuk membedakan penerimaan telemetri sensor tanah riil dari paket echo kendali manual.

### 🛡️ Diperbaiki (Fixed)
- **Eliminasi Data Dummy Saat Alat Mati**:
  - Menghapus nilai *hardcoded initial* (kelembapan $65\%$, suhu $28.5^\circ\text{C}$, udara $72\%$) saat aplikasi pertama kali dibuka.
  - Menghapus penambahan titik data dummy ke dalam daftar riwayat (`history`) pada *constructor* `IrrigationProvider`, sehingga grafik kurva tren telemetri tetap bersih hingga data riil pertama diterima.
  - Mengunci pemicu dialog pop-up peringatan kritis ($< 60\%$) agar tidak muncul sebagai *false alarm* ketika prototype ESP32 belum aktif atau belum mengirim data kelembapan tanah.
- **Pembersihan Notifikasi & SnackBar**:
  - Menghapus penyebutan path internal broker dan nama topik (`skripsi/nizar/manual` & `HiveMQ Cloud`) dari seluruh pesan konfirmasi SnackBar.
  - Menyederhanakan notifikasi kendali pompa menjadi:
    - *"Perintah 'SIRAM' berhasil terpublish ke prototype!"* (saat mengaktifkan pompa).
    - *"Perintah matikan pompa berhasil terpublish!"* (saat mematikan pompa).
    - *"Gagal mengirim perintah: Broker sedang offline..."* (saat koneksi terputus).
    - *"Contoh data telemetri berhasil terpublish ke prototype!"* (pada menu uji pengaturan broker).
- **Perbaikan Kode & Stabilitas (Bug Fixes)**:
  - Memperbaiki *missing import* `MqttConnectionState` pada `lib/screens/kontrol_screen.dart`.
  - Menghapus variabel lokal yang tidak digunakan (`recognizedTopic`) pada parser `lib/services/mqtt_service.dart`.
  - Memperbaiki potensi *RenderFlex horizontal overflow* pada card status kosong di `lib/screens/riwayat_screen.dart` dengan container kolom yang adaptif terhadap seluruh ukuran layar perangkat.

---

## [1.0.0] - 2026-10-13 (Rilis Awal Skripsi Bab 4)

### 🌟 Fitur Utama
- Integrasi IoT mikrokontroler ESP32 dengan protokol MQTT aman (TLS/SSL Port 8883) via broker HiveMQ Cloud Serverless.
- Antarmuka visual bertema *Light Agrotech* sesuai rancangan Mockup Figma Bab 4 Skripsi.
- Tab Beranda (Dashboard) dengan *Circular Percent Indicator*, mini status suhu DHT11, kelembapan udara, dan status pompa.
- Tab Kontrol dengan *Segmented Switch* mode [Otomatis | Manual], tombol kendali pompa melingkar besar, dan proteksi kejenuhan tanah ($> 80\%$).
- Tab Riwayat dengan grafik fluktuasi real-time `fl_chart` dilengkapi garis batas kritis Min $60\%$ dan Max $80\%$.
- Pop-Up dialog Informasi Pengembang akademik lengkap (Nama, NIM, Kampus STMIK Widya Utama, Logo Kampus, dan Judul Skripsi).
- Mode Simulasi Real-Time terintegrasi untuk demonstrasi alur data tanpa perangkat fisik.
- Icon aplikasi resmi **AGRIFLOW** untuk perangkat Android.
