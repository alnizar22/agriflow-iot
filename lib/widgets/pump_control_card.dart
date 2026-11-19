import 'package:flutter/material.dart';

class PumpControlCard extends StatelessWidget {
  final bool isPumpOn;
  final bool isAutoMode;
  final ValueChanged<bool> onPumpToggle;
  final ValueChanged<bool> onAutoModeToggle;

  const PumpControlCard({
    super.key,
    required this.isPumpOn,
    required this.isAutoMode,
    required this.onPumpToggle,
    required this.onAutoModeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isPumpOn ? const Color(0xFF00E676) : const Color(0xFF64748B);
    final glowColor = isPumpOn ? const Color(0xFF00E676).withValues(alpha: 0.4) : Colors.transparent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPumpOn ? const Color(0xFF00E676).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
          width: isPumpOn ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isPumpOn)
            BoxShadow(
              color: glowColor,
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.power_settings_new_rounded,
                      color: activeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AKTUATOR POMPA AIR',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPumpOn ? 'STATUS: MENYALA (IRIGASI AKTIF)' : 'STATUS: MATI (STANDBY)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: activeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Transform.scale(
                scale: 1.1,
                child: Switch(
                  value: isPumpOn,
                  activeColor: const Color(0xFF00E676),
                  activeTrackColor: const Color(0xFF00E676).withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.white54,
                  inactiveTrackColor: Colors.white12,
                  onChanged: onPumpToggle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isAutoMode ? Icons.smart_toy_rounded : Icons.touch_app_rounded,
                    size: 18,
                    color: isAutoMode ? const Color(0xFF38BDF8) : Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAutoMode ? 'Mode Irigasi Otomatis (ESP32)' : 'Mode Manual (Aplikasi)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => onAutoModeToggle(!isAutoMode),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isAutoMode ? const Color(0xFF38BDF8) : Colors.amber).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isAutoMode ? const Color(0xFF38BDF8) : Colors.amber).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    isAutoMode ? 'OTOMATIS' : 'MANUAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isAutoMode ? const Color(0xFF38BDF8) : Colors.amber,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
