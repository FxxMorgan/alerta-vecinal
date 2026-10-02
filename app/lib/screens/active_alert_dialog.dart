import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../services/alarm_player_service.dart';
import '../services/alarm_sync_service.dart';
import '../theme/app_theme.dart';

class ActiveAlertView extends StatefulWidget {
  final AlertModel alert;
  final VoidCallback onDismissLocal;

  const ActiveAlertView({
    super.key,
    required this.alert,
    required this.onDismissLocal,
  });

  @override
  State<ActiveAlertView> createState() => _ActiveAlertViewState();
}

class _ActiveAlertViewState extends State<ActiveAlertView> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss').format(widget.alert.timestamp);

    return Scaffold(
      backgroundColor: AppColors.alertCoralLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Pulsing Alert Icon
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final scale = 1.0 + (_animController.value * 0.15);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.alertCrimson,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.alertCrimson.withValues(alpha: 0.4),
                            blurRadius: 28 * scale,
                            spreadRadius: 8 * scale,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                '¡ALERTA DE ROBO / PELIGRO!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.alertCrimson,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 12),

              // Card details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.alertCoral, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'ALERTA EMITIDA POR:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.alert.sender,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.borderSubtle),
                    const SizedBox(height: 8),
                    Text(
                      widget.alert.notes,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Hora: $timeStr',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Actions
              // 1. Silenciar localmente
              ElevatedButton.icon(
                onPressed: () {
                  AlarmPlayerService().stopAlarm();
                  widget.onDismissLocal();
                },
                icon: const Icon(Icons.volume_off, color: Colors.white),
                label: const Text('Silenciar Mi Teléfono'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.steelBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 12),

              // 2. Cancelar para todos los vecinos
              OutlinedButton.icon(
                onPressed: () {
                  AlarmSyncService().cancelEmergencyAlert();
                  widget.onDismissLocal();
                },
                icon: const Icon(Icons.check_circle_outline, color: AppColors.alertCrimson),
                label: const Text('Cancelar Alerta General (Falsa Alarma / Resuelto)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: AppColors.alertCrimson, width: 1.5),
                  foregroundColor: AppColors.alertCrimson,
                  backgroundColor: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
