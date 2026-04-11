import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/mab_repository.dart';
import '../../data/model/vehicle_profile.dart';

/// MÉCANO À BORD — glovebox_profile_screen.dart
/// ─────────────────────────────────────────────────────────────
/// Écran de saisie du profil véhicule (iOS + Android).
///
/// Même logique que la version Android :
///   - Formulaire avec 8 champs
///   - Kilométrage + type de boîte = OBLIGATOIRES pour l'OBD
///   - Bouton enregistrer grisé tant que tout n'est pas rempli
///   - Pré-remplissage si un profil existe déjà (mode édition)
/// ─────────────────────────────────────────────────────────────

class GloveboxProfileScreen extends StatefulWidget {
  const GloveboxProfileScreen({super.key});

  @override
  State<GloveboxProfileScreen> createState() => _GloveboxProfileScreenState();
}

class _GloveboxProfileScreenState extends State<GloveboxProfileScreen> {

  final _repository = MabRepository.instance;

  // Clé de formulaire : permet de valider tous les champs d'un coup
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs : chaque contrôleur gère la valeur d'un champ texte
  final _brandCtrl    = TextEditingController();
  final _modelCtrl    = TextEditingController();
  final _yearCtrl     = TextEditingController();
  final _plateCtrl    = TextEditingController();
  final _mileageCtrl  = TextEditingController();
  final _notesCtrl    = TextEditingController();

  // Valeurs des listes déroulantes
  String? _selectedGearbox;
  String? _selectedFuel;

  bool _isSaving   = false;
  bool _isEditMode = false;

  // ── Options des listes déroulantes ───────────────────────
  final _gearboxOptions = [
    'Boîte manuelle',
    'Boîte automatique',
    'Boîte automatisée (robot)',
    'Boîte CVT (variation continue)',
    'Je ne sais pas',
  ];

  final _fuelOptions = [
    'Essence (SP95, SP98)',
    'Diesel (Gazole)',
    'Hybride essence',
    'Hybride diesel',
    'Électrique',
    'GPL',
    'E85 (Superéthanol)',
  ];

  // ── Initialisation ────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
    // Écoute les changements pour activer/désactiver le bouton
    _brandCtrl.addListener(_refresh);
    _modelCtrl.addListener(_refresh);
    _yearCtrl.addListener(_refresh);
    _plateCtrl.addListener(_refresh);
    _mileageCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  // ── Chargement d'un profil existant ──────────────────────
  Future<void> _loadExistingProfile() async {
    final profile = await _repository.getVehicleProfile();
    if (profile != null && mounted) {
      setState(() {
        _isEditMode = true;
        _brandCtrl.text   = profile.brand;
        _modelCtrl.text   = profile.model;
        _yearCtrl.text    = profile.year.toString();
        _plateCtrl.text   = profile.plate;
        _mileageCtrl.text = profile.mileage.toString();
        _notesCtrl.text   = profile.notes ?? '';
        _selectedGearbox  = profile.gearboxType;
        _selectedFuel     = profile.fuelType;
      });
    }
  }

  // ── Validation : peut-on enregistrer ? ───────────────────
  bool get _canSave =>
      _brandCtrl.text.trim().isNotEmpty &&
      _modelCtrl.text.trim().isNotEmpty &&
      _yearCtrl.text.trim().isNotEmpty &&
      _plateCtrl.text.trim().isNotEmpty &&
      _mileageCtrl.text.trim().isNotEmpty &&
      _selectedGearbox != null &&
      _selectedFuel != null;

  // ── Sauvegarde ────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_canSave) return;

    setState(() => _isSaving = true);

    try {
      final profile = VehicleProfile(
        brand:       _brandCtrl.text.trim(),
        model:       _modelCtrl.text.trim(),
        year:        int.tryParse(_yearCtrl.text) ?? 0,
        plate:       _plateCtrl.text.trim().toUpperCase(),
        mileage:     int.tryParse(_mileageCtrl.text) ?? 0,
        gearboxType: _selectedGearbox!,
        fuelType:    _selectedFuel!,
        notes:       _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await _repository.saveVehicleProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Véhicule mis à jour ✓' : 'Véhicule enregistré ✓',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Retour à l'écran précédent
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

  // ── Interface ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier mon véhicule' : 'Mon véhicule'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Introduction ────────────────────────────
              _buildInfoBanner(),
              const SizedBox(height: 24),

              // ── Section : Informations du véhicule ──────
              _buildSectionTitle('Informations du véhicule'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _brandCtrl,
                label: 'Marque *',
                hint: 'Ex : Renault, Peugeot, Volkswagen...',
                icon: Icons.directions_car,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _modelCtrl,
                label: 'Modèle *',
                hint: 'Ex : Clio 4, 308, Golf 7...',
                icon: Icons.time_to_leave,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Année (plus petit)
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _yearCtrl,
                      label: 'Année *',
                      hint: 'Ex : 2019',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Immatriculation (plus grand)
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      controller: _plateCtrl,
                      label: 'Immatriculation *',
                      hint: 'Ex : AB-123-CD',
                      icon: Icons.credit_card,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildDropdown(
                label: 'Carburant *',
                hint: 'Choisir le carburant...',
                icon: Icons.local_gas_station,
                value: _selectedFuel,
                options: _fuelOptions,
                onChanged: (val) => setState(() => _selectedFuel = val),
              ),
              const SizedBox(height: 24),

              // ── Section : Informations pour l'OBD ───────
              _buildSectionTitle('Pour le diagnostic OBD'),
              _buildObdWarning(),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _mileageCtrl,
                label: 'Kilométrage actuel *',
                hint: 'Ex : 87500',
                icon: Icons.speed,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                suffix: 'km',
              ),
              const SizedBox(height: 12),

              _buildDropdown(
                label: 'Type de boîte de vitesses *',
                hint: 'Choisir le type de boîte...',
                icon: Icons.settings,
                value: _selectedGearbox,
                options: _gearboxOptions,
                onChanged: (val) => setState(() => _selectedGearbox = val),
              ),
              const SizedBox(height: 24),

              // ── Section : Notes ──────────────────────────
              _buildSectionTitle('Notes (optionnel)'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _notesCtrl,
                label: 'Notes sur le véhicule',
                hint: 'Ex : Révision faite en janvier, pneus neufs...',
                icon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // ── Bouton Enregistrer ───────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canSave && !_isSaving ? _saveProfile : null,
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
                          _isEditMode ? 'Mettre à jour' : 'Enregistrer mon véhicule',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Rappel champs obligatoires
              if (!_canSave)
                const Center(
                  child: Text(
                    '* Les champs marqués d\'une étoile sont obligatoires',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets réutilisables ────────────────────────────────

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A73E8).withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF1A73E8), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ces informations permettent à Mécano à Bord de vous donner '
              'des conseils adaptés à votre véhicule.',
              style: TextStyle(fontSize: 13, color: Color(0xFF1A73E8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObdWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ces deux informations sont indispensables pour lancer '
              'un diagnostic OBD de votre véhicule.',
              style: TextStyle(fontSize: 12, color: Colors.deepOrange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A73E8),
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
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    int? maxLength,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1A73E8), size: 20),
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
        ),
        counterText: '', // Cache le compteur de caractères (maxLength)
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint, style: const TextStyle(color: Colors.grey)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1A73E8), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // ── Nettoyage mémoire ─────────────────────────────────────
  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _plateCtrl.dispose();
    _mileageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
