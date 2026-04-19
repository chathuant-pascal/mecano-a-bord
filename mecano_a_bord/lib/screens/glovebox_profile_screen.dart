// Création / édition du profil véhicule (après onboarding).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/screens/home_screen.dart';
import 'package:mecano_a_bord/services/vehicle_reference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Arguments de route : `null` = profil actif (comportement historique), `'NEW_PROFILE'` = formulaire vierge,
/// [int] ou [String] numérique = édition de ce profil.
class GloveboxProfileScreen extends StatefulWidget {
  const GloveboxProfileScreen({super.key, this.routeArguments});

  final Object? routeArguments;

  @override
  State<GloveboxProfileScreen> createState() => _GloveboxProfileScreenState();
}

class _GloveboxProfileScreenState extends State<GloveboxProfileScreen> {
  static const _kVehicleMarque = 'vehicle_marque';
  static const _kVehicleModele = 'vehicle_modele';
  static const _kVehicleEnergie = 'vehicle_energie';
  static const _kVehicleAnnee = 'vehicle_annee';
  static const _kVehicleCouleur = 'vehicle_couleur';
  static const _kVehicleImmat = 'vehicle_immat';
  static const _kVehiclePortes = 'vehicle_portes';
  static const _kVehicleDataFetched = 'vehicle_data_fetched';

  final _repository = MabRepository.instance;
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
    _loadExistingProfile();
    _loadVehicleIdentityFromPrefs();
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

  String _normalizePlate(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '-');

  Future<void> _loadVehicleIdentityFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final fetched = prefs.getBool(_kVehicleDataFetched) ?? false;
    if (!mounted) return;
    if (!fetched) {
      setState(() => _vehicleDataFetched = false);
      return;
    }
    _applyIdentityToForm(
      marque: prefs.getString(_kVehicleMarque) ?? '',
      modele: prefs.getString(_kVehicleModele) ?? '',
      energie: prefs.getString(_kVehicleEnergie) ?? '',
      annee: prefs.getString(_kVehicleAnnee) ?? '',
      couleur: prefs.getString(_kVehicleCouleur) ?? '',
      immat: prefs.getString(_kVehicleImmat) ?? '',
      portes: prefs.getInt(_kVehiclePortes),
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
      _selectedFuel = _mapApiFuelToAppFuel(energie);
    }
  }

  String _mapApiFuelToAppFuel(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('diesel') || r.contains('gazole')) return 'Diesel (Gazole)';
    if (r.contains('hybride')) return 'Hybride essence';
    if (r.contains('elect') || r.contains('élect')) return 'Électrique';
    return 'Essence (SP95, SP98)';
  }

  String _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    return '';
  }

  Future<void> _saveIdentityPrefs({
    required String marque,
    required String modele,
    required String energie,
    required String annee,
    required String couleur,
    required String immat,
    required int? portes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVehicleMarque, marque);
    await prefs.setString(_kVehicleModele, modele);
    await prefs.setString(_kVehicleEnergie, energie);
    await prefs.setString(_kVehicleAnnee, annee);
    await prefs.setString(_kVehicleCouleur, couleur);
    await prefs.setString(_kVehicleImmat, immat);
    if (portes != null) {
      await prefs.setInt(_kVehiclePortes, portes);
    } else {
      await prefs.remove(_kVehiclePortes);
    }
    await prefs.setBool(_kVehicleDataFetched, true);
  }

  Future<void> _lookupVehicle() async {
    if (_vehicleDataFetched) return;
    final plate = _normalizePlate(_plateLookupCtrl.text);
    if (plate.isEmpty) {
      setState(() => _vehicleApiMessage = 'Entre une plaque pour continuer.');
      return;
    }
    setState(() {
      _isFetchingVehicle = true;
      _vehicleApiMessage = null;
    });
    try {
      final uri = Uri.parse(
        'https://particulier.api.gouv.fr/api/v2/immatriculation?immatriculation=$plate',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Réponse serveur ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = decoded is Map<String, dynamic>
          ? (decoded['data'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(decoded['data'] as Map)
              : decoded)
          : <String, dynamic>{};
      final marque = _firstNonEmpty(data, ['marque', 'brand']);
      final modele = _firstNonEmpty(data, ['modele', 'model']);
      final energie = _firstNonEmpty(data, ['energie', 'carburant', 'fuel']);
      final annee = _firstNonEmpty(
        data,
        ['annee', 'annee_premiere_mise_en_circulation', 'date_premiere_mise_en_circulation'],
      ).replaceAll(RegExp(r'[^0-9]'), '').padLeft(4, '0').substring(0, 4);
      final couleur = _firstNonEmpty(data, ['couleur']);
      await _saveIdentityPrefs(
        marque: marque,
        modele: modele,
        energie: energie,
        annee: annee,
        couleur: couleur,
        immat: plate,
        portes: null,
      );
      _applyIdentityToForm(
        marque: marque,
        modele: modele,
        energie: energie,
        annee: annee,
        couleur: couleur,
        immat: plate,
        portes: null,
      );
      if (!mounted) return;
      setState(() {
        _vehicleDataFetched = true;
        _showVehicleSummary = true;
        _showManualVehicleForm = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _vehicleApiMessage =
            'Pas de souci ! Tu peux remplir les infos de ta voiture toi-même. Tu trouveras tout sur ta carte grise.';
        _showManualVehicleForm = true;
      });
    } finally {
      if (mounted) setState(() => _isFetchingVehicle = false);
    }
  }

  Future<void> _saveManualIdentity() async {
    final year = _yearCtrl.text.trim();
    if (_brandCtrl.text.trim().isEmpty || _modelCtrl.text.trim().isEmpty || year.isEmpty || _selectedFuel == null) {
      setState(() => _vehicleApiMessage = 'Complète les champs obligatoires pour continuer.');
      return;
    }
    await _saveIdentityPrefs(
      marque: _brandCtrl.text.trim(),
      modele: _modelCtrl.text.trim(),
      energie: _selectedFuel ?? '',
      annee: year,
      couleur: _colorCtrl.text.trim(),
      immat: _normalizePlate(_plateLookupCtrl.text.isNotEmpty ? _plateLookupCtrl.text : _plateCtrl.text),
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
              value: _selectedFuel != null ? _mapApiFuelToAppFuel(_selectedFuel!) : null,
              decoration: const InputDecoration(
                labelText: 'Carburant',
                prefixIcon: Icon(Icons.local_gas_station, color: MabColors.rouge),
              ),
              items: _manualFuelOptions
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFuel = v == null ? null : _mapApiFuelToAppFuel(v)),
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
              onPressed: _isFetchingVehicle ? null : _lookupVehicle,
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
