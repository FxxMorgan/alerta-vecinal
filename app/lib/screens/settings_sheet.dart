import 'package:flutter/material.dart';
import '../services/alarm_player_service.dart';
import '../services/alarm_sync_service.dart';
import '../services/native_alert_service.dart';
import '../theme/app_theme.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  bool _isTestingSiren = false;
  bool _isIgnoringBattery = false;

  @override
  void initState() {
    super.initState();
    final service = AlarmSyncService();
    _nameController = TextEditingController(text: service.neighborName);
    _urlController = TextEditingController(text: service.serverUrl);
    _checkBattery();
  }

  Future<void> _checkBattery() async {
    final status = await NativeAlertService.isIgnoringBatteryOptimizations();
    if (mounted) setState(() => _isIgnoringBattery = status);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    if (_isTestingSiren) {
      AlarmPlayerService().stopAlarm();
    }
    super.dispose();
  }

  void _toggleSirenTest() async {
    if (_isTestingSiren) {
      await AlarmPlayerService().stopAlarm();
      setState(() => _isTestingSiren = false);
    } else {
      setState(() => _isTestingSiren = true);
      await AlarmPlayerService().startAlarm();
    }
  }

  void _requestBatteryPermission() async {
    await NativeAlertService.requestIgnoreBatteryOptimizations();
    await Future.delayed(const Duration(seconds: 1));
    _checkBattery();
  }

  void _save() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre y una dirección válida.')),
      );
      return;
    }

    await AlarmSyncService().updateConfig(newUrl: url, newName: name);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.sageGreen,
          content: Text('Configuración guardada y reconectando...', style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Configuración del Dispositivo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Identificador de vecino
            const Text(
              'Identificador de tu Vivienda / Nombre',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Ej. Casa 14 - Familia Soto',
                filled: true,
                fillColor: AppColors.surfaceSlateLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dirección del servidor local
            const Text(
              'Servidor Local (WebSocket)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'ws://192.168.1.100:8080',
                filled: true,
                fillColor: AppColors.surfaceSlateLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta de Permiso de Batería
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isIgnoringBattery ? AppColors.sageGreenLight : AppColors.amberWarningLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isIgnoringBattery ? AppColors.sageGreen : AppColors.amberWarning,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isIgnoringBattery ? Icons.check_circle_outline : Icons.battery_alert_outlined,
                    color: _isIgnoringBattery ? AppColors.sageGreen : AppColors.amberWarning,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isIgnoringBattery
                              ? 'Segundo Plano Ilimitado Activo'
                              : 'Optimización de Batería Pendiente',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isIgnoringBattery ? AppColors.sageGreen : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isIgnoringBattery
                              ? 'Tu teléfono recibirá la alarma incluso si está bloqueado.'
                              : 'Requerido para que la alarma suene con pantalla apagada.',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (!_isIgnoringBattery)
                    TextButton(
                      onPressed: _requestBatteryPermission,
                      child: const Text('PERMITIR', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Botón de Prueba de Sirena
            OutlinedButton.icon(
              onPressed: _toggleSirenTest,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: _isTestingSiren ? AppColors.alertCrimson : AppColors.borderMedium),
                foregroundColor: _isTestingSiren ? AppColors.alertCrimson : AppColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(_isTestingSiren ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
              label: Text(_isTestingSiren ? 'Detener Sirena de Prueba' : 'Probar Sirena en este Teléfono'),
            ),
            const SizedBox(height: 20),

            // Botón Guardar
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Guardar y Reconectar'),
            ),
          ],
        ),
      ),
    );
  }
}
