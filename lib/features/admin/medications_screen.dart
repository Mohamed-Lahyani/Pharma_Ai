import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/medication_model.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Médicaments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicationDialog(context),
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un médicament...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Liste des médicaments
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medications')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucun médicament trouvé',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Appuyez sur + pour en ajouter',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrer selon la recherche
                final docs = snapshot.data!.docs.where((doc) {
                  final name = doc['name'].toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final med = MedicationModel.fromMap(
                      docs[index].data() as Map<String, dynamic>,
                      docs[index].id,
                    );
                    return _buildMedicationCard(med, docs[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Carte médicament
  Widget _buildMedicationCard(MedicationModel med, String docId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: med.isLowStock
                  ? Colors.red.shade50
                  : const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.medication,
              color: med.isLowStock
                  ? Colors.red
                  : const Color(0xFF1565C0),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${med.price} DT • Stock: ${med.stock}',
                  style: TextStyle(
                    color: med.isLowStock ? Colors.red : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                if (med.isLowStock)
                  const Text(
                    '⚠️ Stock critique !',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Supprimer',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _showEditMedicationDialog(context, med, docId);
              } else if (value == 'delete') {
                _deleteMedication(docId);
              }
            },
          ),
        ],
      ),
    );
  }

  // Dialog ajouter médicament
  void _showAddMedicationDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final descController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un médicament'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(nameController, 'Nom du médicament'),
              const SizedBox(height: 10),
              _buildDialogField(priceController, 'Prix (DT)',
                  type: TextInputType.number),
              const SizedBox(height: 10),
              _buildDialogField(stockController, 'Stock',
                  type: TextInputType.number),
              const SizedBox(height: 10),
              _buildDialogField(categoryController, 'Catégorie'),
              const SizedBox(height: 10),
              _buildDialogField(descController, 'Description'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('medications')
                  .add({
                'name': nameController.text.trim(),
                'price': double.tryParse(priceController.text) ?? 0,
                'stock': int.tryParse(stockController.text) ?? 0,
                'category': categoryController.text.trim(),
                'description': descController.text.trim(),
                'barcode': '',
                'expiryDate': '',
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  // Dialog modifier médicament
  void _showEditMedicationDialog(
      BuildContext context, MedicationModel med, String docId) {
    final nameController = TextEditingController(text: med.name);
    final priceController =
    TextEditingController(text: med.price.toString());
    final stockController =
    TextEditingController(text: med.stock.toString());
    final descController = TextEditingController(text: med.description);
    final categoryController =
    TextEditingController(text: med.category);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le médicament'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(nameController, 'Nom du médicament'),
              const SizedBox(height: 10),
              _buildDialogField(priceController, 'Prix (DT)',
                  type: TextInputType.number),
              const SizedBox(height: 10),
              _buildDialogField(stockController, 'Stock',
                  type: TextInputType.number),
              const SizedBox(height: 10),
              _buildDialogField(categoryController, 'Catégorie'),
              const SizedBox(height: 10),
              _buildDialogField(descController, 'Description'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('medications')
                  .doc(docId)
                  .update({
                'name': nameController.text.trim(),
                'price': double.tryParse(priceController.text) ?? 0,
                'stock': int.tryParse(stockController.text) ?? 0,
                'category': categoryController.text.trim(),
                'description': descController.text.trim(),
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  // Supprimer médicament
  Future<void> _deleteMedication(String docId) async {
    await FirebaseFirestore.instance
        .collection('medications')
        .doc(docId)
        .delete();
  }

  // Champ texte pour dialog
  Widget _buildDialogField(
      TextEditingController controller,
      String label, {
        TextInputType type = TextInputType.text,
      }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}