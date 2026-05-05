import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════
// ReminderScreen — Rappels de prise de médicaments
//
// Le client peut :
//   - Voir tous ses rappels actifs/inactifs
//   - Ajouter un nouveau rappel (médicament + heure + fréquence)
//   - Activer / désactiver un rappel
//   - Supprimer un rappel
// ═══════════════════════════════════════════════════════════════

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  // ── Couleurs ───────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color green       = Color(0xFF2E7D32);
  static const Color amber       = Color(0xFFF9A825);
  static const Color red         = Color(0xFFC62828);
  static const Color background  = Color(0xFFF5F7FA);

  // UID du client connecté
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Mes Rappels',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      // ── Liste en temps réel ────────────────────────────────
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reminders')
            .where('userId', isEqualTo: _uid)
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: primaryBlue));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Une erreur est survenue.'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEtatVide();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc  = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildCarteRappel(doc.id, data);
            },
          );
        },
      ),
      // ── Bouton flottant : Ajouter ──────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirFormulaire,
        backgroundColor: primaryBlue,
        icon: const Icon(Icons.add_alarm, color: Colors.white),
        label: const Text(
          'Ajouter un rappel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Carte d'un rappel
  // ════════════════════════════════════════════════════════════
  Widget _buildCarteRappel(String docId, Map<String, dynamic> data) {
    final nomMed    = data['medicationName'] ?? 'Médicament';
    final heure     = data['time'] ?? '08:00';
    final frequence = data['frequency'] ?? 'daily';
    final actif     = data['active'] ?? true;
    final dose      = data['dose'] ?? '';
    final notes     = data['notes'] ?? '';

    return AnimatedOpacity(
      opacity: actif ? 1.0 : 0.55,
      duration: const Duration(milliseconds: 300),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: actif
                ? primaryBlue.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        elevation: actif ? 2 : 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ligne principale : nom + toggle ───────────
              Row(
                children: [
                  // Icône médicament
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: actif
                          ? primaryBlue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medication_outlined,
                      color: actif ? primaryBlue : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nom + fréquence
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomMed,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: actif
                                ? const Color(0xFF1A1A2E)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 13,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _labelFrequence(frequence),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (dose.isNotEmpty) ...[
                              Text(
                                '  •  $dose',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Switch activer/désactiver
                  Switch(
                    value: actif,
                    activeColor: primaryBlue,
                    onChanged: (val) => _toggleActif(docId, val),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Heure du rappel ────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: actif
                      ? primaryBlue.withOpacity(0.06)
                      : background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: actif ? primaryBlue : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      heure,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: actif ? primaryBlue : Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Notes ──────────────────────────────────────
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.notes, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // ── Boutons : Modifier + Supprimer ─────────────
              Row(
                children: [
                  // Modifier
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined,
                          size: 16, color: primaryBlue),
                      label: const Text('Modifier',
                          style: TextStyle(
                              color: primaryBlue, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side:
                        const BorderSide(color: primaryBlue),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () =>
                          _ouvrirFormulaire(docId: docId, data: data),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Supprimer
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: red),
                      label: const Text('Supprimer',
                          style:
                          TextStyle(color: red, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () =>
                          _supprimerRappel(docId, nomMed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // État vide
  // ════════════════════════════════════════════════════════════
  Widget _buildEtatVide() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.alarm_outlined,
                  size: 44, color: primaryBlue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun rappel configuré',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ajoutez vos rappels pour ne jamais\n'
                  'oublier de prendre vos médicaments.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_alarm, color: Colors.white),
              label: const Text('Ajouter un rappel',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _ouvrirFormulaire,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Activer / désactiver un rappel
  // ════════════════════════════════════════════════════════════
  Future<void> _toggleActif(String docId, bool nouvelleValeur) async {
    await FirebaseFirestore.instance
        .collection('reminders')
        .doc(docId)
        .update({'active': nouvelleValeur});
  }

  // ════════════════════════════════════════════════════════════
  // Supprimer un rappel avec confirmation
  // ════════════════════════════════════════════════════════════
  Future<void> _supprimerRappel(String docId, String nom) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le rappel'),
        content: Text('Supprimer le rappel pour "$nom" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirme == true) {
      await FirebaseFirestore.instance
          .collection('reminders')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rappel "$nom" supprimé'),
            backgroundColor: red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // Ouvrir le formulaire (ajout ou modification)
  // ════════════════════════════════════════════════════════════
  void _ouvrirFormulaire(
      {String? docId, Map<String, dynamic>? data}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _FormulaireRappel(
        uid: _uid,
        docId: docId,
        data: data,
      ),
    );
  }

  // ── Helper : label fréquence ───────────────────────────────
  String _labelFrequence(String freq) {
    switch (freq) {
      case 'daily':    return 'Chaque jour';
      case 'twice':    return '2 fois par jour';
      case 'thrice':   return '3 fois par jour';
      case 'weekly':   return 'Chaque semaine';
      case 'asNeeded': return 'Si besoin';
      default:         return freq;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// FORMULAIRE AJOUTER / MODIFIER UN RAPPEL
// ═══════════════════════════════════════════════════════════════
class _FormulaireRappel extends StatefulWidget {
  final String uid;
  final String? docId;
  final Map<String, dynamic>? data;

  const _FormulaireRappel({
    required this.uid,
    this.docId,
    this.data,
  });

  @override
  State<_FormulaireRappel> createState() => _FormulaireRappelState();
}

class _FormulaireRappelState extends State<_FormulaireRappel> {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color red         = Color(0xFFC62828);
  static const Color green       = Color(0xFF2E7D32);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _doseController;
  late TextEditingController _notesController;

  // Heure sélectionnée
  TimeOfDay _heureSelectionnee = const TimeOfDay(hour: 8, minute: 0);

  // Fréquence sélectionnée
  String _frequence = 'daily';

  bool _isLoading = false;

  // Options de fréquence
  final List<Map<String, String>> _frequences = [
    {'valeur': 'daily',    'label': 'Chaque jour'},
    {'valeur': 'twice',    'label': '2 fois par jour'},
    {'valeur': 'thrice',   'label': '3 fois par jour'},
    {'valeur': 'weekly',   'label': 'Chaque semaine'},
    {'valeur': 'asNeeded', 'label': 'Si besoin'},
  ];

  @override
  void initState() {
    super.initState();
    // Pré-remplir si modification
    final d = widget.data;
    _nomController   = TextEditingController(text: d?['medicationName'] ?? '');
    _doseController  = TextEditingController(text: d?['dose'] ?? '');
    _notesController = TextEditingController(text: d?['notes'] ?? '');
    _frequence       = d?['frequency'] ?? 'daily';

    // Parser l'heure existante "HH:mm"
    if (d?['time'] != null) {
      final parts = (d!['time'] as String).split(':');
      if (parts.length == 2) {
        _heureSelectionnee = TimeOfDay(
          hour:   int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Sélecteur d'heure ──────────────────────────────────────
  Future<void> _choisirHeure() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heureSelectionnee,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
          const ColorScheme.light(primary: primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _heureSelectionnee = picked);
    }
  }

  // ── Sauvegarder dans Firestore ─────────────────────────────
  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Formater l'heure en "HH:mm"
    final heureStr =
        '${_heureSelectionnee.hour.toString().padLeft(2, '0')}:'
        '${_heureSelectionnee.minute.toString().padLeft(2, '0')}';

    final Map<String, dynamic> donnees = {
      'userId'         : widget.uid,
      'medicationName' : _nomController.text.trim(),
      'dose'           : _doseController.text.trim(),
      'notes'          : _notesController.text.trim(),
      'time'           : heureStr,
      'frequency'      : _frequence,
      'active'         : true,
      'updatedAt'      : FieldValue.serverTimestamp(),
    };

    try {
      if (widget.docId == null) {
        // Ajout
        donnees['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('reminders')
            .add(donnees);
      } else {
        // Modification
        await FirebaseFirestore.instance
            .collection('reminders')
            .doc(widget.docId)
            .update(donnees);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.docId == null
                ? '✅ Rappel ajouté avec succès'
                : '✅ Rappel mis à jour'),
            backgroundColor: green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Titre ──────────────────────────────────────
              Center(
                child: Text(
                  widget.docId == null
                      ? '🔔 Nouveau rappel'
                      : '✏️ Modifier le rappel',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Nom du médicament ───────────────────────────
              _label('Nom du médicament *'),
              TextFormField(
                controller: _nomController,
                decoration: _inputDeco(
                    'Ex : Doliprane 500mg', Icons.medication_outlined),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Champ requis'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Dosage (optionnel) ──────────────────────────
              _label('Dosage (optionnel)'),
              TextFormField(
                controller: _doseController,
                decoration:
                _inputDeco('Ex : 1 comprimé', Icons.scale_outlined),
              ),
              const SizedBox(height: 16),

              // ── Heure du rappel ─────────────────────────────
              _label('Heure du rappel *'),
              GestureDetector(
                onTap: _choisirHeure,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: primaryBlue, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_heureSelectionnee.hour.toString().padLeft(2, '0')}:'
                            '${_heureSelectionnee.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Modifier',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Fréquence ───────────────────────────────────
              _label('Fréquence *'),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonFormField<String>(
                  value: _frequence,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    prefixIcon: Icon(Icons.repeat,
                        color: primaryBlue, size: 20),
                  ),
                  items: _frequences
                      .map((f) => DropdownMenuItem(
                    value: f['valeur'],
                    child: Text(f['label']!),
                  ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _frequence = val ?? 'daily'),
                ),
              ),
              const SizedBox(height: 16),

              // ── Notes ───────────────────────────────────────
              _label('Notes (optionnel)'),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: _inputDeco(
                    'Ex : Prendre après le repas',
                    Icons.notes_outlined),
              ),
              const SizedBox(height: 28),

              // ── Bouton Sauvegarder ──────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                      : Text(
                    widget.docId == null
                        ? 'Ajouter le rappel'
                        : 'Enregistrer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  Widget _label(String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texte,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Color(0xFF37474F),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icone) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icone, color: primaryBlue, size: 20),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}