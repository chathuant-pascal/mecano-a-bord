import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../data/mab_repository.dart';
import '../../data/model/maintenance_entry.dart';

/// MÉCANO À BORD — add_maintenance_screen.dart
/// ─────────────────────────────────────────────────────────────
/// Écran d'ajout (ou modification) d'un entretien dans le
/// carnet (iOS + Android).
///
/// Même logique que la version Android :
///   - 12+ types d'entretien prédéfinis
///   - Date + kilométrage obligatoires
///   - Prochain entretien (km + date) pour les rappels auto
///   - Photo de facture optionnelle
/// ─────────────────────────────────────────────────────────────

class AddMaintenanceScreen extends StatefulWidget {
  /// Si non null : on est en mode édition d'un entretien existant
  final int? editEntryId;

  const AddMaintenanceScreen({super.key, this.editEntryId});

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {

  final _repository   = MabRepository.instance;
  final _imagePicker  = ImagePicker();

  // Contrôleurs des champs texte
  final _mileageCtrl      = TextEditingController();
  final _nextMileageCtrl  = TextEditingController();
  final _garageCtrl       = TextEditingController();
  final _costCtrl         = TextEditingController();
  final _notesCtrl        = TextEditingController();

  // Valeurs des sélecteurs
  String?  _selectedType;
  DateTime? _selectedDate;
  DateTime? _selectedNextDate;
  File?     _invoicePhoto;

  bool _isSaving   = false;
  bool _isEditMode = false;

  // ── 12+ types d'entretien prédéfinis ─────────────────────
  final _maintenanceTypes = [
    'Vidange + filtre à huile',
    'Filtre à air',
    'Filtre à carburant / gazole',
    'Filtre habitacle (pollen)',
    'Pneumatiques (remplacement)',
    'Pneumatiques (équilibrage / permutation)',
    'Freins — plaquettes',
    'Freins — disques',
    'Courroie de distribution',
    'Batterie',
    'Contrôle technique',
    'Révision générale',
    'Liquide de refroidissement',
    'Ampoules / éclairage',
    'Essuie-glaces',
    'Autre intervention',
  ];

  // Icônes associées à chaque type
  final _typeIcons = <String, IconData>{
    'Vidange + filtre à huile':             Icons.oil_barrel,
    'Filtre à air':                          Icons.air,
    'Filtre à carburant / gazole':           Icons.local_gas_station,
    'Filtre habitacle (pollen)':             Icons.filter_alt,
    'Pneumatiques (remplacement)':           Icons.tire_repair,
    'Pneumatiques (équilibrage / permutation)': Icons.rotate_right,
    'Freins — plaquettes':                   Icons.do_not_disturb_on,
    'Freins — disques':                      Icons.do_not_disturb_on_total_silence,
    'Courroie de distribution':              Icons.settings,
    'Batterie':                              Icons.battery_charging_full,
    'Contrôle technique':                    Icons.fact_check,
    'Révision générale':                     Icons.build,
    'Liquide de refroidissement':            Icons.water_drop,
    'Ampoules / éclairage':                  Icons.lightbulb,
    'Essuie-glaces':                         Icons.water,
    'Autre intervention':                    Icons.handyman,
  };

  @override
  void initState() {
    super.initState();
    if (widget.editEntryId != null) {
      _isEditMode = true;
      _loadExistingEntry(widget.editEntryId!);
    } else {
      // Par défaut : date d'aujourd'hui
      _selectedDate = DateTime.now();
    }
  }

  // ── Chargement d'un entretien existant ────────────────────
  Future<void> _loadExistingEntry(int id) async {
    final entry = await _repository.getMaintenanceEntryById(id);
    if (entry == null || !mounted) return;

    setState(() {
      _selectedType    = entry.type;
      _selectedDate    = entry.date;
      _selectedNextDate = entry.nextDate;
      _mileageCtrl.text     = entry.mileage.toString();
      _nextMileageCtrl.text = entry.nextMileage?.toString() ?? '';
      _garageCtrl.text      = entry.garage ?? '';
      _costCtrl.text        = entry.cost?.toString() ?? '';
      _notesCtrl.text       = entry.notes ?? '';
      if (entry.invoicePhotoPath != null) {
        _invoicePhoto = File(entry.invoicePhotoPath!);
      }
    });
  }

  // ── Validation ────────────────────────────────────────────
  bool get _canSave =>
      _selectedType != null &&
      _selectedDate != null &&
      _mileageCtrl.text.trim().isNotEmpty;

  // ── Sélecteur de date ─────────────────────────────────────
  Future<void> _pickDate({required bool isNext}) async {
    final initial = isNext
        ? (_selectedNextDate ?? DateTime.now().add(const Duration(days: 365)))
        : (_selectedDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        if (isNext) {
          _selectedNextDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  // ── Sélection de photo de facture ─────────────────────────
  Future<void> _pickInvoicePhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _invoicePhoto = File(picked.path));
    }
  }

  // ── Sauvegarde ────────────────────────────────────────────
  Future<void> _saveEntry() async {
    if (!_canSave) return;

    setState(() => _isSaving = true);

    try {
      final entry = MaintenanceEntry(
        id:               widget.editEntryId ?? 0,
        type:             _selectedType!,
        date:             _selectedDate!,
        mileage:          int.tryParse(_mileageCtrl.text) ?? 0,
        nextMileage:      int.tryParse(_nextMileageCtrl.text),
        nextDate:         _selectedNextDate,
        garage:           _garageCtrl.text.trim().isEmpty ? null : _garageCtrl.text.trim(),
        cost:             double.tryParse(_costCtrl.text.replaceAll(',', '.')),
        notes:            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        invoicePhotoPath: _invoicePhoto?.path,
      );

      if (_isEditMode) {
        await _repository.updateMaintenanceEntry(entry);
      } else {
        await _repository.addMaintenanceEntry(entry);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Entretien mis à jour ✓' : 'Entretien enregistré ✓',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // true = succès, pour rafraîchir la liste
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue. Veuillez réessayer.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Formatage de date pour l'affichage ────────────────────
  String _formatDate(DateTime? date) {
    if (date == null) return 'Choisir une date...';
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  // ── Interface ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier l\'entretien' : 'Ajouter un entretien'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Type d'entretien ───────────────────────────
            _buildSectionTitle('Type d\'entretien *'),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            const SizedBox(height: 20),

            // ── Date et kilométrage ────────────────────────
            _buildSectionTitle('Date et kilométrage *'),
            const SizedBox(height: 8),

            // Date d'intervention
            _buildDateRow(
              label:    'Date de l\'intervention',
              date:     _selectedDate,
              icon:     Icons.calendar_today,
              onTap:    () => _pickDate(isNext: false),
            ),
            const SizedBox(height: 12),

            // Kilométrage au moment de l'entretien
            _buildTextField(
              controller:   _mileageCtrl,
              label:        'Kilométrage au moment de l\'entretien *',
              hint:         'Ex : 87 500',
              icon:         Icons.speed,
              suffix:       'km',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),

            // ── Prochain entretien ─────────────────────────
            _buildSectionTitle('Prochain entretien (pour les rappels)'),
            _buildOptionalBadge(),
            const SizedBox(height: 8),

            _buildTextField(
              controller:   _nextMileageCtrl,
              label:        'Prochain entretien au kilométrage',
              hint:         'Ex : 97 500',
              icon:         Icons.speed_outlined,
              suffix:       'km',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),

            _buildDateRow(
              label: 'Prochain entretien à la date',
              date:  _selectedNextDate,
              icon:  Icons.event,
              onTap: () => _pickDate(isNext: true),
              showClear: _selectedNextDate != null,
              onClear: () => setState(() => _selectedNextDate = null),
            ),
            const SizedBox(height: 20),

            // ── Informations complémentaires ───────────────
            _buildSectionTitle('Informations complémentaires'),
            _buildOptionalBadge(),
            const SizedBox(height: 8),

            _buildTextField(
              controller: _garageCtrl,
              label:      'Garage / lieu de l\'intervention',
              hint:       'Ex : Renault Saint-Denis, Mécano du coin...',
              icon:       Icons.business,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller:   _costCtrl,
              label:        'Coût de l\'intervention',
              hint:         'Ex : 89.90',
              icon:         Icons.euro,
              suffix:       '€',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _notesCtrl,
              label:      'Notes',
              hint:       'Ex : Pneus Michelin Energy Saver, bon état général...',
              icon:       Icons.notes,
              maxLines:   3,
            ),
            const SizedBox(height: 20),

            // ── Photo de facture ───────────────────────────
            _buildSectionTitle('Photo de facture'),
            _buildOptionalBadge(),
            const SizedBox(height: 8),
            _buildInvoicePhotoSection(),
            const SizedBox(height: 32),

            // ── Bouton enregistrer ─────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _canSave && !_isSaving ? _saveEntry : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isEditMode ? 'Mettre à jour' : 'Enregistrer l\'entretien',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            if (!_canSave)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    '* Les champs marqués d\'une étoile sont obligatoires',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Sélecteur de type d'entretien (grille de chips) ──────
  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _maintenanceTypes.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1A73E8)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1A73E8)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _typeIcons[type] ?? Icons.build,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Ligne de sélection de date ────────────────────────────
  Widget _buildDateRow({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
    bool showClear = false,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1A73E8), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 15,
                      color: date != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (showClear && onClear != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                color: Colors.grey,
                onPressed: onClear,
              )
            else
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ── Section photo de facture ──────────────────────────────
  Widget _buildInvoicePhotoSection() {
    if (_invoicePhoto != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              _invoicePhoto!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8, right: 8,
            child: Row(
              children: [
                _photoActionButton(
                  icon: Icons.refresh,
                  label: 'Changer',
                  onTap: _pickInvoicePhoto,
                ),
                const SizedBox(width: 8),
                _photoActionButton(
                  icon: Icons.delete,
                  label: 'Supprimer',
                  onTap: () => setState(() => _invoicePhoto = null),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _pickInvoicePhoto,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Ajouter une photo de facture',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Text(
              '(optionnel)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ── Widgets utilitaires ───────────────────────────────────
  Widget _buildSectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A73E8),
        ),
      );

  Widget _buildOptionalBadge() => Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 4),
        child: Text(
          'Optionnel',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1A73E8), size: 20),
        suffixText: suffix,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF1A73E8), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  void dispose() {
    _mileageCtrl.dispose();
    _nextMileageCtrl.dispose();
    _garageCtrl.dispose();
    _costCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
