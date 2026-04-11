// Création / édition du profil véhicule (après onboarding).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/widgets/mab_watermark_background.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/screens/home_screen.dart';
import 'package:mecano_a_bord/services/vehicle_reference_service.dart';

/// Arguments de route : `null` = profil actif (comportement historique), `'NEW_PROFILE'` = formulaire vierge,
/// [int] ou [String] numérique = édition de ce profil.
class GloveboxProfileScreen extends StatefulWidget {
  const GloveboxProfileScreen({super.key, this.routeArguments});

  final Object? routeArguments;

  @override
  State<GloveboxProfileScreen> createState() => _GloveboxProfileScreenState();
}

class _GloveboxProfileScreenState extends State<GloveboxProfileScreen> {
  final _repository = MabRepository.instance;
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _motorisationCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _vinCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedGearbox;
  String? _selectedFuel;
  bool _isSaving = false;
  bool _isEditMode = false;
  String _existingProfileId = '';

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

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
    _brandCtrl.addListener(_refresh);
    _modelCtrl.addListener(_refresh);
    _motorisationCtrl.addListener(_refresh);
    _yearCtrl.addListener(_refresh);
    _plateCtrl.addListener(_refresh);
    _vinCtrl.addListener(_refresh);
    _mileageCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  Future<void> _loadExistingProfile() async {
    final args = widget.routeArguments;
    if (args == 'NEW_PROFILE') {
      return;
    }

    int? profileId;
    if (args is int && args > 0) {
      profileId = args;
    } else if (args is String && args != 'NEW_PROFILE') {
      profileId = int.tryParse(args);
    }

    VehicleProfile? profile;
    if (profileId != null && profileId > 0) {
      profile = await _repository.getVehicleProfileById(profileId);
    } else {
      profile = await _repository.getVehicleProfile();
    }

    final prof = profile;
    if (prof != null && mounted) {
      setState(() {
        _isEditMode = true;
        _existingProfileId = prof.id;
        _brandCtrl.text = prof.brand;
        _modelCtrl.text = prof.model;
        _motorisationCtrl.text = prof.motorisation;
        _yearCtrl.text = prof.year.toString();
        _plateCtrl.text = prof.plate;
        _vinCtrl.text = prof.vin;
        _mileageCtrl.text = prof.mileage.toString();
        _notesCtrl.text = prof.notes ?? '';
        _selectedGearbox = prof.gearboxType;
        _selectedFuel = prof.fuelType;
      });
    }
  }

  static bool _isVinValid(String v) {
    final s = v.trim();
    if (s.length != 17) return false;
    return RegExp(r'^[A-Za-z0-9]+$').hasMatch(s);
  }

  bool get _canSave =>
      _brandCtrl.text.trim().isNotEmpty &&
      _modelCtrl.text.trim().isNotEmpty &&
      _yearCtrl.text.trim().isNotEmpty &&
      _plateCtrl.text.trim().isNotEmpty &&
      _isVinValid(_vinCtrl.text) &&
      _mileageCtrl.text.trim().isNotEmpty &&
      _selectedGearbox != null &&
      _selectedFuel != null;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || !_canSave) return;

    setState(() => _isSaving = true);

    try {
      final profile = VehicleProfile(
        id: _isEditMode ? _existingProfileId : '',
        brand: _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        year: int.tryParse(_yearCtrl.text) ?? 0,
        mileage: int.tryParse(_mileageCtrl.text) ?? 0,
        gearboxType: _selectedGearbox!,
        fuelType: _selectedFuel!,
        licensePlate: _plateCtrl.text.trim().toUpperCase(),
        vin: _vinCtrl.text.trim().toUpperCase(),
        motorisation: _motorisationCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await _repository.saveVehicleProfile(profile);

      final saved = await _repository.getVehicleProfile();
      final vid = saved != null ? int.tryParse(saved.id) : null;
      if (vid != null && vid > 0 && saved != null) {
        unawaited(
          VehicleReferenceService.instance.ensureReferenceValuesForProfile(
            vehicleProfileId: vid,
            profile: saved,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Véhicule mis à jour ✓' : 'Véhicule enregistré ✓',
            ),
            backgroundColor: MabColors.diagnosticVert,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        );
      }
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: MabColors.diagnosticRouge,
          ),
        );
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? 'Modifier mon véhicule'
              : (widget.routeArguments == 'NEW_PROFILE'
                  ? 'Nouveau véhicule'
                  : 'Mon véhicule'),
        ),
      ),
      body: MabWatermarkBackground(
        child: SingleChildScrollView(
          padding: MabDimensions.paddingEcran,
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBanner(),
              const SizedBox(height: 24),
              Text('Informations du véhicule', style: MabTextStyles.titreCard),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _brandCtrl,
                label: 'Marque *',
                hint: 'Ex : Renault, Peugeot...',
                icon: Icons.directions_car,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _modelCtrl,
                label: 'Modèle *',
                hint: 'Ex : Clio 4, 308...',
                icon: Icons.time_to_leave,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _motorisationCtrl,
                label: 'Motorisation (ex: 1.5 dCi 90ch)',
                hint: 'Optionnel',
                icon: Icons.settings_suggest,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _yearCtrl,
                      label: 'Année *',
                      hint: 'Ex : 2019',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      maxLength: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
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
              _buildVinField(),
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
              Text('Pour le diagnostic OBD', style: MabTextStyles.titreCard),
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
                label: 'Type de boîte *',
                hint: 'Choisir le type de boîte...',
                icon: Icons.settings,
                value: _selectedGearbox,
                options: _gearboxOptions,
                onChanged: (val) => setState(() => _selectedGearbox = val),
              ),
              const SizedBox(height: 24),
              Text('Notes (optionnel)', style: MabTextStyles.titreCard),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _notesCtrl,
                label: 'Notes sur le véhicule',
                hint: 'Ex : Révision en janvier...',
                icon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: MabDimensions.boutonHauteur,
                child: ElevatedButton(
                  onPressed: _canSave && !_isSaving ? _saveProfile : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: MabColors.blanc,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Mettre à jour' : 'Enregistrer mon véhicule',
                        ),
                ),
              ),
              if (!_canSave)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      '* Champs obligatoires',
                      style: MabTextStyles.label,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: MabDimensions.paddingCard,
      decoration: BoxDecoration(
        color: MabColors.rouge.withOpacity(0.15),
        borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
        border: Border.all(color: MabColors.rouge.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: MabColors.rouge, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ces informations permettent à Mécano à Bord de vous donner '
              'des conseils adaptés à votre véhicule.',
              style: MabTextStyles.corpsSecondaire.copyWith(
                color: MabColors.blanc,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVinField() {
    const String vinTooltip =
        'Le numéro VIN se trouve sur votre carte grise, sur le tableau de bord côté conducteur ou dans l\'encadrement de la portière.';
    return TextFormField(
      controller: _vinCtrl,
      textCapitalization: TextCapitalization.characters,
      maxLength: 17,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
      ],
      decoration: InputDecoration(
        labelText: 'Numéro VIN (17 caractères) *',
        hintText: 'Ex : WVWZZZ3CZWE123456',
        prefixIcon: const Icon(Icons.vpn_key, color: MabColors.rouge, size: 20),
        suffixIcon: Tooltip(
          message: vinTooltip,
          child: Icon(Icons.info_outline, color: MabColors.grisTexte, size: MabDimensions.iconeM),
        ),
        counterText: '',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Le numéro VIN est obligatoire.';
        if (!_isVinValid(v)) return 'Le numéro VIN doit contenir exactement 17 caractères alphanumériques.';
        return null;
      },
    );
  }

  Widget _buildObdWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MabColors.diagnosticOrange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(MabDimensions.rayonPetit),
        border: Border.all(color: MabColors.diagnosticOrange),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: MabColors.diagnosticOrange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kilométrage et type de boîte sont indispensables pour le diagnostic OBD.',
              style: MabTextStyles.label.copyWith(
                color: MabColors.diagnosticOrange,
              ),
            ),
          ),
        ],
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
        prefixIcon: Icon(icon, color: MabColors.rouge, size: 20),
        suffixText: suffix,
        counterText: '',
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
      hint: Text(hint, style: MabTextStyles.corpsSecondaire),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: MabColors.rouge, size: 20),
      ),
      items: options
          .map((option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option, style: MabTextStyles.corpsNormal),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _motorisationCtrl.dispose();
    _yearCtrl.dispose();
    _plateCtrl.dispose();
    _vinCtrl.dispose();
    _mileageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
