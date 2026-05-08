import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pharma_ai/core/l10n/app_localizations.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';
import 'package:pharma_ai/core/services/vibration_service.dart';
import 'package:pharma_ai/core/services/sound_service.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  static const Color _couleurPrimaire   = Color(0xFF1565C0);
  static const Color _couleurSuccess    = Color(0xFF2E7D32);
  static const Color _couleurWarning    = Color(0xFFF9A825);
  static const Color _couleurDanger     = Color(0xFFC62828);
  final _vibration = VibrationService();
  final _sound     = SoundService();

  static const List<String> _categories = [
    'Antibiotique', 'Antidouleur', 'Anti-inflammatoire',
    'Antihistaminique', 'Antihypertenseur', 'Antidiabétique',
    'Antidépresseur', 'Anxiolytique', 'Cardiovasculaire',
    'Dermatologie', 'Gastro-entérologie', 'Gynécologie',
    'Ophtalmologie', 'Pédiatrie', 'Pneumologie',
    'Vitamines & Compléments', 'Autre',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteMedication(
      String docId, String name, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.delete),
        content: Text('$name ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _couleurDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('medications')
            .doc(docId)
            .delete();

        await Future.wait([_sound.playError(), _vibration.error()]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$name" supprimé'),
              backgroundColor: _couleurSuccess,
            ),
          );
        }
      } catch (e) {
        await Future.wait([_sound.playError(), _vibration.error()]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur suppression : $e'),
              backgroundColor: _couleurDanger,
            ),
          );
        }
      }
    }
  }

  void _openMedicationForm({DocumentSnapshot? doc}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MedicationForm(
        doc: doc,
        categories: _categories,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          l10n.medications,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.addMedication,
            onPressed: () => _openMedicationForm(),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchMedication,
                prefixIcon: Icon(Icons.search,
                    color: Theme.of(context).colorScheme.primary),
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
                fillColor: AppColors.inputFill(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: AppColors.border(context)),
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medications')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 64,
                            color: AppColors.textSecondary(context)),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? l10n.medications
                              : '${l10n.searchMedication} : $_searchQuery',
                          style: TextStyle(
                              color: AppColors.textSecondary(context)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc  = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final int stock       = data['stock'] ?? 0;
                    final bool isCritical = stock <= 5;

                    String expiryText = 'N/A';
                    if (data['expiryDate'] != null) {
                      try {
                        final ts = data['expiryDate'] as Timestamp;
                        expiryText =
                            DateFormat('dd/MM/yyyy').format(ts.toDate());
                      } catch (_) {}
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: AppColors.surface(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isCritical
                            ? const BorderSide(
                            color: _couleurWarning, width: 1.5)
                            : BorderSide.none,
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isCritical
                              ? _couleurWarning.withValues(alpha: 0.15)
                              : _couleurPrimaire.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.medication,
                            color: isCritical
                                ? _couleurWarning
                                : _couleurPrimaire,
                          ),
                        ),
                        title: Text(
                          data['name'] ?? 'Inconnu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.onSurface(context),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.category_outlined,
                                    size: 13,
                                    color: AppColors.textSecondary(context)),
                                const SizedBox(width: 4),
                                Text(
                                  data['category'] ?? 'Non défini',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary(context)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.event_outlined,
                                    size: 13,
                                    color: AppColors.textSecondary(context)),
                                const SizedBox(width: 4),
                                Text(
                                  'Exp : $expiryText',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary(context)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  isCritical
                                      ? Icons.warning_amber_rounded
                                      : Icons.inventory_2_outlined,
                                  size: 13,
                                  color: isCritical
                                      ? _couleurWarning
                                      : AppColors.textSecondary(context),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.stockUnits(stock),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCritical
                                        ? _couleurWarning
                                        : AppColors.textSecondary(context),
                                    fontWeight: isCritical
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${data['price'] ?? 0} DZD',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _openMedicationForm(doc: doc),
                                  child: Icon(Icons.edit_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => _deleteMedication(
                                      doc.id, data['name'] ?? '', l10n),
                                  child: const Icon(Icons.delete_outline,
                                      color: _couleurDanger, size: 20),
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

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMedicationForm(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(l10n.add,
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
class _MedicationForm extends StatefulWidget {
  final DocumentSnapshot? doc;
  final List<String>      categories;

  const _MedicationForm({this.doc, required this.categories});

  @override
  State<_MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<_MedicationForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;

  String?   _selectedCategory;
  DateTime? _selectedExpiryDate;
  bool      _isLoading = false;
  final _vibration = VibrationService();
  final _sound     = SoundService();

  static const Color _couleurDanger  = Color(0xFFC62828);
  static const Color _couleurSuccess = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    if (widget.doc != null) {
      final data = widget.doc!.data() as Map<String, dynamic>;
      _nameController        = TextEditingController(text: data['name'] ?? '');
      _priceController       = TextEditingController(
          text: (data['price'] ?? '').toString());
      _stockController       = TextEditingController(
          text: (data['stock'] ?? '').toString());
      _descriptionController = TextEditingController(
          text: data['description'] ?? '');
      _selectedCategory = data['category'];
      if (data['expiryDate'] != null) {
        try {
          _selectedExpiryDate = (data['expiryDate'] as Timestamp).toDate();
        } catch (_) {}
      }
    } else {
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

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 20),
      helpText: "Date d'expiration",
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedExpiryDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      await Future.wait([_sound.playError(), _vibration.error()]);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> data = {
        'name'       : _nameController.text.trim(),
        'category'   : _selectedCategory ?? 'Autre',
        'price'      : double.tryParse(_priceController.text.trim()) ?? 0,
        'stock'      : int.tryParse(_stockController.text.trim()) ?? 0,
        'description': _descriptionController.text.trim(),
        'expiryDate' : _selectedExpiryDate != null
            ? Timestamp.fromDate(_selectedExpiryDate!)
            : null,
        'updatedAt'  : FieldValue.serverTimestamp(),
      };

      if (widget.doc == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('medications').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('medications')
            .doc(widget.doc!.id)
            .update(data);
      }
      await Future.wait([_sound.playSuccess(), _vibration.success()]);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.doc == null
                ? l10n.addMedication
                : l10n.editMedication),
            backgroundColor: _couleurSuccess,
          ),
        );
      }
    } catch (e) {
      await Future.wait([_sound.playError(), _vibration.error()]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: _couleurDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n          = AppLocalizations.of(context)!;
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

              Center(
                child: Text(
                  widget.doc == null
                      ? l10n.addMedication
                      : l10n.editMedication,
                  style: TextStyle(
                    fontSize  : 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel(context, l10n.medicationName),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                    context, 'Ex : Paracétamol 500mg', Icons.medication),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Champ requis'
                    : null,
              ),
              const SizedBox(height: 16),

              _buildLabel(context, l10n.category),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration(
                    context, l10n.category, Icons.category_outlined),
                items: widget.categories
                    .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedCategory = val),
                validator: (val) =>
                val == null ? 'Veuillez choisir une catégorie' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, l10n.price),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                              context, '0.00', Icons.attach_money),
                          validator: (val) =>
                          (val == null || val.trim().isEmpty)
                              ? 'Requis'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, l10n.stock),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                              context, '0', Icons.inventory_2),
                          validator: (val) =>
                          (val == null || val.trim().isEmpty)
                              ? 'Requis'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabel(context, "Date d'expiration"),
              InkWell(
                onTap: _pickExpiryDate,
                child: InputDecorator(
                  decoration: _inputDecoration(
                      context,
                      "Choisir une date",
                      Icons.calendar_today_outlined),
                  child: Text(
                    _selectedExpiryDate == null
                        ? "Aucune date sélectionnée"
                        : DateFormat('dd / MM / yyyy')
                        .format(_selectedExpiryDate!),
                    style: TextStyle(
                      color: _selectedExpiryDate == null
                          ? AppColors.textSecondary(context)
                          : AppColors.onSurface(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel(context, 'Description'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration(
                    context,
                    'Posologie, indications...',
                    Icons.notes_outlined),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width : double.infinity,
                height: 52,
                child : ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 22,
                    width : 22,
                    child : CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                      : Text(
                    widget.doc == null ? l10n.add : l10n.save,
                    style: const TextStyle(
                        fontSize  : 16,
                        fontWeight: FontWeight.bold,
                        color     : Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize  : 13,
          color: AppColors.onSurface(context),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      BuildContext context, String hint, IconData icon) {
    return InputDecoration(
      hintText  : hint,
      hintStyle : TextStyle(color: AppColors.textSecondary(context)),
      prefixIcon: Icon(icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20),
      filled    : true,
      fillColor : AppColors.inputFill(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide  : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _couleurDanger),
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
    );
  }
}