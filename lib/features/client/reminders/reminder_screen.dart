import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';
import 'package:pharma_ai/core/l10n/app_localizations.dart';
import 'package:pharma_ai/core/services/notification_service.dart';
import 'package:pharma_ai/core/services/sound_service.dart';
import 'package:pharma_ai/core/services/vibration_service.dart';


class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {

  static const Color red = Color(0xFFC62828);

  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  final NotificationService _notifService = NotificationService();

  final _sound     = SoundService();
  final _vibration = VibrationService();

  @override
  Widget build(BuildContext context) {
    final l10n    = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          l10n.myReminders,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reminders')
            .where('userId', isEqualTo: _uid)
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text(l10n.errorOccurred));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEtatVide(l10n);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc  = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildCarteRappel(doc.id, data, l10n);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirFormulaire,
        backgroundColor: primary,
        icon: const Icon(Icons.add_alarm, color: Colors.white),
        label: Text(
          l10n.addReminder,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCarteRappel(
      String docId, Map<String, dynamic> data, AppLocalizations l10n) {
    final primary   = Theme.of(context).colorScheme.primary;
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
        color: AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: actif
                ? primary.withValues(alpha: 0.2)
                : AppColors.border(context),
            width: 1.2,
          ),
        ),
        elevation: actif ? 2 : 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: actif
                          ? primary.withValues(alpha: 0.1)
                          : AppColors.border(context).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medication_outlined,
                      color: actif ? primary : AppColors.textSecondary(context),
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
                                ? AppColors.onSurface(context)
                                : AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 13,
                              color: AppColors.textSecondary(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _labelFrequence(frequence, l10n),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                            if (dose.isNotEmpty) ...[
                              Text(
                                '  •  $dose',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: actif,
                    activeColor: primary,
                    onChanged: (val) => _toggleActif(docId, val, data),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: actif
                      ? primary.withValues(alpha: 0.06)
                      : AppColors.background(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: actif ? primary : AppColors.textSecondary(context),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      heure,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: actif ? primary : AppColors.textSecondary(context),
                        letterSpacing: 1,
                      ),
                    ),
                    if (actif && frequence != 'asNeeded') ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_active,
                                size: 12, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 4),
                            Text(
                              l10n.notificationActive,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.notes,
                        size: 14, color: AppColors.textSecondary(context)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.edit_outlined,
                          size: 16, color: primary),
                      label: Text(l10n.edit,
                          style: TextStyle(
                              color: primary, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primary),
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
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: red),
                      label: Text(l10n.delete,
                          style: const TextStyle(color: red, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _supprimerRappel(docId, nomMed, l10n),
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


  Widget _buildEtatVide(AppLocalizations l10n) {
    final primary = Theme.of(context).colorScheme.primary;

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
                color: primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.alarm_outlined, size: 44, color: primary),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noReminders,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.noRemindersDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 14),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_alarm, color: Colors.white),
              label: Text(l10n.addReminder,
                  style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
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


  Future<void> _toggleActif(
      String docId, bool nouvelleValeur, Map<String, dynamic> data) async {
    try {

      await FirebaseFirestore.instance
          .collection('reminders')
          .doc(docId)
          .update({'active': nouvelleValeur});

      final notifId = NotificationService.generateId(docId);

      if (nouvelleValeur) {

        await _planifierNotification(
          docId      : docId,
          nomMed     : data['medicationName'] ?? '',
          heureStr   : data['time'] ?? '08:00',
          frequence  : data['frequency'] ?? 'daily',
        );
        await Future.wait([_sound.playNotification(), _vibration.doubleVibrate()]);
      } else {
        await _annulerNotifications(docId, data['frequency'] ?? 'daily');
        await Future.wait([_sound.playNotification(), _vibration.light()]);

      }
    } catch (e) {
      await Future.wait([_sound.playError(), _vibration.error()]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: red,
          ),
        );
      }
    }
  }


  Future<void> _supprimerRappel(
      String docId, String nom, AppLocalizations l10n) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteReminder),
        content: Text('${l10n.deleteReminderConfirm} "$nom" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirme == true) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('reminders')
            .doc(docId)
            .get();
        final freq = doc.data()?['frequency'] ?? 'daily';

        await FirebaseFirestore.instance
            .collection('reminders')
            .doc(docId)
            .delete();

        await _annulerNotifications(docId, freq);

        await Future.wait([_sound.playError(), _vibration.error()]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.reminderDeleted} "$nom"'),
              backgroundColor: red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        await Future.wait([_sound.playError(), _vibration.error()]);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: red,
            ),
          );
        }
      }
    }
  }

  void _ouvrirFormulaire({String? docId, Map<String, dynamic>? data}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _FormulaireRappel(
        uid   : _uid,
        docId : docId,
        data  : data,
        onSaved: (String savedDocId, Map<String, dynamic> savedData) async {
          await _planifierNotification(
            docId    : savedDocId,
            nomMed   : savedData['medicationName'] ?? '',
            heureStr : savedData['time'] ?? '08:00',
            frequence: savedData['frequency'] ?? 'daily',
          );
          await Future.wait([_sound.playSuccess(), _vibration.doubleVibrate()]);
        },
      ),
    );
  }

  Future<void> _planifierNotification({
    required String docId,
    required String nomMed,
    required String heureStr,
    required String frequence,
  }) async {
    if (frequence == 'asNeeded') return;
    final parts  = NotificationService.parseTime(heureStr);
    final hour   = parts['hour']!;
    final minute = parts['minute']!;
    final baseId = NotificationService.generateId(docId);

    try {

      await _annulerNotifications(docId, frequence);

      switch (frequence) {
        case 'daily':
          await _notifService.scheduleReminderDaily(
            id             : baseId,
            medicationName : nomMed,
            hour           : hour,
            minute         : minute,
          );
          break;

        case 'twice':
          await _notifService.scheduleReminderDaily(
            id             : baseId,
            medicationName : '$nomMed (1/2)',
            hour           : hour,
            minute         : minute,
          );
          await _notifService.scheduleReminderDaily(
            id             : baseId + 1,
            medicationName : '$nomMed (2/2)',
            hour           : (hour + 8) % 24,
            minute         : minute,
          );
          break;

        case 'thrice':
          await _notifService.scheduleReminderDaily(
            id             : baseId,
            medicationName : '$nomMed (1/3)',
            hour           : hour,
            minute         : minute,
          );
          await _notifService.scheduleReminderDaily(
            id             : baseId + 1,
            medicationName : '$nomMed (2/3)',
            hour           : (hour + 6) % 24,
            minute         : minute,
          );
          await _notifService.scheduleReminderDaily(
            id             : baseId + 2,
            medicationName : '$nomMed (3/3)',
            hour           : (hour + 12) % 24,
            minute         : minute,
          );
          break;

        case 'weekly':
          await _notifService.scheduleReminderWeekly(
            id             : baseId,
            medicationName : nomMed,
            hour           : hour,
            minute         : minute,
          );
          break;
      }
    } catch (e) {
      debugPrint('[ReminderScreen] Erreur planification notification : $e');
    }
  }

  Future<void> _annulerNotifications(String docId, String frequence) async {
    final baseId = NotificationService.generateId(docId);
    try {
      await _notifService.cancelReminder(baseId);
      if (frequence == 'twice' || frequence == 'thrice') {
        await _notifService.cancelReminder(baseId + 1);
      }
      if (frequence == 'thrice') {
        await _notifService.cancelReminder(baseId + 2);
      }
    } catch (e) {
      debugPrint('[ReminderScreen] Erreur annulation notification : $e');
    }
  }

  String _labelFrequence(String freq, AppLocalizations l10n) {
    switch (freq) {
      case 'daily':    return l10n.frequencyDaily;
      case 'twice':    return l10n.frequencyTwice;
      case 'thrice':   return l10n.frequencyThrice;
      case 'weekly':   return l10n.frequencyWeekly;
      case 'asNeeded': return l10n.frequencyAsNeeded;
      default:         return freq;
    }
  }
}

class _FormulaireRappel extends StatefulWidget {
  final String uid;
  final String? docId;
  final Map<String, dynamic>? data;

  /// Callback appelé après sauvegarde Firestore avec succès.
  /// Reçoit le docId Firestore et les données sauvegardées
  /// pour que ReminderScreen puisse planifier la notification.
  final Future<void> Function(String docId, Map<String, dynamic> data) onSaved;

  const _FormulaireRappel({
    required this.uid,
    required this.onSaved,
    this.docId,
    this.data,
  });

  @override
  State<_FormulaireRappel> createState() => _FormulaireRappelState();
}

class _FormulaireRappelState extends State<_FormulaireRappel> {
  static const Color red   = Color(0xFFC62828);
  static const Color green = Color(0xFF2E7D32);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _doseController;
  late TextEditingController _notesController;

  TimeOfDay _heureSelectionnee = const TimeOfDay(hour: 8, minute: 0);
  String    _frequence         = 'daily';
  bool      _isLoading         = false;
  final _sound     = SoundService();
  final _vibration = VibrationService();

  final List<Map<String, String>> _frequences = [
    {'valeur': 'daily',    'labelKey': 'daily'},
    {'valeur': 'twice',    'labelKey': 'twice'},
    {'valeur': 'thrice',   'labelKey': 'thrice'},
    {'valeur': 'weekly',   'labelKey': 'weekly'},
    {'valeur': 'asNeeded', 'labelKey': 'asNeeded'},
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _nomController   = TextEditingController(text: d?['medicationName'] ?? '');
    _doseController  = TextEditingController(text: d?['dose'] ?? '');
    _notesController = TextEditingController(text: d?['notes'] ?? '');
    _frequence       = d?['frequency'] ?? 'daily';

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

  Future<void> _choisirHeure() async {
    final primary = Theme.of(context).colorScheme.primary;
    final picked  = await showTimePicker(
      context: context,
      initialTime: _heureSelectionnee,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _heureSelectionnee = picked);
    }
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) {
      await _vibration.error();
      await _sound.playError();
      return;
    }
    setState(() => _isLoading = true);

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
      String savedDocId;

      if (widget.docId == null) {
        donnees['createdAt'] = FieldValue.serverTimestamp();
        final ref = await FirebaseFirestore.instance
            .collection('reminders')
            .add(donnees);
        savedDocId = ref.id;
      } else {
        await FirebaseFirestore.instance
            .collection('reminders')
            .doc(widget.docId)
            .update(donnees);
        savedDocId = widget.docId!;
      }


      await widget.onSaved(savedDocId, donnees);

      if (mounted) {
        Navigator.pop(context);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.docId == null
                ? l10n.reminderAdded
                : l10n.reminderUpdated),
            backgroundColor: green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      await Future.wait([_sound.playError(), _vibration.error()]);
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
    final l10n    = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final bottom  = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  widget.docId == null
                      ? ' ${l10n.newReminder}'
                      : ' ${l10n.editReminder}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _label(context, '${l10n.medicationName} *'),
              TextFormField(
                controller: _nomController,
                decoration: _inputDeco(
                    context, l10n.medicationNameHint, Icons.medication_outlined),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? l10n.fieldRequired
                    : null,
              ),
              const SizedBox(height: 16),

              _label(context, l10n.dosageOptional),
              TextFormField(
                controller: _doseController,
                decoration: _inputDeco(
                    context, l10n.dosageHint, Icons.scale_outlined),
              ),
              const SizedBox(height: 16),

              _label(context, '${l10n.reminderTime} *'),
              GestureDetector(
                onTap: _choisirHeure,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_heureSelectionnee.hour.toString().padLeft(2, '0')}:'
                            '${_heureSelectionnee.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.modify,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _label(context, '${l10n.frequency} *'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.inputFill(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: DropdownButtonFormField<String>(
                  value: _frequence,
                  dropdownColor: AppColors.surface(context),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    prefixIcon:
                    Icon(Icons.repeat, color: primary, size: 20),
                  ),
                  items: _frequences
                      .map((f) => DropdownMenuItem(
                    value: f['valeur'],
                    child: Text(_labelFrequence(f['valeur']!, l10n)),
                  ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _frequence = val ?? 'daily'),
                ),
              ),

              // ── Info contextuelle selon la fréquence choisie ─
              if (_frequence != 'asNeeded') ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _infoFrequence(_frequence, l10n),
                          style: TextStyle(
                            fontSize: 12,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              _label(context, l10n.notesOptional),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: _inputDeco(context,
                    l10n.notesHint, Icons.notes_outlined),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
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
                        ? l10n.addReminder
                        : l10n.save,
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

  String _infoFrequence(String freq, AppLocalizations l10n) {
    switch (freq) {
      case 'daily':  return l10n.notifInfoDaily;
      case 'twice':  return l10n.notifInfoTwice;
      case 'thrice': return l10n.notifInfoThrice;
      case 'weekly': return l10n.notifInfoWeekly;
      default:       return '';
    }
  }

  String _labelFrequence(String freq, AppLocalizations l10n) {
    switch (freq) {
      case 'daily':    return l10n.frequencyDaily;
      case 'twice':    return l10n.frequencyTwice;
      case 'thrice':   return l10n.frequencyThrice;
      case 'weekly':   return l10n.frequencyWeekly;
      case 'asNeeded': return l10n.frequencyAsNeeded;
      default:         return freq;
    }
  }

  Widget _label(BuildContext context, String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texte,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.onSurface(context),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(
      BuildContext context, String hint, IconData icone) {
    final primary = Theme.of(context).colorScheme.primary;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary(context)),
      prefixIcon: Icon(icone, color: primary, size: 20),
      filled: true,
      fillColor: AppColors.inputFill(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}