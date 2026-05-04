
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  // Contrôleur de recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ─── Couleurs du thème ───────────────────────────────────────
  static const Color primaryColor   = Color(0xFF1565C0);
  static const Color secondaryColor = Color(0xFF2E7D32);
  static const Color alertColor     = Color(0xFFF9A825);
  static const Color dangerColor    = Color(0xFFC62828);
  static const Color bgColor        = Color(0xFFF5F7FA);

  // ─── Liste fixe des catégories ───────────────────────────────
  // Tu peux ajouter ou retirer des catégories ici facilement
  static const List<String> _categories = [
    'Antibiotique',
    'Antidouleur',
    'Anti-inflammatoire',
    'Antihistaminique',
    'Antihypertenseur',
    'Antidiabétique',
    'Antidépresseur',
    'Anxiolytique',
    'Cardiovasculaire',
    'Dermatologie',
    'Gastro-entérologie',
    'Gynécologie',
    'Ophtalmologie',
    'Pédiatrie',
    'Pneumologie',
    'Vitamines & Compléments',
    'Autre',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Supprimer un médicament ─────────────────────────────────
  Future<void> _deleteMedication(String docId, String name) async {
    // Demande confirmation avant suppression
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous supprimer "$name" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('medications')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$name" supprimé avec succès'),
            backgroundColor: secondaryColor,
          ),
        );
      }
    }
  }

  // ─── Ouvrir le formulaire Ajouter / Modifier ─────────────────
  void _openMedicationForm({DocumentSnapshot? doc}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // pour que le clavier ne cache pas le formulaire
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MedicationForm(
        doc: doc,
        categories: _categories,
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Médicaments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Bouton ajouter dans la barre
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Ajouter un médicament',
            onPressed: () => _openMedicationForm(),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Barre de recherche ──────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un médicament...',
                prefixIcon: const Icon(Icons.search, color: primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // ── Liste temps réel depuis Firestore ───────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medications')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                // Chargement
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                // Erreur
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur : ${snapshot.error}'),
                  );
                }

                // Filtrer par recherche
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                // Liste vide
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Aucun médicament enregistré'
                              : 'Aucun résultat pour "$_searchQuery"',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                // Afficher la liste
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc  = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final int stock = data['stock'] ?? 0;
                    final bool isCritical = stock <= 5;

                    // Formater la date d'expiration si elle existe
                    String expiryText = 'N/A';
                    if (data['expiryDate'] != null) {
                      try {
                        final ts = data['expiryDate'] as Timestamp;
                        expiryText = DateFormat('dd/MM/yyyy').format(ts.toDate());
                      } catch (_) {}
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isCritical
                            ? const BorderSide(color: alertColor, width: 1.5)
                            : BorderSide.none,
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),

                        // Icône avec couleur selon stock
                        leading: CircleAvatar(
                          backgroundColor: isCritical
                              ? alertColor.withOpacity(0.15)
                              : primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.medication,
                            color: isCritical ? alertColor : primaryColor,
                          ),
                        ),

                        // Nom + catégorie
                        title: Text(
                          data['name'] ?? 'Inconnu',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            // Catégorie
                            Row(
                              children: [
                                const Icon(Icons.category_outlined,
                                    size: 13, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  data['category'] ?? 'Non défini',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Date d'expiration
                            Row(
                              children: [
                                const Icon(Icons.event_outlined,
                                    size: 13, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Exp : $expiryText',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Stock
                            Row(
                              children: [
                                Icon(
                                  isCritical
                                      ? Icons.warning_amber_rounded
                                      : Icons.inventory_2_outlined,
                                  size: 13,
                                  color: isCritical ? alertColor : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Stock : $stock unités',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCritical
                                        ? alertColor
                                        : Colors.grey.shade600,
                                    fontWeight: isCritical
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Prix + boutons action
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${data['price'] ?? 0} DZD',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  fontSize: 13),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Modifier
                                InkWell(
                                  onTap: () => _openMedicationForm(doc: doc),
                                  child: const Icon(Icons.edit_outlined,
                                      color: primaryColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                // Supprimer
                                InkWell(
                                  onTap: () => _deleteMedication(
                                      doc.id, data['name'] ?? ''),
                                  child: const Icon(Icons.delete_outline,
                                      color: dangerColor, size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Bouton flottant pour ajouter
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMedicationForm(),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ================================================================
// FORMULAIRE AJOUTER / MODIFIER UN MÉDICAMENT
// ================================================================
class _MedicationForm extends StatefulWidget {
  final DocumentSnapshot? doc; // null = mode ajout, sinon mode modification
  final List<String> categories;

  const _MedicationForm({this.doc, required this.categories});

  @override
  State<_MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<_MedicationForm> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs des champs texte
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;

  // Catégorie sélectionnée dans la liste déroulante
  String? _selectedCategory;

  // Date d'expiration sélectionnée
  DateTime? _selectedExpiryDate;

  bool _isLoading = false;

  static const Color primaryColor = Color(0xFF1565C0);
  static const Color dangerColor  = Color(0xFFC62828);

  @override
  void initState() {
    super.initState();

    // Si on est en mode modification, on pré-remplit les champs
    if (widget.doc != null) {
      final data = widget.doc!.data() as Map<String, dynamic>;

      _nameController        = TextEditingController(text: data['name'] ?? '');
      _priceController       = TextEditingController(
          text: (data['price'] ?? '').toString());
      _stockController       = TextEditingController(
          text: (data['stock'] ?? '').toString());
      _descriptionController = TextEditingController(
          text: data['description'] ?? '');

      // Catégorie existante
      _selectedCategory = data['category'];

      // Date d'expiration existante
      if (data['expiryDate'] != null) {
        try {
          _selectedExpiryDate =
              (data['expiryDate'] as Timestamp).toDate();
        } catch (_) {}
      }
    } else {
      // Mode ajout : champs vides
      _nameController        = TextEditingController();
      _priceController       = TextEditingController();
      _stockController       = TextEditingController();
      _descriptionController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ─── Ouvrir le calendrier pour choisir la date d'expiration ──
  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? now,
      firstDate: now, // on ne peut pas choisir une date passée
      lastDate: DateTime(now.year + 20),
      helpText: "Date d'expiration",
      builder: (context, child) {
        // Appliquer la couleur du thème au calendrier
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedExpiryDate = picked);
    }
  }

  // ─── Sauvegarder dans Firestore ───────────────────────────────
  Future<void> _save() async {
    // Valider le formulaire
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Données à enregistrer
      // NOTER : le champ 'barcode' a été supprimé volontairement
      final Map<String, dynamic> data = {
        'name'        : _nameController.text.trim(),
        'category'    : _selectedCategory ?? 'Autre',
        'price'       : double.tryParse(_priceController.text.trim()) ?? 0,
        'stock'       : int.tryParse(_stockController.text.trim()) ?? 0,
        'description' : _descriptionController.text.trim(),
        // Date d'expiration convertie en Timestamp Firestore
        'expiryDate'  : _selectedExpiryDate != null
            ? Timestamp.fromDate(_selectedExpiryDate!)
            : null,
        'updatedAt'   : FieldValue.serverTimestamp(),
      };

      if (widget.doc == null) {
        // ── MODE AJOUT ──
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('medications').add(data);
      } else {
        // ── MODE MODIFICATION ──
        await FirebaseFirestore.instance
            .collection('medications')
            .doc(widget.doc!.id)
            .update(data);
      }

      if (mounted) {
        Navigator.pop(context); // Fermer le formulaire
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.doc == null
                ? 'Médicament ajouté avec succès ✓'
                : 'Médicament mis à jour avec succès ✓'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── BUILD DU FORMULAIRE ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // padding bottom pour éviter que le clavier cache le formulaire
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Titre du formulaire ─────────────────────────
              Center(
                child: Text(
                  widget.doc == null
                      ? 'Ajouter un médicament'
                      : 'Modifier le médicament',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Champ : Nom ─────────────────────────────────
              _buildLabel('Nom du médicament *'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                    'Ex : Paracétamol 500mg', Icons.medication),
                validator: (val) =>
                (val == null || val.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),

              // ── Champ : Catégorie (LISTE DÉROULANTE) ────────
              _buildLabel('Catégorie *'),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration('Sélectionner une catégorie',
                    Icons.category_outlined),
                // Générer les items depuis la liste fixe
                items: widget.categories
                    .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) =>
                val == null ? 'Veuillez choisir une catégorie' : null,
              ),
              const SizedBox(height: 16),

              // ── Champs Prix + Stock (sur la même ligne) ─────
              Row(
                children: [
                  // Prix
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Prix (DZD) *'),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration:
                          _inputDecoration('0.00', Icons.attach_money),
                          validator: (val) => (val == null || val.trim().isEmpty)
                              ? 'Requis'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stock
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Stock *'),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('0', Icons.inventory_2),
                          validator: (val) => (val == null || val.trim().isEmpty)
                              ? 'Requis'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Champ : Date d'expiration ───────────────────
              _buildLabel("Date d'expiration"),
              InkWell(
                onTap: _pickExpiryDate,
                child: InputDecorator(
                  decoration: _inputDecoration(
                      "Choisir une date", Icons.calendar_today_outlined),
                  child: Text(
                    _selectedExpiryDate == null
                        ? "Aucune date sélectionnée"
                        : DateFormat('dd / MM / yyyy')
                        .format(_selectedExpiryDate!),
                    style: TextStyle(
                      color: _selectedExpiryDate == null
                          ? Colors.grey.shade500
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Champ : Description ─────────────────────────
              _buildLabel('Description'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration(
                    'Posologie, indications...', Icons.notes_outlined),
              ),
              const SizedBox(height: 28),

              // ── Bouton Sauvegarder ──────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                      : Text(
                    widget.doc == null ? 'Ajouter' : 'Enregistrer',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helper : label de champ ───────────────────────────────────
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF37474F)),
      ),
    );
  }

  // ─── Helper : style commun pour tous les champs ────────────────
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: primaryColor, size: 20),
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
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dangerColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}