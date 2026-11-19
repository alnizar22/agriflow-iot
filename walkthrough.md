# Walkthrough - Dokumentasi Resmi Aplikasi Flutter "IRIGASI BAWANG" (Allimation)

Aplikasi **Irigasi Bawang** (Allimation) dikembangkan untuk memenuhi prasyarat kelulusan Sarjana Komputer (S.Kom) pada program studi Teknik Informatika di **STMIK Widya Utama, Purwokerto** oleh mahasiswa **EVA YUNIZAR SUGIARTO** (NIM: **STI202202907**).

Aplikasi ini telah direvisi dan disinkronkan **100% presisi** dengan dokumen Skripsi Bab 4, desain tema *Light Agrotech*, prototipe Figma, serta hardware IoT mikrokontroler **ESP32** melalui broker cloud terenkripsi **HiveMQ Cloud Serverless (TLS Port 8883)**.

---

## 📱 Arsitektur & Tampilan Visual Antarmuka (Bab 4 Skripsi)

### 1. App Bar & Pop-Up Dialog "Informasi Pengembang"
- **Pemicu (Trigger)**: Pojok kanan atas App Bar pada halaman Beranda dan Kontrol memiliki Circular Avatar hijau pekat (`#047857`) dengan siluet ikon User/Person putih di tengahnya.
- **Pop-Up Dialog Modal**: Saat avatar ditekan, dialog modal bertema *Light Agrotech* muncul menampilkan:
  - **Header Akademik**: Ikon topi toga kelulusan (`Icons.school_rounded`), teks *"Informasi Pengembang"*, dan penjelasan prasyarat kelulusan S.Kom.
  - **Identitas Skripsi**: Logo resmi kampus STMIK Widya Utama, Nama Mahasiswa (**EVA YUNIZAR SUGIARTO**), NIM (**STI202202907**), Institusi (**STMIK WIDYA UTAMA, PURWOKERTO**), Tahun (**2026**), dan Judul Skripsi lengkap.
  - **Aksi & Footer**: Tombol *"Tutup"* berwarna Deep Green dan tombol ikon gear di sudut untuk membuka halaman Konfigurasi Broker MQTT.

---

### 2. Tab 0: Beranda (Mockup 1)
- **Header**: Logo AGRIFLOW resmi + teks `"IRIGASI IOT Beranda"` + Avatar Pengembang.
- **Card Status Utama**: Menampilkan nama instalasi `"Irigasi Bawang Merah"` dan badge live status broker:
  - `🟢 Status: Online (HiveMQ Cloud)` saat terhubung.
  - `🟡 Status: Menghubungkan ke Broker...` saat proses handshake TLS.
  - `🔴 Status: Offline (Tap to Reconnect)` jika koneksi terputus (bisa ditekan untuk menghubungkan ulang instan).
- **Banner Deteksi Prototype**: Jika hardware ESP32 belum dinyalakan dan data belum masuk, banner informasi muncul mengarahkan pengguna untuk menyalakan prototype ESP32 tanpa menampilkan data dummy palsu.
- **Moisture Gauge Card**: Circular Percent Indicator kelembapan tanah (0–100%), badge rentang ideal `"OPTIMAL"`, serta banner verifikasi `"Rentang Ideal Bawang (60% - 75%) Terverifikasi"`. Jika prototype belum aktif, indikator menampilkan placeholder bersih (`--%`) dengan status badge `"MENUNGGU ALAT"`.
- **3 Mini Status Cards**:
  - **Suhu Udara**: Menampilkan nilai suhu DHT11 dalam °C (misal `31°C Normal` atau `--°C Menunggu Alat`).
  - **Kelembapan Udara**: Menampilkan nilai kelembapan relatif DHT11 dalam % (misal `63% Cukup` atau `--% Menunggu Alat`).
  - **Status Pompa**: Status pompa air (`ON` / `OFF` / `--`) beserta status operasional ESP32.
- **Bar Pembaruan Telemetri**: Menampilkan status sinkronisasi otomatis dan waktu pembaruan terakhir (*"Baru saja"* atau *"Belum Aktif"*).
- **Pengujian Mode Simulasi**: Tombol quick-toggle simulasi data untuk demonstrasi UI tanpa hardware.

---

### 3. Tab 1: Kontrol Pompa & Mode Operasi (Mockup 2)
- **Header & Subheader**: Logo AGRIFLOW + `"IRIGASI IOT Kontrol"` + status `"SISTEM SIAGA - Hardware pompa terhubung via IoT Gateway"` + indikator sinyal `"98% Stabil"`. Jika prototype belum aktif, subheader menginformasikan *"MENUNGGU HARDWARE - Silakan nyalakan daya prototype ESP32"*.
- **Mode Operasi Segmented Switch**:
  - `[🤖 Otomatis]`: Pompa menyala/mati secara otomatis sesuai aturan Skripsi (menyala jika `< 60%`, mati jika `>= 80%`).
  - `[🪛 Manual]`: Pengendalian manual langsung dari tombol aplikasi.
- **Tombol Utama Kendali Pompa (Big Circular Button)**:
  - **Kondisi Standby / Siaga**: Tombol hijau tua pekat (`#047857`) dengan teks *"Nyalakan Pompa Air - SIAP DIGUNAKAN"*.
  - **Kondisi Aktif Menyiram**: Tombol merah dinamis (`#DC2626`) dengan teks *"Matikan Pompa Air - POMPA AKTIF"*.
  - **Feedback Visual (SnackBar)**: Menampilkan pesan konfirmasi ramah pengguna yang bersih tanpa mencantumkan path teknis topik (*"Perintah 'SIRAM' berhasil terpublish ke prototype!"* dan *"Perintah matikan pompa berhasil terpublish!"*).
- **Pill Status Relai**: Menampilkan pembacaan status relai ESP32 (`STANDBY`, `MENYIRAM (AUTO)`, `SIRAM MANUAL (5 DETIK)`, `JEDA RESAP` atau `Menunggu prototype...`).
- **Proteksi Kejenuhan Tanah (> 80%)**: Saklar pompa otomatis ditolak dan dikunci ke posisi OFF apabila kelembapan tanah melampaui 80% untuk mencegah pembusukan umbi bawang merah (*Over-Irrigation Protection*).

---

### 4. Tab 2: Riwayat & Tren Telemetri
- **Grafik Tren (`fl_chart`)**: Kurva fluktuasi kelembapan tanah real-time dengan garis ambang batas:
  - Garis Kritis Min 60% (Merah).
  - Garis Proteksi Max 80% (Biru).
- **Daftar Catatan Telemetri Terakhir**: Menampilkan daftar historis pembacaan data sensor lengkap dengan stempel waktu, nilai kelembapan tanah, suhu udara, kelembapan udara, dan status pompa.

---

### 5. Pop-Up Alert Kelembapan Kritis < 60% (Mockup 3)
- **Kondisi Muncul**: Dialog peringatan otomatis muncul tepat **1 kali** di halaman Beranda apabila kelembapan tanah turun di bawah 60% dan pompa dalam keadaan mati (`!isPumpOn`).
- **Pencegahan Infinite Loop**: Menggunakan mekanisme *state-transition flag* sehingga dialog tidak akan muncul berulang kali saat tombol ditekan atau ditutup.
- **Konten Dialog**:
  - Ikon Segitiga Peringatan Bahaya merah lembut.
  - Teks tegas: `"PERINGATAN! Kelembapan Tanah Kritis (< 60%)"`.
  - Tombol Utama: `"💧 Siram Sekarang"` (langsung mem-publish `"SIRAM"` ke broker dan mengaktifkan relai pompa ESP32).
  - Tombol Sekunder: `"Tutup"`.

---

## 🌐 Integrasi Hardware ESP32 & HiveMQ Cloud Serverless

### 1. Spesifikasi Koneksi Broker
- **Broker Host**: `adaa622b6b644c048748162b0be4ac5f.s1.eu.hivemq.cloud`
- **Port**: `8883` (Koneksi Aman TLS/SSL dengan `SecurityContext.defaultContext` & bypass self-signed validation)
- **Client ID**: Format dinamis `FlutterApp_Nizar_<timestamp>` untuk mencegah tabrakan sesi client ID di broker.
- **Kredensial Autentikasi**:
  - Username: `nizar2209`
  - Password: `saputra2209` (didukung fitur obscure text sensor bintang dan tombol toggle visibilitas sandi).

### 2. Pemetaan Topik Telemetri Masuk (Inbound from ESP32)
Aplikasi secara otomatis men-subscribe topik wildcard `skripsi/nizar/#` dan topik individual:
1. **`skripsi/nizar/soil`**:
   - Membaca data ADC rata-rata 3 sensor kapasitif ESP32 (0–4095).
   - Di Arduino: Nilai `> 2500` adalah kondisi kering, `<= 2500` adalah kondisi ideal.
   - Di Aplikasi: Rumus kalibrasi memetakan rentang ADC 1200 (basah 100%) sampai 3600 (kering 0%) ke persentase 0–100%. Jika payload berupa persentase murni (<= 100), dibaca langsung.
2. **`skripsi/nizar/temp`**: Membaca data suhu udara dari sensor DHT11.
3. **`skripsi/nizar/hum`**: Membaca data kelembapan udara dari sensor DHT11.
4. **`skripsi/nizar/pompa`**: Membaca status relai hardware (`MENYIRAM (AUTO)`, `SIRAM MANUAL (5 DETIK)`, `JEDA RESAP`, `STANDBY`).

### 3. Pemetaan Topik Kendali Keluar (Outbound to ESP32)
- **Topik**: `skripsi/nizar/manual`
- **Payload ON**: String mentah `"SIRAM"` (sesuai sintaks Arduino IDE ESP32: `if (msg == "SIRAM") { ... }`).
- **Payload OFF**: String mentah `"0"`.

---

## 🎨 Ikon Aplikasi Resmi (App Launcher Icon)

Ikon aplikasi bawaan Flutter telah digantikan secara permanen dengan ikon resmi **AGRIFLOW**:
- **Aset Sumber**: `assets/images/agriflow_logo.png` (Logo umbi bawang hijau dengan tetesan air biru di tengahnya dan latar belakang squircle putih).
- **Generator**: `flutter_launcher_icons: ^0.14.3`.
- **Dukungan Android**: Menghasilkan semua resolusi mipmap standar dan adaptive icons:
  - `mipmap-mdpi` (48x48)
  - `mipmap-hdpi` (72x72)
  - `mipmap-xhdpi` (96x96)
  - `mipmap-xxhdpi` (144x144)
  - `mipmap-xxxhdpi` (192x192)
  - `mipmap-anydpi-v26` (Android Adaptive Icons dengan latar belakang `#FFFFFF`).

---

## 🧪 Status Pengujian & Verifikasi Mutu

### 1. Pengujian Otomatis (`flutter test`)
Semua 6 pengujian unit dan integrasi dinyatakan **LULUS (100% Passed)**:
1. `allimation_test.dart`: Verifikasi logika status ambang batas kelembapan tanah (<60% kering, 60-80% optimal, >80% basah).
2. `developer_profile_dialog_test.dart`: Verifikasi kelengkapan seluruh entitas data akademik pengembang (Nama, NIM, Institusi, Judul Skripsi, Tahun).
3. `mqtt_service_parser_test.dart`: Verifikasi kesesuaian kredensial bawaan dengan hardware ESP32 yang telah di-flash.
4. `mqtt_live_connection_test.dart`: Verifikasi koneksi live TLS port 8883 ke broker HiveMQ Cloud Serverless dan pengiriman payload `"SIRAM"`.
5. `widget_test.dart`: Verifikasi rendering halaman utama dan navigasi.

### 2. Pengujian Nyata (*Live Telemetry & Control Test*)
- Telah diuji penerimaan data tiruan ESP32: nilai kelembapan tanah, suhu udara, kelembapan udara, status relai pompa, dan grafik riwayat ter-update secara otomatis tanpa perlu refresh manual.
- Telah diuji pengiriman perintah tombol manual dari aplikasi ke HiveMQ Cloud Serverless:
  ```text
  >>> PROBE RECEIVED TOPIC: [skripsi/nizar/manual] PAYLOAD: [SIRAM]
  >>> PROBE RECEIVED TOPIC: [skripsi/nizar/manual] PAYLOAD: [0]
  ```

---

## 📦 File Paket APK Rilis

File APK mandiri versi rilis (*release bundle*) yang telah dilengkapi ikon resmi AGRIFLOW dan konfigurasi TLS HiveMQ siap dipasang pada perangkat Android:
- **Lokasi File**: `build/app/outputs/flutter-apk/app-release.apk`
- **Ukuran File**: ± 23.2 MB
- **Perintah Build Ulang**:
  ```bash
  flutter build apk --release
  ```
- **Perintah Jalankan di HP / Emulator**:
  ```bash
  flutter run --release
  ```
