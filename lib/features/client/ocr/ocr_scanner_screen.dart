import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';
import 'package:pharma_ai/core/services/sound_service.dart';
import 'package:pharma_ai/core/services/vibration_service.dart';
import 'dart:io';



class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  static const Color green = Color(0xFF2E7D32);
  static const Color amber = Color(0xFFF9A825);
  static const Color red   = Color(0xFFC62828);

  final _sound     = SoundService();
  final _vibration = VibrationService();

  String _etape = 'initial';

  File?        _imageFile;
  String       _texteExtrait  = '';
  List<String> _medsDetectes = [];
  String       _erreur = '';

  final TextEditingController _texteController = TextEditingController();

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

  Future<void> _prendrePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
        _etape     = 'processing';
        _erreur    = '';
      });

      await _extraireTexte();
    } catch (e) {
      await _vibration.error();
      await _sound.playError();
      setState(() {
        _erreur = 'Erreur caméra : $e';
        _etape  = 'initial';
      });
    }
  }

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
      await _vibration.error();
      await _sound.playError();

      setState(() {
        _erreur = 'Erreur galerie : $e';
        _etape  = 'initial';
      });
    }
  }

  Future<void> _extraireTexte() async {
    if (_imageFile == null) return;

    try {
      final inputImage = InputImage.fromFile(_imageFile!);

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      final RecognizedText recognized =
      await textRecognizer.processImage(inputImage);

      await textRecognizer.close();

      final texte = recognized.text.trim();

      if (texte.isEmpty) {
        await _vibration.error();
        await _sound.playError();
        setState(() {
          _erreur = 'Aucun texte détecté. Essayez avec une image plus nette.';
          _etape  = 'initial';
        });
        return;
      }

      final meds = _detecterMedicaments(texte);
      await _vibration.scanFeedback();
      await _sound.playScanBeep();
      await Future.delayed(const Duration(milliseconds: 300));
      await _vibration.success();
      await _sound.playSuccess();
      setState(() {
        _texteExtrait         = texte;
        _medsDetectes         = meds;
        _etape                = 'result';
        _texteController.text = texte;
      });
    } catch (e) {
      await _vibration.error();
      await _sound.playError();
      setState(() {
        _erreur = 'Erreur OCR : $e';
        _etape  = 'initial';
      });
    }
  }


  List<String> _detecterMedicaments(String texte) {
    final lignes = texte.split('\n');
    final List<String> meds = [];

    for (final ligne in lignes) {
      final ligneLower = ligne.toLowerCase().trim();
      if (ligneLower.isEmpty) continue;

      final contientMotCle = _motsClesMedicaments.any(
            (mot) => ligneLower.contains(mot.toLowerCase()),
      );

      if (contientMotCle && ligne.trim().length > 3) {
        meds.add(ligne.trim());
      }
    }

    return meds.toSet().toList();
  }

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

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Client';

      final medsFinaux = _detecterMedicaments(texteEdite);

      await FirebaseFirestore.instance.collection('ordonnances').add({
        'userId'        : user.uid,
        'userName'      : userName,
        'extractedText' : texteEdite,
        'medicines'     : medsFinaux,
        'status'        : 'pending',
        'createdAt'     : FieldValue.serverTimestamp(),
        'validatedAt'   : null,
      });

      setState(() => _etape = 'done');
      await Future.wait([_sound.playSuccess(), _vibration.success()]);
    } catch (e) {
      await Future.wait([_sound.playError(), _vibration.error()]);
      setState(() {
        _erreur = 'Erreur envoi : $e';
        _etape  = 'result';
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text(
          'Scanner une ordonnance',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContenu(),
      ),
    );
  }

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

  Widget _buildEtapeInitial() {
    final primary = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      key: const ValueKey('initial'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.document_scanner_outlined,
                    color: primary,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Scanner votre ordonnance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Prenez une photo claire de votre ordonnance '
                      'ou importez-la depuis la galerie.\n'
                      'Le texte sera extrait automatiquement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          _buildBoutonAction(
            label: 'Prendre une photo',
            sousTitre: 'Utiliser l\'appareil photo',
            icone: Icons.camera_alt_outlined,
            couleur: primary,
            onTap: _prendrePhoto,
          ),

          const SizedBox(height: 14),

          _buildBoutonAction(
            label: 'Importer depuis la galerie',
            sousTitre: 'Choisir une image existante',
            icone: Icons.photo_library_outlined,
            couleur: green,
            onTap: _importerGalerie,
          ),

          if (_erreur.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: red.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: red.withValues(alpha: 0.3)),
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

          _buildConseils(),
        ],
      ),
    );
  }

  Widget _buildEtapeProcessing() {
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      key: const ValueKey('processing'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          CircularProgressIndicator(color: primary),
          const SizedBox(height: 20),
          Text(
            'Analyse en cours...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ML Kit extrait le texte de votre ordonnance',
            style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeResult() {
    final primary = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          color: AppColors.textSecondary(context), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_medsDetectes.isNotEmpty) ...[
            _buildSectionTitre(
              ' Médicaments détectés (${_medsDetectes.length})',
              couleur: primary,
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
                backgroundColor: primary.withValues(alpha: 0.08),
                side: BorderSide(color: primary.withValues(alpha: 0.2)),
                avatar: Icon(Icons.medication,
                    size: 14, color: primary),
              ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: amber.withValues(alpha: 0.3)),
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
                          color: AppColors.textSecondary(context), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          _buildSectionTitre(' Texte extrait (modifiable)'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputFill(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
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

          if (_erreur.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_erreur,
                style: const TextStyle(color: red, fontSize: 13)),
          ],

          const SizedBox(height: 24),

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
                backgroundColor: primary,
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
              icon: Icon(Icons.refresh, color: primary),
              label: Text(
                'Recommencer',
                style: TextStyle(color: primary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primary),
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

  Widget _buildEtapeSending() {
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      key: const ValueKey('sending'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primary),
          const SizedBox(height: 20),
          Text(
            'Envoi en cours...',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre ordonnance est envoyée au pharmacien',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeDone() {
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      key: const ValueKey('done'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: green,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ordonnance envoyée !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Votre ordonnance a été transmise au pharmacien.\n'
                  'Vous serez notifié dès qu\'elle est traitée.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
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
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _recommencer,
              ),
            ),
            const SizedBox(height: 14),
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
          ],
        ),
      ),
    );
  }


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
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: couleur.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: couleur.withValues(alpha: 0.07),
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
                color: couleur.withValues(alpha: 0.1),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.onSurface(context),
                    ),
                  ),
                  Text(
                    sousTitre,
                    style: TextStyle(
                        color: AppColors.textSecondary(context), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.border(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitre(String titre, {Color? couleur}) {
    return Text(
      titre,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: couleur ?? AppColors.onSurface(context),
      ),
    );
  }

  Widget _buildConseils() {
    final conseils = [
      ' Bonne luminosité, pas de reflet',
      ' Ordonnance à plat, bien cadrée',
      ' Texte net et lisible',
      ' Évitez de couper les bords',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: amber.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conseils pour un bon scan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.onSurface(context),
            ),
          ),
          const SizedBox(height: 10),
          ...conseils.map(
                (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                c,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}