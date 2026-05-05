// lib/features/client/ocr/ocr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

// ═══════════════════════════════════════════════════════════════
// OcrScannerScreen — Scanner d'ordonnance avec ML Kit OCR
//
// Fonctionnement :
//   1. L'utilisateur prend une photo OU importe depuis la galerie
//   2. ML Kit extrait le texte de l'image
//   3. On détecte automatiquement les médicaments dans le texte
//   4. L'ordonnance est envoyée dans Firestore (status: 'pending')
//   5. L'admin peut ensuite la valider ou rejeter
// ═══════════════════════════════════════════════════════════════

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  // ── Couleurs ───────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color green       = Color(0xFF2E7D32);
  static const Color amber       = Color(0xFFF9A825);
  static const Color red         = Color(0xFFC62828);
  static const Color background  = Color(0xFFF5F7FA);

  // ── État de l'écran ────────────────────────────────────────
  // 'initial'    → page d'accueil (aucune image)
  // 'processing' → OCR en cours
  // 'result'     → texte extrait, prêt à envoyer
  // 'sending'    → envoi Firestore en cours
  // 'done'       → envoi réussi
  String _etape = 'initial';

  File?   _imageFile;          // Image sélectionnée
  String  _texteExtrait  = ''; // Texte brut OCR
  List<String> _medsDetectes = []; // Médicaments détectés
  String  _erreur = '';        // Message d'erreur éventuel

  // ── Contrôleur du texte (éditable par l'utilisateur) ──────
  final TextEditingController _texteController = TextEditingController();

  // ── Mots-clés pour détecter les médicaments dans le texte ─
  // Liste simple — peut être enrichie
  static const List<String> _motsClesMedicaments = [
    'mg', 'ml', 'cp', 'gel', 'comp', 'gél', 'sirop', 'injectable',
    'solution', 'pommade', 'crème', 'patch', 'suppositoire',
    'amoxicilline', 'paracétamol', 'ibuprofène', 'aspirine',
    'doliprane', 'efferalgan', 'augmentin', 'amoxil',
    'metformine', 'oméprazole', 'atorvastatine', 'metoprolol',
  ];

  @override
  void dispose() {
    _texteController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE 1 — Prendre une photo avec la caméra
  // ════════════════════════════════════════════════════════════
  Future<void> _prendrePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // bonne qualité sans trop alourdir
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile == null) return; // annulé par l'utilisateur

      setState(() {
        _imageFile = File(pickedFile.path);
        _etape     = 'processing';
        _erreur    = '';
      });

      await _extraireTexte();
    } catch (e) {
      setState(() {
        _erreur = 'Erreur caméra : $e';
        _etape  = 'initial';
      });
    }
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE 1 (bis) — Importer depuis la galerie
  // ════════════════════════════════════════════════════════════
  Future<void> _importerGalerie() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
        _etape     = 'processing';
        _erreur    = '';
      });

      await _extraireTexte();
    } catch (e) {
      setState(() {
        _erreur = 'Erreur galerie : $e';
        _etape  = 'initial';
      });
    }
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE 2 — Extraire le texte avec ML Kit OCR
  // ════════════════════════════════════════════════════════════
  Future<void> _extraireTexte() async {
    if (_imageFile == null) return;

    try {
      // Créer l'objet InputImage depuis le fichier
      final inputImage = InputImage.fromFile(_imageFile!);

      // Initialiser le reconnaisseur de texte (Latin = Fr/En)
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      // Lancer la reconnaissance
      final RecognizedText recognized =
      await textRecognizer.processImage(inputImage);

      // Fermer le reconnaisseur pour libérer la mémoire
      await textRecognizer.close();

      // Récupérer le texte brut
      final texte = recognized.text.trim();

      if (texte.isEmpty) {
        setState(() {
          _erreur = 'Aucun texte détecté. Essayez avec une image plus nette.';
          _etape  = 'initial';
        });
        return;
      }

      // Détecter les médicaments dans le texte
      final meds = _detecterMedicaments(texte);

      setState(() {
        _texteExtrait  = texte;
        _medsDetectes  = meds;
        _etape         = 'result';
        _texteController.text = texte; // afficher dans le champ éditable
      });
    } catch (e) {
      setState(() {
        _erreur = 'Erreur OCR : $e';
        _etape  = 'initial';
      });
    }
  }

  // ════════════════════════════════════════════════════════════
  // Détecter les médicaments dans le texte extrait
  // Logique simple : cherche les lignes contenant des mots-clés
  // ════════════════════════════════════════════════════════════
  List<String> _detecterMedicaments(String texte) {
    final lignes = texte.split('\n');
    final List<String> meds = [];

    for (final ligne in lignes) {
      final ligneLower = ligne.toLowerCase().trim();
      if (ligneLower.isEmpty) continue;

      // Vérifier si la ligne contient un mot-clé médicament
      final contientMotCle = _motsClesMedicaments.any(
            (mot) => ligneLower.contains(mot.toLowerCase()),
      );

      if (contientMotCle && ligne.trim().length > 3) {
        meds.add(ligne.trim());
      }
    }

    // Dédoublonner
    return meds.toSet().toList();
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE 3 — Envoyer l'ordonnance dans Firestore
  // ════════════════════════════════════════════════════════════
  Future<void> _envoyerOrdonnance() async {
    final texteEdite = _texteController.text.trim();
    if (texteEdite.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le texte de l\'ordonnance est vide.'),
          backgroundColor: red,
        ),
      );
      return;
    }

    setState(() => _etape = 'sending');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Récupérer le nom du client depuis Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Client';

      // Ré-détecter les médicaments sur le texte édité
      final medsFinaux = _detecterMedicaments(texteEdite);

      // Enregistrer dans Firestore
      await FirebaseFirestore.instance.collection('ordonnances').add({
        'userId'        : user.uid,
        'userName'      : userName,
        'extractedText' : texteEdite,
        'medicines'     : medsFinaux,
        'status'        : 'pending',    // en attente de validation admin
        'createdAt'     : FieldValue.serverTimestamp(),
        'validatedAt'   : null,
      });

      setState(() => _etape = 'done');
    } catch (e) {
      setState(() {
        _erreur = 'Erreur envoi : $e';
        _etape  = 'result'; // revenir à l'étape résultat
      });
    }
  }

  // ════════════════════════════════════════════════════════════
  // Recommencer (reset complet)
  // ════════════════════════════════════════════════════════════
  void _recommencer() {
    setState(() {
      _etape         = 'initial';
      _imageFile     = null;
      _texteExtrait  = '';
      _medsDetectes  = [];
      _erreur        = '';
      _texteController.clear();
    });
  }

  // ════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Scanner une ordonnance',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContenu(),
      ),
    );
  }

  // Choisir le bon widget selon l'étape
  Widget _buildContenu() {
    switch (_etape) {
      case 'processing':
        return _buildEtapeProcessing();
      case 'result':
        return _buildEtapeResult();
      case 'sending':
        return _buildEtapeSending();
      case 'done':
        return _buildEtapeDone();
      default:
        return _buildEtapeInitial();
    }
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE : initial — Choix de la source image
  // ════════════════════════════════════════════════════════════
  Widget _buildEtapeInitial() {
    return SingleChildScrollView(
      key: const ValueKey('initial'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Illustration centrale
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Icône principale
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.document_scanner_outlined,
                    color: primaryBlue,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Scanner votre ordonnance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Prenez une photo claire de votre ordonnance '
                      'ou importez-la depuis la galerie.\n'
                      'Le texte sera extrait automatiquement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Bouton : Prendre une photo
          _buildBoutonAction(
            label: 'Prendre une photo',
            sousTitre: 'Utiliser l\'appareil photo',
            icone: Icons.camera_alt_outlined,
            couleur: primaryBlue,
            onTap: _prendrePhoto,
          ),

          const SizedBox(height: 14),

          // Bouton : Importer depuis la galerie
          _buildBoutonAction(
            label: 'Importer depuis la galerie',
            sousTitre: 'Choisir une image existante',
            icone: Icons.photo_library_outlined,
            couleur: green,
            onTap: _importerGalerie,
          ),

          // Message d'erreur
          if (_erreur.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: red.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _erreur,
                      style: const TextStyle(color: red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Conseils pour une bonne photo
          _buildConseils(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE : processing — OCR en cours
  // ════════════════════════════════════════════════════════════
  Widget _buildEtapeProcessing() {
    return Center(
      key: const ValueKey('processing'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Aperçu de l'image
          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _imageFile!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: primaryBlue),
          const SizedBox(height: 20),
          const Text(
            'Analyse en cours...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ML Kit extrait le texte de votre ordonnance',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE : result — Texte extrait, vérification avant envoi
  // ════════════════════════════════════════════════════════════
  Widget _buildEtapeResult() {
    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Aperçu image + succès ──────────────────────────
          Row(
            children: [
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Texte extrait avec succès',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: green,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vérifiez et corrigez si nécessaire',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Médicaments détectés ───────────────────────────
          if (_medsDetectes.isNotEmpty) ...[
            _buildSectionTitre(
              '💊 Médicaments détectés (${_medsDetectes.length})',
              couleur: primaryBlue,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _medsDetectes
                  .map((med) => Chip(
                label: Text(
                  med.length > 30
                      ? '${med.substring(0, 30)}...'
                      : med,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor:
                primaryBlue.withOpacity(0.08),
                side: BorderSide(
                    color: primaryBlue.withOpacity(0.2)),
                avatar: const Icon(Icons.medication,
                    size: 14, color: primaryBlue),
              ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ] else ...[
            // Pas de médicament détecté
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aucun médicament automatiquement détecté. '
                          'Vérifiez le texte ci-dessous.',
                      style: TextStyle(
                          color: Colors.grey[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Texte extrait (éditable) ───────────────────────
          _buildSectionTitre('📄 Texte extrait (modifiable)'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _texteController,
              maxLines: 10,
              style: const TextStyle(fontSize: 13, height: 1.6),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
                hintText: 'Le texte extrait apparaît ici...',
              ),
            ),
          ),

          // Erreur éventuelle
          if (_erreur.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_erreur,
                style: const TextStyle(color: red, fontSize: 13)),
          ],

          const SizedBox(height: 24),

          // ── Boutons : Envoyer + Recommencer ───────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send_outlined, color: Colors.white),
              label: const Text(
                'Envoyer à la pharmacie',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _envoyerOrdonnance,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh, color: primaryBlue),
              label: const Text(
                'Recommencer',
                style: TextStyle(color: primaryBlue),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryBlue),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _recommencer,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE : sending — Envoi en cours
  // ════════════════════════════════════════════════════════════
  Widget _buildEtapeSending() {
    return Center(
      key: const ValueKey('sending'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: primaryBlue),
          const SizedBox(height: 20),
          const Text(
            'Envoi en cours...',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlue),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre ordonnance est envoyée au pharmacien',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ÉTAPE : done — Succès final
  // ════════════════════════════════════════════════════════════
  Widget _buildEtapeDone() {
    return Center(
      key: const ValueKey('done'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône succès animée (simple)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: green,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ordonnance envoyée !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Votre ordonnance a été transmise au pharmacien.\n'
                  'Vous serez notifié dès qu\'elle est traitée.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            // Bouton : Scanner une autre
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.document_scanner_outlined,
                    color: Colors.white),
                label: const Text(
                  'Scanner une autre ordonnance',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _recommencer,
              ),
            ),
            const SizedBox(height: 14),
            // Bouton : Retour accueil
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon:
                const Icon(Icons.home_outlined, color: primaryBlue),
                label: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(color: primaryBlue),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryBlue),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Widgets helpers
  // ════════════════════════════════════════════════════════════

  // Bouton d'action (caméra / galerie)
  Widget _buildBoutonAction({
    required String label,
    required String sousTitre,
    required IconData icone,
    required Color couleur,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: couleur.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: couleur.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: couleur, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    sousTitre,
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  // Titre de section
  Widget _buildSectionTitre(String titre, {Color couleur = const Color(0xFF1A1A2E)}) {
    return Text(
      titre,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: couleur,
      ),
    );
  }

  // Conseils pour une bonne photo
  Widget _buildConseils() {
    final conseils = [
      '📸  Bonne luminosité, pas de reflet',
      '📄  Ordonnance à plat, bien cadrée',
      '🔍  Texte net et lisible',
      '✂️  Évitez de couper les bords',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: amber.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: amber.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conseils pour un bon scan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          ...conseils.map(
                (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                c,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}