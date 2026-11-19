import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/settings_screen.dart';

class DeveloperProfileDialog extends StatelessWidget {
  const DeveloperProfileDialog({super.key});

  /// Helper statis untuk menampilkan pop-up dialog profil pengembang
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => const DeveloperProfileDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 20,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // BAGIAN A: Header & Pengantar Akademik
              // ==========================================
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7), // Soft mint green
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF047857).withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school_rounded,
                      color: Color(0xFF047857),
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Informasi Pengembang',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Aplikasi ini dikembangkan sebagai syarat kelulusan untuk memperoleh gelar Sarjana Komputer (S.Kom).',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================
              // BAGIAN B: Identitas Skripsi (Kartu Utama)
              // ==========================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header Institusi Kampus + Logo Resmi STMIK Widya Utama
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/logo_stmik.png',
                            height: 48,
                            width: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0288D1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STMIK WIDYA UTAMA',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'PURWOKERTO • 2026',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF047857),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFFE2E8F0), height: 1),
                    ),

                    // Judul Penelitian Lengkap
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'JUDUL PENELITIAN',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '“RANCANG BANGUN SISTEM KONTROL DAN MONITORING PENYIRAMAN BAWANG MERAH BERBASIS IOT MENGGUNAKAN APLIKASI MOBILE FLUTTER (Studi Kasus: Kelompok Tani Dukuhwringin Brebes)”',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF1E293B),
                          height: 1.45,
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFFE2E8F0), height: 1),
                    ),

                    // Nama Mahasiswa
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NAMA MAHASISWA',
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'EVA YUNIZAR SUGIARTO',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Baris NIM dan Tahun
                    Row(
                      children: [
                        // Pill NIM (Highlight Hijau)
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.badge_rounded, size: 18, color: Color(0xFF047857)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'NIM',
                                        style: GoogleFonts.outfit(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF047857),
                                        ),
                                      ),
                                      Text(
                                        'STI202202907',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF047857),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Pill Tahun (Highlight Biru)
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF0288D1)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TAHUN',
                                        style: GoogleFonts.outfit(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0288D1),
                                        ),
                                      ),
                                      Text(
                                        '2026',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0288D1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================
              // BAGIAN C: Footer / Tindakan
              // ==========================================
              Row(
                children: [
                  // Tombol Akses Cepat Konfigurasi MQTT (Menu Lama yang dipindahkan)
                  Tooltip(
                    message: 'Konfigurasi Broker MQTT',
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Color(0xFF475569), size: 22),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Tombol Tutup Lebar (Full-Width Button)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF047857), // Deep Green
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Tutup',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
