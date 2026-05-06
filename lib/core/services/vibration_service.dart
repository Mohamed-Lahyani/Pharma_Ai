// lib/core/services/vibration_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class VibrationService {
  // ── Singleton ───────────────────────────────────────────────
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  static const String _kVibrationKey = 'pharma_ai_vibration_enabled';

  bool _vibrationEnabled = true;
  bool _hasVibrator      = false;

  // ════════════════════════════════════════════════════════════
  // INITIALISATION
  // ════════════════════════════════════════════════════════════

  Future<void> init() async {
    await _loadPreferences();

    // ✅ CORRECTION : cast explicite en bool pour éviter le warning
    final result = await Vibration.hasVibrator();
    _hasVibrator = result == true;

    debugPrint(
      '[VibrationService] Initialisé. '
          'Vibreur disponible : $_hasVibrator | '
          'Vibration activée : $_vibrationEnabled',
    );
  }

  // ════════════════════════════════════════════════════════════
  // PRÉFÉRENCES
  // ════════════════════════════════════════════════════════════

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _vibrationEnabled = prefs.getBool(_kVibrationKey) ?? true;
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kVibrationKey, enabled);
    debugPrint('[VibrationService] Vibration ${enabled ? "activée" : "désactivée"}');
  }

  bool get isVibrationEnabled => _vibrationEnabled;

  Future<void> toggleVibration() async {
    await setVibrationEnabled(!_vibrationEnabled);
  }

  // ════════════════════════════════════════════════════════════
  // MÉTHODE INTERNE
  // ════════════════════════════════════════════════════════════

  bool get _canVibrate => _vibrationEnabled && _hasVibrator;

  // ════════════════════════════════════════════════════════════
  // PATTERNS DE VIBRATION
  // ════════════════════════════════════════════════════════════

  /// Vibration légère — feedback simple (appui bouton)
  Future<void> light() async {
    if (!_canVibrate) return;
    try {
      await Vibration.vibrate(duration: 50);
    } catch (e) {
      debugPrint('[VibrationService] Erreur vibration légère : $e');
    }
  }

  /// Vibration succès — scan réussi, ordonnance envoyée
  Future<void> success() async {
    if (!_canVibrate) return;
    try {
      await Vibration.vibrate(
        pattern    : [0, 50, 100, 150],
        intensities: [0, 128, 0, 255],
      );
    } catch (e) {
      await Vibration.vibrate(duration: 200);
      debugPrint('[VibrationService] Pattern succès non supporté, fallback : $e');
    }
  }

  /// Vibration erreur — médicament non trouvé, scan échoué
  Future<void> error() async {
    if (!_canVibrate) return;
    try {
      await Vibration.vibrate(
        pattern    : [0, 300, 100, 300],
        intensities: [0, 200, 0, 200],
      );
    } catch (e) {
      await Vibration.vibrate(duration: 500);
      debugPrint('[VibrationService] Pattern erreur non supporté, fallback : $e');
    }
  }

  /// Vibration double — validation ordonnance admin
  Future<void> doubleVibrate() async {
    if (!_canVibrate) return;
    try {
      await Vibration.vibrate(pattern: [0, 100, 80, 100]);
    } catch (e) {
      await Vibration.vibrate(duration: 150);
      debugPrint('[VibrationService] Pattern double non supporté, fallback : $e');
    }
  }

  /// Vibration scan — bip haptique court lors du scan barcode
  Future<void> scanFeedback() async {
    if (!_canVibrate) return;
    try {
      await Vibration.vibrate(duration: 30);
    } catch (e) {
      debugPrint('[VibrationService] Erreur vibration scan : $e');
    }
  }

  /// Stopper toute vibration en cours
  Future<void> stop() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('[VibrationService] Erreur stop vibration : $e');
    }
  }
}