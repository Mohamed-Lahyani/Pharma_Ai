// lib/core/services/sound_service.dart
//
// Service de gestion des effets sonores pour PharmaAI
// Gère :
//   - Son de succès (scan OCR réussi, barcode trouvé, ordonnance envoyée)
//   - Son d'erreur (médicament non trouvé, scan échoué)
//   - Son de validation (ordonnance validée par l'admin)
//   - Activation / désactivation globale des sons (SharedPreferences)
// ═══════════════════════════════════════════════════════════════

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  // ── Singleton ───────────────────────────────────────────────
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // ── Clé SharedPreferences ───────────────────────────────────
  static const String _kSoundKey = 'pharma_ai_sound_enabled';

  // ── Player dédié (un seul à la fois) ────────────────────────
  final AudioPlayer _player = AudioPlayer();

  // ── État local : sons activés ou non ────────────────────────
  bool _soundEnabled = true;

  // ── Noms des fichiers audio (assets/sounds/) ─────────────────
  // Ces fichiers doivent être placés dans assets/sounds/
  // et déclarés dans pubspec.yaml sous flutter > assets
  static const String _successSound    = 'sounds/success.mp3';
  static const String _errorSound      = 'sounds/error.mp3';
  static const String _scanSound       = 'sounds/scan_beep.mp3';
  static const String _validationSound = 'sounds/validation.mp3';
  static const String _notifSound      = 'sounds/notification.mp3';

  // ════════════════════════════════════════════════════════════
  // INITIALISATION
  // ════════════════════════════════════════════════════════════

  /// Initialiser le service et charger les préférences sauvegardées.
  /// Appeler dans main() après Firebase.initializeApp()
  Future<void> init() async {
    await _loadPreferences();

    // Configurer le player en mode bas volume par défaut
    await _player.setVolume(1.0);
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setSource(AssetSource(_scanSound));

    debugPrint('[SoundService] Initialisé. Sons activés : $_soundEnabled');
  }

  // ════════════════════════════════════════════════════════════
  // GESTION DES PRÉFÉRENCES
  // ════════════════════════════════════════════════════════════

  /// Charger le paramètre sons depuis SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_kSoundKey) ?? true; // activé par défaut
  }

  /// Activer ou désactiver les sons et sauvegarder le choix
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundKey, enabled);
    debugPrint('[SoundService] Sons ${enabled ? "activés" : "désactivés"}');
  }

  /// Retourner l'état actuel des sons
  bool get isSoundEnabled => _soundEnabled;

  /// Basculer rapidement activé/désactivé
  Future<void> toggleSound() async {
    await setSoundEnabled(!_soundEnabled);
  }

  // ════════════════════════════════════════════════════════════
  // LECTURE DES SONS
  // ════════════════════════════════════════════════════════════

  /// Méthode interne de lecture (vérifie d'abord si les sons sont activés)
  Future<void> _play(String assetPath) async {
    if (!_soundEnabled) return;

    try {
      // S'assurer que le mode de libération est bien sur STOP ou RELEASE
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('[SoundService] Erreur lecture : $e');
    }
  }

  // ── Sons publics ────────────────────────────────────────────

  /// Son de succès — scan OCR réussi, barcode trouvé, ordonnance envoyée
  Future<void> playSuccess() => _play(_successSound);

  /// Son d'erreur — médicament non trouvé, scan échoué, erreur réseau
  Future<void> playError() => _play(_errorSound);

  /// Son de scan — bip court lors du scan barcode (temps réel)
  Future<void> playScanBeep() => _play(_scanSound);

  /// Son de validation — ordonnance validée par l'admin
  Future<void> playValidation() => _play(_validationSound);

  /// Son de notification — nouveau message / alerte
  Future<void> playNotification() => _play(_notifSound);

  // ════════════════════════════════════════════════════════════
  // NETTOYAGE
  // ════════════════════════════════════════════════════════════

  /// Libérer les ressources du player (appeler dans dispose si nécessaire)
  Future<void> dispose() async {
    await _player.dispose();
  }
}