// lib/features/client/barcode/barcode_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';
import 'dart:io';

// ═══════════════════════════════════════════════════════════════
// BarcodeScannerScreen — Scanner code-barres médicament (ML Kit)
//
// Fonctionnement :
//   1. La caméra s'ouvre en temps réel (flux CameraImage)
//   2. ML Kit détecte le code-barres frame par frame
//   3. Dès qu'un code est détecté → on cherche dans Firestore
//      par le champ `barcode` de la collection `medications`
//   4. On affiche une fiche médicament (nom, prix, stock, catégorie)
//   5. Le client peut rescanner ou retourner à l'accueil
// ═══════════════════════════════════════════════════════════════

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  // ── Couleurs sémantiques (conservées fixes) ────────────────
  static const Color green = Color(0xFF2E7D32);
  static const Color amber = Color(0xFFF9A825);
  static const Color red   = Color(0xFFC62828);

  // ── État de l'écran ────────────────────────────────────────
  // 'scanning'   → caméra active, recherche en cours
  // 'searching'  → code détecté, requête Firestore en cours
  // 'found'      → médicament trouvé dans Firestore
  // 'notFound'   → code-barres non référencé
  // 'error'      → erreur caméra ou permission
  String _etape = 'scanning';

  // ── Caméra ────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraInitialisee = false;

  // ── ML Kit Barcode Scanner ─────────────────────────────────
  final BarcodeScanner _barcodeScanner = BarcodeScanner(
    formats: [
      BarcodeFormat.ean13,   // Code-barres médicaments Europe
      BarcodeFormat.ean8,
      BarcodeFormat.code128, // Code-barres hôpitaux/pharmacies
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,  // QR codes bonus
      BarcodeFormat.upca,
      BarcodeFormat.upce,
    ],
  );

  // ── Contrôle du traitement frame par frame ─────────────────
  bool _traitement = false; // Évite les doubles traitements simultanés

  // ── Résultat du scan ──────────────────────────────────────
  String _codeDetecte  = '';
  Map<String, dynamic>? _medicamentTrouve;
  String _erreur = '';

  // ── Torche ────────────────────────────────────────────────
  bool _torche = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialiserCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  // ── Gestion cycle de vie (pause/resume de l'app) ──────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initialiserCamera();
    }
  }

  // ════════════════════════════════════════════════════════════
  // INITIALISATION CAMÉRA
  // ════════════════════════════════════════════════════════════
  Future<void> _initialiserCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _etape  = 'error';
          _erreur = 'Aucune caméra disponible sur cet appareil.';
        });
        return;
      }

      // Caméra arrière en priorité
      final camera = _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21   // Format optimal ML Kit Android
            : ImageFormatGroup.bgra8888, // Format optimal ML Kit iOS
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() => _cameraInitialisee = true);

      // Démarrer le flux d'images pour le scan temps réel
      await _cameraController!.startImageStream(_traiterFrame);
    } catch (e) {
      if (mounted) {
        setState(() {
          _etape  = 'error';
          _erreur = 'Erreur initialisation caméra : $e';
        });
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // TRAITEMENT FRAME PAR FRAME — ML Kit Barcode
  // ════════════════════════════════════════════════════════════
  Future<void> _traiterFrame(CameraImage image) async {
    // Ignorer si déjà en cours de traitement ou si on n'est plus en mode scan
    if (_traitement || _etape != 'scanning') return;
    _traitement = true;

    try {
      // Convertir CameraImage → InputImage pour ML Kit
      final inputImage = _convertirImage(image);
      if (inputImage == null) {
        _traitement = false;
        return;
      }

      // Analyse ML Kit
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isEmpty) {
        _traitement = false;
        return;
      }

      // On prend le premier code-barres valide détecté
      final barcode = barcodes.first;
      final code    = barcode.rawValue ?? '';

      if (code.isEmpty) {
        _traitement = false;
        return;
      }

      // Code trouvé → arrêter le flux et chercher dans Firestore
      await _cameraController?.stopImageStream();

      if (mounted) {
        setState(() {
          _codeDetecte = code;
          _etape       = 'searching';
        });
      }

      await _rechercherMedicament(code);
    } catch (e) {
      debugPrint('[BarcodeScanner] Erreur traitement frame : $e');
    } finally {
      _traitement = false;
    }
  }

  // ── Convertir CameraImage → InputImage (ML Kit) ───────────
  InputImage? _convertirImage(CameraImage image) {
    try {
      final camera = _cameraController?.description;
      if (camera == null) return null;

      final rotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      // Pour Android NV21 — un seul plan
      if (image.planes.isEmpty) return null;

      final bytes = image.planes.first.bytes;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(
            image.width.toDouble(),
            image.height.toDouble(),
          ),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('[BarcodeScanner] Erreur conversion image : $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════
  // RECHERCHE FIRESTORE par champ `barcode`
  // ════════════════════════════════════════════════════════════
  Future<void> _rechercherMedicament(String code) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('medications')
          .where('barcode', isEqualTo: code)
          .limit(1)
          .get();

      if (!mounted) return;

      if (query.docs.isEmpty) {
        // Code-barres non référencé dans la base
        setState(() => _etape = 'notFound');
      } else {
        // Médicament trouvé
        final doc  = query.docs.first;
        final data = doc.data();
        data['id'] = doc.id;

        setState(() {
          _medicamentTrouve = data;
          _etape            = 'found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erreur = 'Erreur recherche : $e';
          _etape  = 'error';
        });
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // RESCANNER — réinitialiser et relancer le flux
  // ════════════════════════════════════════════════════════════
  Future<void> _rescanner() async {
    setState(() {
      _etape            = 'scanning';
      _codeDetecte      = '';
      _medicamentTrouve = null;
      _erreur           = '';
      _traitement       = false;
    });

    try {
      // Relancer le flux si la caméra est initialisée
      if (_cameraController != null &&
          _cameraController!.value.isInitialized &&
          !_cameraController!.value.isStreamingImages) {
        await _cameraController!.startImageStream(_traiterFrame);
      }
    } catch (e) {
      // Si le flux ne peut pas redémarrer → réinitialiser la caméra
      await _initialiserCamera();
    }
  }

  // ── Toggle torche ──────────────────────────────────────────
  Future<void> _toggleTorche() async {
    try {
      _torche = !_torche;
      await _cameraController?.setFlashMode(
        _torche ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      debugPrint('[BarcodeScanner] Torche non disponible : $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scanner un médicament',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // Bouton torche (visible uniquement en mode scan)
          if (_etape == 'scanning' && _cameraInitialisee)
            IconButton(
              icon: Icon(
                _torche ? Icons.flash_on : Icons.flash_off,
                color: _torche ? amber : Colors.white,
              ),
              onPressed: _toggleTorche,
              tooltip: 'Torche',
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContenu(),
      ),
    );
  }

  Widget _buildContenu() {
    switch (_etape) {
      case 'searching':
        return _buildEtapeSearching();
      case 'found':
        return _buildEtapeFound();
      case 'notFound':
        return _buildEtapeNotFound();
      case 'error':
        return _buildEtapeError();
      default:
        return _buildEtapeScanning();
    }
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE : scanning — Caméra active + viseur
  // ════════════════════════════════════════════════════════════
  Widget _buildEtapeScanning() {
    if (!_cameraInitialisee || _cameraController == null) {
      return const Center(
        key: ValueKey('loading'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Initialisation de la caméra...',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Stack(
      key: const ValueKey('scanning'),
      fit: StackFit.expand,
      children: [
        // ── Prévisualisation caméra ────────────────────────
        CameraPreview(_cameraController!),

        // ── Overlay sombre autour du viseur ───────────────
        _buildOverlaySombre(),

        // ── Viseur animé ──────────────────────────────────
        Center(child: _buildViseur()),

        // ── Instructions bas d'écran ───────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBandeauInstructions(),
        ),
      ],
    );
  }

  // ── Overlay sombre avec découpe centrale ──────────────────
  Widget _buildOverlaySombre() {
    return CustomPaint(
      painter: _OverlayScannerPainter(),
    );
  }

  // ── Viseur avec coins animés ───────────────────────────────
  Widget _buildViseur() {
    const double taille   = 260;
    const double epaisseur = 4;
    const double longueur  = 36;
    const Color  couleurCoin = Colors.white;

    return SizedBox(
      width: taille,
      height: taille,
      child: Stack(
        children: [
          // Coin haut-gauche
          Positioned(
            top: 0, left: 0,
            child: _buildCoin(couleurCoin, epaisseur, longueur,
                borderTop: true, borderLeft: true),
          ),
          // Coin haut-droit
          Positioned(
            top: 0, right: 0,
            child: _buildCoin(couleurCoin, epaisseur, longueur,
                borderTop: true, borderRight: true),
          ),
          // Coin bas-gauche
          Positioned(
            bottom: 0, left: 0,
            child: _buildCoin(couleurCoin, epaisseur, longueur,
                borderBottom: true, borderLeft: true),
          ),
          // Coin bas-droit
          Positioned(
            bottom: 0, right: 0,
            child: _buildCoin(couleurCoin, epaisseur, longueur,
                borderBottom: true, borderRight: true),
          ),
          // Ligne de scan animée
          const _LigneScanAnimee(),
        ],
      ),
    );
  }

  Widget _buildCoin(
      Color couleur, double epaisseur, double longueur, {
        bool borderTop    = false,
        bool borderBottom = false,
        bool borderLeft   = false,
        bool borderRight  = false,
      }) {
    return Container(
      width: longueur,
      height: longueur,
      decoration: BoxDecoration(
        border: Border(
          top:    borderTop    ? BorderSide(color: couleur, width: epaisseur) : BorderSide.none,
          bottom: borderBottom ? BorderSide(color: couleur, width: epaisseur) : BorderSide.none,
          left:   borderLeft   ? BorderSide(color: couleur, width: epaisseur) : BorderSide.none,
          right:  borderRight  ? BorderSide(color: couleur, width: epaisseur) : BorderSide.none,
        ),
      ),
    );
  }

  // ── Bandeau d'instructions en bas ─────────────────────────
  Widget _buildBandeauInstructions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner, color: Colors.white70, size: 28),
          const SizedBox(height: 10),
          const Text(
            'Pointez la caméra vers le code-barres',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'EAN-13 · EAN-8 · Code 128 · QR Code',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE : searching — Recherche Firestore en cours
  // ════════════════════════════════════════════════════════════
  Widget _buildEtapeSearching() {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      key: const ValueKey('searching'),
      color: AppColors.background(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(color: primary),
              ),
              const SizedBox(height: 28),
              Text(
                'Code détecté !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface(context),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _codeDetecte,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Recherche dans la base médicaments...',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE : found — Fiche médicament trouvé
  // ════════════════════════════════════════════════════════════
  Widget _buildEtapeFound() {
    final primary = Theme.of(context).colorScheme.primary;
    final med     = _medicamentTrouve!;

    final String nom         = med['name']        ?? 'Inconnu';
    final double prix        = (med['price']       ?? 0).toDouble();
    final int    stock       = (med['stock']       ?? 0) as int;
    final String description = med['description'] ?? '';
    final String categorie   = med['category']    ?? '';
    final String expiry      = med['expiryDate']  ?? '';
    final bool   stockCritique = stock < 5;

    return Container(
      key: const ValueKey('found'),
      color: AppColors.background(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bannière succès ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: green.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Médicament trouvé !',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: green,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Code : $_codeDetecte',
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Fiche médicament ───────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône + nom
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.medication,
                          color: primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nom,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface(context),
                              ),
                            ),
                            if (categorie.isNotEmpty)
                              Text(
                                categorie,
                                style: TextStyle(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(color: AppColors.border(context)),
                  const SizedBox(height: 16),

                  // Prix + Stock côte à côte
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTuile(
                          label: 'Prix',
                          valeur: '${prix.toStringAsFixed(2)} DT',
                          icone: Icons.payments_outlined,
                          couleur: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoTuile(
                          label: 'Stock',
                          valeur: '$stock unité${stock > 1 ? 's' : ''}',
                          icone: stockCritique
                              ? Icons.warning_amber
                              : Icons.inventory_2_outlined,
                          couleur: stockCritique ? red : green,
                        ),
                      ),
                    ],
                  ),

                  // Alerte stock critique
                  if (stockCritique) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: red.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: red.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              color: red, size: 16),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Stock critique — quantité limitée',
                              style: TextStyle(
                                  color: red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Description
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurface(context),
                        height: 1.5,
                      ),
                    ),
                  ],

                  // Date d'expiration
                  if (expiry.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.event_outlined,
                            size: 16,
                            color: AppColors.textSecondary(context)),
                        const SizedBox(width: 8),
                        Text(
                          'Expire le : $expiry',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Bouton Rescanner ───────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: const Text(
                  'Scanner un autre médicament',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _rescanner,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: Icon(Icons.home_outlined, color: primary),
                label: Text(
                  'Retour à l\'accueil',
                  style: TextStyle(color: primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Tuile info (prix / stock) ──────────────────────────────
  Widget _buildInfoTuile({
    required String   label,
    required String   valeur,
    required IconData icone,
    required Color    couleur,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icone, color: couleur, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Text(
                  valeur,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: couleur,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE : notFound — Code-barres non référencé
  // ════════════════════════════════════════════════════════════
  Widget _buildEtapeNotFound() {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      key: const ValueKey('notFound'),
      color: AppColors.background(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off,
                    color: amber, size: 44),
              ),
              const SizedBox(height: 24),
              Text(
                'Médicament non référencé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _codeDetecte,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: amber,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ce code-barres ne correspond à aucun\n'
                    'médicament dans notre base de données.',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 14,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner,
                      color: Colors.white),
                  label: const Text(
                    'Rescanner',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _rescanner,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.home_outlined, color: primary),
                  label: Text('Retour à l\'accueil',
                      style: TextStyle(color: primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE : error — Erreur caméra ou permission
  // ════════════════════════════════════════════════════════════
  Widget _buildEtapeError() {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      key: const ValueKey('error'),
      color: AppColors.background(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: red, size: 44),
              ),
              const SizedBox(height: 24),
              Text(
                'Caméra indisponible',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface(context),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _erreur.isNotEmpty
                    ? _erreur
                    : 'Vérifiez les permissions caméra\ndans les paramètres de l\'appareil.',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 14,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Réessayer',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    setState(() {
                      _etape             = 'scanning';
                      _cameraInitialisee = false;
                      _erreur            = '';
                    });
                    _initialiserCamera();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAINTER — Overlay sombre avec découpe centrale transparente
// ═══════════════════════════════════════════════════════════════
class _OverlayScannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    const double taille = 260;
    final double left   = (size.width  - taille) / 2;
    final double top    = (size.height - taille) / 2;
    final Rect   decoupe = Rect.fromLTWH(left, top, taille, taille);

    // Zone sombre complète moins la découpe centrale
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(decoupe, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// WIDGET — Ligne de scan animée dans le viseur
// ═══════════════════════════════════════════════════════════════
class _LigneScanAnimee extends StatefulWidget {
  const _LigneScanAnimee();

  @override
  State<_LigneScanAnimee> createState() => _LigneScanAnimeeState();
}

class _LigneScanAnimeeState extends State<_LigneScanAnimee>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double>   _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: _animation.value * 240,
          left: 10,
          right: 10,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.green.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}