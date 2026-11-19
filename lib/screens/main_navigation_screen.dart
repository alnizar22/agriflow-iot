import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/irrigation_provider.dart';
import '../widgets/pop_up_alert.dart';
import 'dashboard_screen.dart';
import 'kontrol_screen.dart';
import 'riwayat_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _hasShownCriticalDialog = false;

  final List<Widget> _screens = const [
    DashboardScreen(), // Tab 0: Beranda (Mockup 1)
    KontrolScreen(), // Tab 1: Kontrol (Mockup 2)
    RiwayatScreen(), // Tab 2: Riwayat (Skripsi Bab 4 Revision)
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCriticalMoistureAlert();
    });
  }

  void _checkCriticalMoistureAlert() {
    final provider = Provider.of<IrrigationProvider>(context, listen: false);
    final hasData = provider.hasData;
    final hasSoilData = provider.currentData.hasSoilData;
    final moisture = provider.currentData.soilMoisture;
    final isPumpOn = provider.currentData.isPumpOn;

    if (hasData && hasSoilData && moisture < 60.0 && !isPumpOn && !_hasShownCriticalDialog) {
      _hasShownCriticalDialog = true;
      PopUpAlert.showCriticalMoistureDialog(
        context: context,
        moisture: moisture,
        onDismiss: () {
          // Dialog ditutup oleh pengguna, biarkan flag true agar tidak looping
        },
        onActivatePump: () async {
          final ok = await provider.togglePumpState(true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? "Perintah 'SIRAM' berhasil terpublish ke prototype!"
                      : "Gagal mengirim perintah: Sedang menghubungkan ulang ke broker...",
                ),
                backgroundColor:
                    ok ? const Color(0xFF047857) : Colors.redAccent,
              ),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IrrigationProvider>(
      builder: (context, provider, child) {
        final hasData = provider.hasData;
        final hasSoilData = provider.currentData.hasSoilData;
        final moisture = provider.currentData.soilMoisture;
        final isPumpOn = provider.currentData.isPumpOn;

        // Pengecekan kelembapan < 60% untuk pemicu Pop-Up Alert (Hanya jika data tanah valid telah diterima, di Beranda, dan saat pompa mati)
        if (_currentIndex == 0 && hasData && hasSoilData && moisture < 60.0 && !isPumpOn) {
          if (!_hasShownCriticalDialog) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_hasShownCriticalDialog &&
                  mounted &&
                  !provider.currentData.isPumpOn) {
                _hasShownCriticalDialog = true;
                PopUpAlert.showCriticalMoistureDialog(
                  context: context,
                  moisture: moisture,
                  onDismiss: () {
                    // Dialog ditutup oleh pengguna, biarkan flag true
                  },
                  onActivatePump: () async {
                    final ok = await provider.togglePumpState(true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? "Perintah 'SIRAM' berhasil terpublish ke prototype!"
                                : "Gagal mengirim perintah: Sedang menghubungkan ulang ke broker...",
                          ),
                          backgroundColor:
                              ok ? const Color(0xFF047857) : Colors.redAccent,
                        ),
                      );
                    }
                  },
                );
              }
            });
          }
        } else if (!hasData || !hasSoilData || moisture >= 60.0 || isPumpOn) {
          // Jika belum ada data tanah, sudah optimal, atau pompa sedang menyiram, reset dialog flag
          _hasShownCriticalDialog = false;
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF047857), // Deep Green Accent
              unselectedItemColor: const Color(0xFF64748B),
              selectedFontSize: 12,
              unselectedFontSize: 12,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.eco_outlined),
                  activeIcon: Icon(Icons.eco_rounded),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.tune_outlined),
                  activeIcon: Icon(Icons.tune_rounded),
                  label: 'Kontrol',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_outlined),
                  activeIcon: Icon(Icons.history_rounded),
                  label: 'Riwayat',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
