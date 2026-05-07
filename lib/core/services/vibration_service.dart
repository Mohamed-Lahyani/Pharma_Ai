// lib/core/services/vibration_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← Ajout pour HapticFeedback fallback
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class VibrationService {
  // ── Singleton ─────────────────────────────────────────────────
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  static const String _kVibrationKey = 'pharma_ai_vibration_enabled';

  bool _vibrationEnabled = true;
  bool _hasVibrator      = false;
  bool _hasAmplitudeControl = false; // ← Nouveau : certains Android ne gèrent pas intensities

  // ════════════════════════════════════════════════════════════
  // INITIALISATION
  // ════════════════════════════════════════════════════════════

  Future<void> init() async {
    await _loadPreferences();

    // Vérification vibreur
    final hasVib = await Vibration.hasVibrator();
    _hasVibrator = hasVib == true;

    // ✅ CORRECTION : vérifier si l'appareil supporte le contrôle d'amplitude
    if (_hasVibrator) {
      final hasAmp = await Vibration.hasAmplitudeControl();
      _hasAmplitudeControl = hasAmp == true;
    }

    debugPrint(
      '[VibrationService] Initialisé. '
          'Vibreur : $_hasVibrator | '
          'Amplitude : $_hasAmplitudeControl | '
          'Activé : $_vibrationEnabled',
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
  // MÉTHODE INTERNE CORRIGÉE
  // ════════════════════════════════════════════════════════════

  bool get _canVibrate => _vibrationEnabled && _hasVibrator;

  /// Vibration avec pattern + intensities si supporté, sinon fallback simple
  Future<void> _vibratePattern({
    required List<int> pattern,
    List<int>? intensities,
    int fallbackDuration = 200,
  }) async {
    if (!_canVibrate) return;
    try {
      if (_hasAmplitudeControl && intensities != null) {
        // ✅ Appareil supporte les intensités
        await Vibration.vibrate(pattern: pattern, intensities: intensities);
      } else {
        // ✅ Fallback : pattern sans intensités
        await Vibration.vibrate(pattern: pattern);
      }
    } catch (e) {
      // ✅ Dernier recours : vibration simple
      try {
        await Vibration.vibrate(duration: fallbackDuration);
      } catch (e2) {
        // Fallback final via Flutter HapticFeedback (marche même sans plugin)
        await HapticFeedback.mediumImpact();
        debugPrint('[VibrationService] Fallback haptique : $e2');
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // PATTERNS DE VIBRATION
  // ════════════════════════════════════════════════════════════

  /// Vibration légère — feedback simple (appui bouton)
  Future<void> light() async {
    if (!_canVibrate) {
      await HapticFeedback.lightImpact(); // fallback si pas de vibreur plugin
      return;
    }
    try {
      await Vibration.vibrate(duration: 50);
    } catch (e) {
      await HapticFeedback.lightImpact();
    }
  }

  /// Vibration succès — scan réussi, ordonnance envoyée
  Future<void> success() async {
    await _vibratePattern(
      pattern: [0, 50, 100, 150],
      intensities: [0, 128, 0, 255],
      fallbackDuration: 200,
    );
  }

  /// Vibration erreur — médicament non trouvé, scan échoué
  Future<void> error() async {
    await _vibratePattern(
      pattern: [0, 300, 100, 300],
      intensities: [0, 200, 0, 200],
      fallbackDuration: 500,
    );
  }

  /// Vibration double — validation ordonnance admin
  Future<void> doubleVibrate() async {
    await _vibratePattern(
      pattern: [0, 100, 80, 100],
      fallbackDuration: 150,
    );
  }

  /// Vibration scan — bip haptique court lors du scan barcode
  Future<void> scanFeedback() async {
    if (!_canVibrate) {
      await HapticFeedback.selectionClick();
      return;
    }
    try {
      await Vibration.vibrate(duration: 30);
    } catch (e) {
      await HapticFeedback.selectionClick();
    }
  }

  /// Stopper toute vibration en cours
  Future<void> stop() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('[VibrationService] Erreur stop : $e');
    }
  }
}