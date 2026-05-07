import 'package:flutter/material.dart';
import 'core/services/sound_service.dart';
import 'core/services/vibration_service.dart';

class TestSoundVibrationScreen extends StatefulWidget {
  const TestSoundVibrationScreen({super.key});
  @override
  State<TestSoundVibrationScreen> createState() => _TestState();
}

class _TestState extends State<TestSoundVibrationScreen> {
  final _sound     = SoundService();
  final _vibration = VibrationService();
  String _log = 'Prêt à tester...';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _sound.init();
    await _vibration.init();
    setState(() => _log = '✅ Services initialisés');
  }

  // ── Helper log ─────────────────────────────────────────────
  void _logMsg(String msg) => setState(() => _log = msg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Sons & Vibrations')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Zone de log ─────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _log,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 24),

              // ── SONS ────────────────────────────────────
              const Text(
                'SONS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _btn('🎵 Success',    Colors.green,  () async { await _sound.playSuccess();      _logMsg('▶ success.mp3'); }),
              _btn('🎵 Error',      Colors.red,    () async { await _sound.playError();        _logMsg('▶ error.mp3'); }),
              _btn('🎵 Scan Beep',  Colors.blue,   () async { await _sound.playScanBeep();     _logMsg('▶ scan_beep.mp3'); }),
              _btn('🎵 Validation', Colors.teal,   () async { await _sound.playValidation();   _logMsg('▶ validation.mp3'); }),
              _btn('🎵 Notif',      Colors.orange, () async { await _sound.playNotification(); _logMsg('▶ notification.mp3'); }),

              const Divider(height: 32),

              // ── VIBRATIONS ──────────────────────────────
              const Text(
                'VIBRATIONS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _btn('📳 Light',   Colors.grey,   () async { await _vibration.light();         _logMsg('📳 light'); }),
              _btn('📳 Success', Colors.green,  () async { await _vibration.success();       _logMsg('📳 success'); }),
              _btn('📳 Error',   Colors.red,    () async { await _vibration.error();         _logMsg('📳 error'); }),
              _btn('📳 Double',  Colors.purple, () async { await _vibration.doubleVibrate(); _logMsg('📳 double'); }),
              _btn('📳 Scan',    Colors.blue,   () async { await _vibration.scanFeedback();  _logMsg('📳 scan'); }),

              const Divider(height: 32),

              // ── COMBINÉ ─────────────────────────────────
              _btn('🔊+📳 Scan complet', Colors.indigo, () async {
                await Future.wait([
                  _sound.playScanBeep(),
                  _vibration.scanFeedback(),
                ]);
                _logMsg('✅ Son + vibration simultanés');
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bouton helper ──────────────────────────────────────────
  Widget _btn(String label, Color color, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    ),
  );
}