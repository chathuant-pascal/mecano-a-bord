import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mecano_a_bord/controllers/maintenance_controller.dart';
import 'package:mecano_a_bord/data/mab_repository.dart' show MaintenanceEntry;
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/utils/mab_logger.dart';
import 'package:mecano_a_bord/widgets/mab_watermark_background.dart';

class AddMaintenanceScreen extends StatefulWidget {
  /// Si non null : mode édition d'un entretien existant.
  final int? editEntryId;

  const AddMaintenanceScreen({super.key, this.editEntryId});

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final MaintenanceController _maintenanceController = MaintenanceController();
  final ImagePicker _imagePicker = ImagePicker();

  final _mileageCtrl = TextEditingController();
  final _nextMileageCtrl = TextEditingController();
  final _garageCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedType;
  DateTime? _selectedDate;
  DateTime? _selectedNextDate;
  File? _invoicePhoto;

  bool _isSaving = false;
  bool _isEditMode = false;

  /// Évite d’écraser les champs « prochain » lors du chargement d’une entrée existante.
  bool _suppressAutoNextDefaults = false;

  @override
  void initState() {
    super.initState();
    assert(
      Set<String>.from(MaintenanceController.maintenanceTypes) ==
          MaintenanceController.categoryDisplay.expand((c) => c.types).toSet(),
      'Les types affichés par catégorie doivent correspondre à _maintenanceTypes.',
    );
    _mileageCtrl.addListener(_onMileageChanged);
    if (widget.editEntryId != null) {
      _isEditMode = true;
      _loadExistingEntry(widget.editEntryId!);
    } else {
      _selectedDate = DateTime.now();
    }
  }

  void _onMileageChanged() {
    if (_suppressAutoNextDefaults) return;
    _applyNextServiceDefaults();
  }

  /// Pré-remplit « prochain km » et « prochaine date » selon le type et le km saisi (modifiables ensuite).
  void _applyNextServiceDefaults() {
    if (_suppressAutoNextDefaults) return;

    final type = _selectedType;
    final raw = _mileageCtrl.text.replaceAll(RegExp(r'\s'), '');
    final currentKm = int.tryParse(raw);
    if (type == null || raw.isEmpty || currentKm == null) return;

    final baseDate = _selectedDate ?? DateTime.now();
    final defaults = _maintenanceController.computeNextDefaults(
      type,
      currentKm,
      baseDate,
    );

    setState(() {
      if (defaults.clearNextKm) {
        _nextMileageCtrl.clear();
      } else if (defaults.nextKm != null) {
        _nextMileageCtrl.text = '${defaults.nextKm}';
      }
      _selectedNextDate = defaults.nextDate;
    });
  }

  Future<void> _loadExistingEntry(int id) async {
    MaintenanceEntry? entry;
    try {
      entry = await _maintenanceController.loadEntry(id);
    } catch (e, st) {
      mabLog('AddMaintenance: chargement entretien id=$id — $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de charger cet entretien. Réessaie ou reviens à la liste.',
            style: MabTextStyles.corpsNormal,
          ),
        ),
      );
      return;
    }
    if (entry == null || !mounted) return;
    final loaded = entry;

    _suppressAutoNextDefaults = true;
    setState(() {
      _selectedType = loaded.entryType;
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(loaded.date);
      _selectedNextDate = loaded.nextServiceDate != null
          ? DateTime.fromMillisecondsSinceEpoch(loaded.nextServiceDate!)
          : null;
      _mileageCtrl.text = loaded.mileageAtService.toString();
      _nextMileageCtrl.text =
          loaded.nextServiceMileage != null ? '${loaded.nextServiceMileage}' : '';
      _garageCtrl.text = loaded.garage ?? '';
      _costCtrl.text = loaded.cost != null ? '${loaded.cost}' : '';
      _notesCtrl.text = loaded.notes ?? '';
      if (loaded.receiptPhotoPath != null) {
        _invoicePhoto = File(loaded.receiptPhotoPath!);
      }
    });
    _suppressAutoNextDefaults = false;
  }

  bool get _canSave =>
      _maintenanceController.canSave(
        _selectedType,
        _selectedDate,
        _mileageCtrl.text,
      );

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
      if (!isNext) {
        _applyNextServiceDefaults();
      }
    }
  }

  Future<void> _pickInvoicePhoto() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MabColors.noirMoyen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MabDimensions.rayonGrand),
        ),
        title: Text(
          'Photo de facture',
          style: MabTextStyles.titreCard,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(ImageSource.camera),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  MabDimensions.zoneTactileMin,
                ),
              ),
              child: Text(
                '📷 Prendre une photo',
                style: MabTextStyles.corpsMedium,
                textAlign: TextAlign.center,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(ImageSource.gallery),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  MabDimensions.zoneTactileMin,
                ),
              ),
              child: Text(
                '🖼️ Choisir dans la galerie',
                style: MabTextStyles.corpsMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _invoicePhoto = File(picked.path));
    }
  }

  Future<void> _saveEntry() async {
    if (!_canSave) return;

    setState(() => _isSaving = true);

    try {
      final entry = MaintenanceEntry(
        id: widget.editEntryId?.toString() ?? '',
        vehicleProfileId: '',
        entryType: _selectedType!,
        date: _selectedDate!.millisecondsSinceEpoch,
        mileageAtService: int.tryParse(_mileageCtrl.text) ?? 0,
        nextServiceMileage: int.tryParse(_nextMileageCtrl.text),
        nextServiceDate: _selectedNextDate?.millisecondsSinceEpoch,
        garage:
            _garageCtrl.text.trim().isEmpty ? null : _garageCtrl.text.trim(),
        cost: double.tryParse(_costCtrl.text.replaceAll(',', '.')),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        receiptPhotoPath: _invoicePhoto?.path,
      );

      await _maintenanceController.saveEntry(entry, isEditMode: _isEditMode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Entretien mis à jour ✓'
                  : 'Entretien enregistré ✓',
            ),
            backgroundColor: MabColors.diagnosticVert,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue. Veuillez réessayer.'),
            backgroundColor: MabColors.diagnosticRouge,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Choisir une date...';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Modifier l\'entretien' : 'Ajouter un entretien',
        ),
      ),
      body: MabWatermarkBackground(
        child: SingleChildScrollView(
          padding: MabDimensions.paddingEcran,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Type d\'entretien *'),
            const SizedBox(height: MabDimensions.espacementS),
            _buildTypeSelector(),
            const SizedBox(height: MabDimensions.espacementL),
            _buildSectionTitle('Date et kilométrage *'),
            const SizedBox(height: MabDimensions.espacementS),
            _buildDateRow(
              label: 'Date de l\'intervention',
              date: _selectedDate,
              icon: Icons.calendar_today,
              onTap: () => _pickDate(isNext: false),
            ),
            const SizedBox(height: MabDimensions.espacementS),
            _buildTextField(
              controller: _mileageCtrl,
              label: 'Kilométrage au moment de l\'entretien *',
              hint: 'Ex : 87 500',
              icon: Icons.speed,
              suffix: 'km',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: MabDimensions.espacementL),
            _buildSectionTitle('Prochain entretien (pour les rappels)'),
            _buildOptionalBadge(),
            const SizedBox(height: MabDimensions.espacementS),
            _buildTextField(
              controller: _nextMileageCtrl,
              label: 'Prochain entretien au kilométrage',
              hint: 'Ex : 97 500',
              icon: Icons.speed_outlined,
              suffix: 'km',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: MabDimensions.espacementS),
            _buildDateRow(
              label: 'Prochain entretien à la date',
              date: _selectedNextDate,
              icon: Icons.event,
              onTap: () => _pickDate(isNext: true),
              showClear: _selectedNextDate != null,
              onClear: () => setState(() => _selectedNextDate = null),
            ),
            const SizedBox(height: MabDimensions.espacementL),
            _buildSectionTitle('Informations complémentaires'),
            _buildOptionalBadge(),
            const SizedBox(height: MabDimensions.espacementS),
            _buildTextField(
              controller: _garageCtrl,
              label: 'Garage / lieu de l\'intervention',
              hint: 'Ex : Renault Saint-Denis, Mécano du coin...',
              icon: Icons.business,
            ),
            const SizedBox(height: MabDimensions.espacementS),
            _buildTextField(
              controller: _costCtrl,
              label: 'Coût de l\'intervention',
              hint: 'Ex : 89.90',
              icon: Icons.euro,
              suffix: '€',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: MabDimensions.espacementS),
            _buildTextField(
              controller: _notesCtrl,
              label: 'Notes',
              hint:
                  'Ex : Pneus Michelin Energy Saver, bon état général...',
              icon: Icons.notes,
              maxLines: 3,
            ),
            const SizedBox(height: MabDimensions.espacementL),
            _buildSectionTitle('Photo de facture'),
            _buildOptionalBadge(),
            const SizedBox(height: MabDimensions.espacementS),
            _buildInvoicePhotoSection(),
            const SizedBox(height: MabDimensions.espacementL),
            SizedBox(
              width: double.infinity,
              height: MabDimensions.boutonHauteur,
              child: ElevatedButton(
                onPressed: _canSave && !_isSaving ? _saveEntry : null,
                child: _isSaving
                    ? const CircularProgressIndicator(color: MabColors.blanc)
                    : Text(
                        _isEditMode
                            ? 'Mettre à jour'
                            : 'Enregistrer l\'entretien',
                      ),
              ),
            ),
            if (!_canSave)
              Padding(
                padding:
                    const EdgeInsets.only(top: MabDimensions.espacementS),
                child: Center(
                  child: Text(
                    '* Les champs marqués d\'une étoile sont obligatoires',
                    style: MabTextStyles.label,
                  ),
                ),
              ),
            const SizedBox(height: MabDimensions.espacementXL),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < MaintenanceController.categoryDisplay.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: MabDimensions.espacementM),
            Divider(
              height: 1,
              thickness: 1,
              color: MabColors.grisContour.withValues(alpha: 0.45),
            ),
            const SizedBox(height: MabDimensions.espacementM),
          ],
          Text(
            MaintenanceController.categoryDisplay[i].title,
            style: MabTextStyles.label.copyWith(
              color: MabColors.rouge,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: MabDimensions.espacementS),
          Wrap(
            spacing: MabDimensions.espacementS,
            runSpacing: MabDimensions.espacementS,
            children: MaintenanceController.categoryDisplay[i].types
                .map(_buildMaintenanceTypeChip)
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildMaintenanceTypeChip(String type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = type);
        _applyNextServiceDefaults();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: MabDimensions.espacementM,
          vertical: MabDimensions.espacementS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? MabColors.rouge : MabColors.noirMoyen,
          borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
          border: Border.all(
            color: isSelected ? MabColors.rouge : MabColors.grisContour,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              MaintenanceController.typeIcons[type] ?? Icons.build,
              size: 16,
              color: isSelected ? MabColors.blanc : MabColors.grisTexte,
            ),
            const SizedBox(width: MabDimensions.espacementXS),
            Text(
              type,
              style: MabTextStyles.label.copyWith(
                color: isSelected ? MabColors.blanc : MabColors.blanc,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        padding: const EdgeInsets.symmetric(
          horizontal: MabDimensions.espacementM,
          vertical: MabDimensions.espacementS,
        ),
        decoration: BoxDecoration(
          color: MabColors.noirMoyen,
          borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
          border: Border.all(color: MabColors.grisContour),
        ),
        child: Row(
          children: [
            Icon(icon, color: MabColors.rouge, size: 20),
            const SizedBox(width: MabDimensions.espacementS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: MabTextStyles.label,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(date),
                    style: MabTextStyles.corpsNormal,
                  ),
                ],
              ),
            ),
            if (showClear && onClear != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                color: MabColors.grisTexte,
                onPressed: onClear,
              )
            else
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: MabColors.grisTexte,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicePhotoSection() {
    if (_invoicePhoto != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
            child: Image.file(
              _invoicePhoto!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _photoActionButton(
                  icon: Icons.refresh,
                  label: 'Changer',
                  onTap: _pickInvoicePhoto,
                ),
                const SizedBox(width: MabDimensions.espacementS),
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
        height: 120,
        decoration: BoxDecoration(
          color: MabColors.noirMoyen,
          borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
          border: Border.all(color: MabColors.grisContour),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 32, color: MabColors.grisTexte),
            SizedBox(height: MabDimensions.espacementXS),
            Text(
              'Ajouter une photo de facture',
              style: MabTextStyles.corpsSecondaire,
            ),
            Text(
              '(optionnel)',
              style: MabTextStyles.label,
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
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: MabTextStyles.titreCard,
    );
  }

  Widget _buildOptionalBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Text(
        'Optionnel',
        style: MabTextStyles.label,
      ),
    );
  }

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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: MabColors.rouge, size: 20),
        suffixText: suffix,
      ),
    );
  }

  @override
  void dispose() {
    _mileageCtrl.removeListener(_onMileageChanged);
    _mileageCtrl.dispose();
    _nextMileageCtrl.dispose();
    _garageCtrl.dispose();
    _costCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}

