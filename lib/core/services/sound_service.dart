import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();
  static const String _kSoundKey = 'pharma_ai_sound_enabled';
  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;
  static const String _successSound    = 'sounds/success.mp3';
  static const String _errorSound      = 'sounds/error.mp3';
  static const String _scanSound       = 'sounds/scan_beep.mp3';
  static const String _validationSound = 'sounds/validation.mp3';
  static const String _notifSound      = 'sounds/notification.mp3';

  /// Initialiser le service et charger les préférences sauvegardées.
  /// Appeler dans main() après Firebase.initializeApp()
  Future<void> init() async {
    await _loadPreferences();
    await _player.setVolume(1.0);
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setSource(AssetSource(_scanSound));

    debugPrint('[SoundService] Initialisé. Sons activés : $_soundEnabled');
  }

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

  /// Méthode interne de lecture (vérifie d'abord si les sons sont activés)
  Future<void> _play(String assetPath) async {
    if (!_soundEnabled) return;

    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('[SoundService] Erreur lecture : $e');
    }
  }

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

  /// Libérer les ressources du player (appeler dans dispose si nécessaire)
  Future<void> dispose() async {
    await _player.dispose();
  }
}