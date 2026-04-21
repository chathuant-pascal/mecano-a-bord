// Création / édition du profil véhicule (après onboarding).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mecano_a_bord/controllers/vehicle_profile_controller.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/screens/home_screen.dart';

/// Arguments de route : `null` = profil actif (comportement historique), `'NEW_PROFILE'` = formulaire vierge,
/// [int] ou [String] numérique = édition de ce profil.
class GloveboxProfileScreen extends StatefulWidget {
  const GloveboxProfileScreen({super.key, this.routeArguments});

  final Object? routeArguments;

  @override
  State<GloveboxProfileScreen> createState() => _GloveboxProfileScreenState();
}

class _GloveboxProfileScreenState extends State<GloveboxProfileScreen> {
  final VehicleProfileController _controller = VehicleProfileController();
  final _formKey = GlobalKey<FormState>();
  final _plateLookupCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _motorisationCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _vinCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedGearbox;
  String? _selectedFuel;
  bool _isSaving = false;
  bool _isEditMode = false;
  bool _isFetchingVehicle = false;
  bool _showManualVehicleForm = false;
  bool _showVehicleSummary = false;
  bool _vehicleDataFetched = false;
  String? _vehicleApiMessage;
  int? _selectedDoors;
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
  final _manualFuelOptions = const ['Essence', 'Diesel', 'Hybride', 'Électrique'];
  final _doorOptions = const [2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _loadExistingProfileFromController();
    _loadIdentityFromController();
    _plateLookupCtrl.addListener(_syncPlateLookup);
    _brandCtrl.addListener(_refresh);
    _modelCtrl.addListener(_refresh);
    _motorisationCtrl.addListener(_refresh);
    _yearCtrl.addListener(_refresh);
    _plateCtrl.addListener(_refresh);
    _vinCtrl.addListener(_refresh);
    _mileageCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});
  void _syncPlateLookup() {
    final up = _plateLookupCtrl.text.toUpperCase();
    if (up != _plateLookupCtrl.text) {
      _plateLookupCtrl.value = _plateLookupCtrl.value.copyWith(
        text: up,
        selection: TextSelection.collapsed(offset: up.length),
      );
    }
  }

  Future<void> _loadIdentityFromController() async {
    final result = await _controller.loadIdentityFromPrefs();
    if (!mounted) return;
    if (!result.fetched || result.identity == null) {
      setState(() => _vehicleDataFetched = false);
      return;
    }
    final identity = result.identity!;
    _applyIdentityToForm(
      marque: identity.marque,
      modele: identity.modele,
      energie: identity.energie,
      annee: identity.annee,
      couleur: identity.couleur,
      immat: identity.immat,
      portes: identity.portes,
    );
    setState(() {
      _vehicleDataFetched = true;
      _showVehicleSummary = true;
    });
  }

  void _applyIdentityToForm({
    required String marque,
    required String modele,
    required String energie,
    required String annee,
    required String couleur,
    required String immat,
    required int? portes,
  }) {
    if (marque.isNotEmpty) _brandCtrl.text = marque;
    if (modele.isNotEmpty) _modelCtrl.text = modele;
    if (annee.isNotEmpty) _yearCtrl.text = annee;
    if (immat.isNotEmpty) {
      _plateCtrl.text = immat;
      _plateLookupCtrl.text = immat;
    }
    _colorCtrl.text = couleur;
    _selectedDoors = portes;
    if (energie.isNotEmpty) {
      _selectedFuel = _controller.mapApiFuelToAppFuel(energie);
    }
  }

  Future<void> _lookupVehicleFromController() async {
    if (_vehicleDataFetched) return;
    setState(() {
      _isFetchingVehicle = true;
      _vehicleApiMessage = null;
    });
    final result = await _controller.lookupVehicle(_plateLookupCtrl.text);
    if (!mounted) return;
    if (result.success && result.data != null) {
      final data = result.data!;
      _applyIdentityToForm(
        marque: data.marque,
        modele: data.modele,
        energie: data.energie,
        annee: data.annee,
        couleur: data.couleur,
        immat: data.immat,
        portes: data.portes,
      );
    }
    setState(() {
      _vehicleDataFetched = result.vehicleDataFetched;
      _showVehicleSummary = result.showVehicleSummary;
      _showManualVehicleForm = result.showManualVehicleForm;
      _vehicleApiMessage = result.message;
      _isFetchingVehicle = false;
    });
  }

  Future<void> _saveManualIdentity() async {
    final year = _yearCtrl.text.trim();
    if (_brandCtrl.text.trim().isEmpty || _modelCtrl.text.trim().isEmpty || year.isEmpty || _selectedFuel == null) {
      setState(() => _vehicleApiMessage = 'Complète les champs obligatoires pour continuer.');
      return;
    }
    await _controller.saveIdentityPrefs(
      marque: _brandCtrl.text.trim(),
      modele: _modelCtrl.text.trim(),
      energie: _selectedFuel ?? '',
      annee: year,
      couleur: _colorCtrl.text.trim(),
      immat: _controller.normalizePlate(
        _plateLookupCtrl.text.isNotEmpty ? _plateLookupCtrl.text : _plateCtrl.text,
      ),
      portes: _selectedDoors,
    );
    if (!mounted) return;
    setState(() {
      _vehicleDataFetched = true;
      _showVehicleSummary = true;
      _showManualVehicleForm = false;
      _vehicleApiMessage = null;
    });
  }

  Future<void> _loadExistingProfileFromController() async {
    final result = await _controller.loadExistingProfile(widget.routeArguments);
    final prof = result.profile;
    if (prof != null && mounted) {
      setState(() {
        _isEditMode = result.isEditMode;
        _existingProfileId = result.existingProfileId;
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

  bool get _canSave => _controller.canSave(
        brand: _brandCtrl.text,
        model: _modelCtrl.text,
        year: _yearCtrl.text,
        plate: _plateCtrl.text,
        vin: _vinCtrl.text,
        mileage: _mileageCtrl.text,
        selectedGearbox: _selectedGearbox,
        selectedFuel: _selectedFuel,
      );

  Future<void> _saveProfileFromController() async {
    if (!_formKey.currentState!.validate() || !_canSave) return;

    setState(() => _isSaving = true);

    try {
      final result = await _controller.saveProfile(
        VehicleProfileSaveInput(
          isEditMode: _isEditMode,
          existingProfileId: _existingProfileId,
          brand: _brandCtrl.text,
          model: _modelCtrl.text,
          motorisation: _motorisationCtrl.text,
          year: _yearCtrl.text,
          plate: _plateCtrl.text,
          vin: _vinCtrl.text,
          mileage: _mileageCtrl.text,
          notes: _notesCtrl.text,
          selectedGearbox: _selectedGearbox,
          selectedFuel: _selectedFuel,
        ),
      );

      if (mounted && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: MabColors.diagnosticVert,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: MabColors.diagnosticRouge,
          ),
        );
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
      body: SingleChildScrollView(
          padding: MabDimensions.paddingEcran,
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVehicleIdentitySection(),
              const SizedBox(height: 24),
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
                  onPressed: _canSave && !_isSaving ? _saveProfileFromController : null,
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
    );
  }

  Widget _buildVehicleIdentitySection() {
    if (_showVehicleSummary) {
      return Container(
        padding: MabDimensions.paddingCard,
        decoration: BoxDecoration(
          color: MabColors.noirMoyen,
          borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
          border: Border.all(color: MabColors.grisContour),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quelle est ta voiture ?', style: MabTextStyles.titreCard),
            const SizedBox(height: MabDimensions.espacementS),
            Text('Marque : ${_brandCtrl.text}', style: MabTextStyles.corpsSecondaire),
            Text('Modèle : ${_modelCtrl.text}', style: MabTextStyles.corpsSecondaire),
            Text('Année : ${_yearCtrl.text}', style: MabTextStyles.corpsSecondaire),
            Text('Carburant : ${_selectedFuel ?? '-'}', style: MabTextStyles.corpsSecondaire),
            Text('Plaque : ${_plateCtrl.text}', style: MabTextStyles.corpsSecondaire),
            if (_colorCtrl.text.isNotEmpty) Text('Couleur : ${_colorCtrl.text}', style: MabTextStyles.corpsSecondaire),
            const SizedBox(height: MabDimensions.espacementM),
            SizedBox(
              width: double.infinity,
              height: MabDimensions.boutonHauteur,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _showVehicleSummary = false);
                },
                child: const Text("C'est bien ma voiture !"),
              ),
            ),
            const SizedBox(height: MabDimensions.espacementS),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showManualVehicleForm = true;
                    _showVehicleSummary = false;
                  });
                },
                child: const Text('Modifier les informations'),
              ),
            ),
          ],
        ),
      );
    }

    if (_showManualVehicleForm) {
      return Container(
        padding: MabDimensions.paddingCard,
        decoration: BoxDecoration(
          color: MabColors.noirMoyen,
          borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
          border: Border.all(color: MabColors.grisContour),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remplis les infos de ta voiture', style: MabTextStyles.titreCard),
            const SizedBox(height: MabDimensions.espacementM),
            _buildTextField(
              controller: _brandCtrl,
              label: 'Marque',
              hint: 'Ex : Renault',
              icon: Icons.directions_car,
            ),
            const SizedBox(height: MabDimensions.espacementS),
            _buildTextField(
              controller: _modelCtrl,
              label: 'Modèle',
              hint: 'Ex : Clio',
              icon: Icons.time_to_leave,
            ),
            const SizedBox(height: MabDimensions.espacementS),
            DropdownButtonFormField<String>(
              value: _yearCtrl.text.isEmpty ? null : _yearCtrl.text,
              decoration: const InputDecoration(
                labelText: 'Année',
                prefixIcon: Icon(Icons.calendar_today, color: MabColors.rouge),
              ),
              items: List.generate(
                2026 - 1980 + 1,
                (i) => (2026 - i).toString(),
              )
                  .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                  .toList(),
              onChanged: (v) => setState(() => _yearCtrl.text = v ?? ''),
            ),
            const SizedBox(height: MabDimensions.espacementS),
            DropdownButtonFormField<String>(
              value: _selectedFuel != null
                  ? _controller.mapApiFuelToAppFuel(_selectedFuel!)
                  : null,
              decoration: const InputDecoration(
                labelText: 'Carburant',
                prefixIcon: Icon(Icons.local_gas_station, color: MabColors.rouge),
              ),
              items: _manualFuelOptions
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(
                () => _selectedFuel =
                    v == null ? null : _controller.mapApiFuelToAppFuel(v),
              ),
            ),
            const SizedBox(height: MabDimensions.espacementS),
            _buildTextField(
              controller: _colorCtrl,
              label: 'Couleur',
              hint: 'Ex : gris',
              icon: Icons.palette_outlined,
            ),
            const SizedBox(height: MabDimensions.espacementS),
            DropdownButtonFormField<int>(
              value: _selectedDoors,
              decoration: const InputDecoration(
                labelText: 'Nombre de portes',
                prefixIcon: Icon(Icons.door_front_door_outlined, color: MabColors.rouge),
              ),
              items: _doorOptions
                  .map((d) => DropdownMenuItem<int>(value: d, child: Text('$d')))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDoors = v),
            ),
            const SizedBox(height: MabDimensions.espacementM),
            SizedBox(
              width: double.infinity,
              height: MabDimensions.boutonHauteur,
              child: ElevatedButton(
                onPressed: _saveManualIdentity,
                child: const Text('Enregistrer les modifications'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: MabDimensions.paddingCard,
      decoration: BoxDecoration(
        color: MabColors.noirMoyen,
        borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
        border: Border.all(color: MabColors.grisContour),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quelle est ta voiture ?', style: MabTextStyles.titreCard),
          const SizedBox(height: MabDimensions.espacementS),
          Text(
            "Entre ta plaque d'immatriculation, on s'occupe du reste.",
            style: MabTextStyles.corpsSecondaire,
          ),
          const SizedBox(height: MabDimensions.espacementM),
          TextFormField(
            controller: _plateLookupCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Immatriculation',
              hintText: 'AA-123-BC ou 123 ABC 12',
              prefixIcon: Icon(Icons.credit_card, color: MabColors.rouge),
            ),
          ),
          const SizedBox(height: MabDimensions.espacementM),
          SizedBox(
            width: double.infinity,
            height: MabDimensions.boutonHauteur,
            child: ElevatedButton(
              onPressed: _isFetchingVehicle ? null : _lookupVehicleFromController,
              child: _isFetchingVehicle
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: MabColors.blanc,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Trouver ma voiture'),
            ),
          ),
          const SizedBox(height: MabDimensions.espacementS),
          Text(
            "Ta plaque est utilisée uniquement pour identifier ton véhicule. Aucune donnée personnelle n'est partagée.",
            style: MabTextStyles.label.copyWith(color: MabColors.grisTexte),
          ),
          const SizedBox(height: MabDimensions.espacementS),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showManualVehicleForm = true),
              child: const Text('Je préfère remplir moi-même ->'),
            ),
          ),
          if (_vehicleApiMessage != null) ...[
            const SizedBox(height: MabDimensions.espacementS),
            Text(
              _vehicleApiMessage!,
              style: MabTextStyles.corpsSecondaire.copyWith(
                color: MabColors.diagnosticOrange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: MabDimensions.paddingCard,
      decoration: BoxDecoration(
        color: MabColors.rouge.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
        border: Border.all(color: MabColors.rouge.withValues(alpha: 0.3)),
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
        if (!VehicleProfileController.isVinValid(v)) {
          return 'Le numéro VIN doit contenir exactement 17 caractères alphanumériques.';
        }
        return null;
      },
    );
  }

  Widget _buildObdWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MabColors.diagnosticOrange.withValues(alpha: 0.2),
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
    _controller.dispose();
    _plateLookupCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _motorisationCtrl.dispose();
    _yearCtrl.dispose();
    _plateCtrl.dispose();
    _colorCtrl.dispose();
    _vinCtrl.dispose();
    _mileageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
