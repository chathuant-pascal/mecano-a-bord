import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mecano_a_bord/config/mab_features.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/services/vehicle_reference_service.dart';
import 'package:mecano_a_bord/utils/mab_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleProfileController {
  VehicleProfileController({
    MabRepository? repository,
    http.Client? httpClient,
  })  : _repository = repository ?? MabRepository.instance,
        _httpClient = httpClient ?? http.Client();

  final MabRepository _repository;
  final http.Client _httpClient;

  static const String kVehicleMarque = 'vehicle_marque';
  static const String kVehicleModele = 'vehicle_modele';
  static const String kVehicleEnergie = 'vehicle_energie';
  static const String kVehicleAnnee = 'vehicle_annee';
  static const String kVehicleCouleur = 'vehicle_couleur';
  static const String kVehicleImmat = 'vehicle_immat';
  static const String kVehiclePortes = 'vehicle_portes';
  static const String kVehicleDataFetched = 'vehicle_data_fetched';

  String mapApiFuelToAppFuel(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('diesel') || r.contains('gazole')) {
      return 'Diesel (Gazole)';
    }
    if (r.contains('hybride')) return 'Hybride essence';
    if (r.contains('elect') || r.contains('élect')) return 'Électrique';
    return 'Essence (SP95, SP98)';
  }

  static bool isVinValid(String value) {
    final s = value.trim();
    if (s.length != 17) return false;
    return RegExp(r'^[A-Za-z0-9]+$').hasMatch(s);
  }

  String normalizePlate(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '-');

  bool canSave({
    required String brand,
    required String model,
    required String year,
    required String plate,
    required String vin,
    required String mileage,
    required String? selectedGearbox,
    required String? selectedFuel,
  }) {
    return brand.trim().isNotEmpty &&
        model.trim().isNotEmpty &&
        year.trim().isNotEmpty &&
        plate.trim().isNotEmpty &&
        isVinValid(vin) &&
        mileage.trim().isNotEmpty &&
        selectedGearbox != null &&
        selectedFuel != null;
  }

  Future<VehicleLookupResult> lookupVehicle(String rawPlate) async {
    if (!kFeaturePlaque) {
      mabLog('lookupVehicle ignoré: kFeaturePlaque=false');
      return const VehicleLookupResult(
        success: false,
        vehicleDataFetched: false,
        showManualVehicleForm: true,
        showVehicleSummary: false,
        message:
            'La recherche automatique par plaque est indisponible. Tu peux remplir les informations manuellement.',
      );
    }

    final plate = normalizePlate(rawPlate);
    if (plate.isEmpty) {
      return const VehicleLookupResult(
        success: false,
        vehicleDataFetched: false,
        showManualVehicleForm: false,
        showVehicleSummary: false,
        message: 'Entre une plaque pour continuer.',
      );
    }

    try {
      final uri = Uri.parse(
        'https://particulier.api.gouv.fr/api/v2/immatriculation?immatriculation=$plate',
      );
      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 10));

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
        [
          'annee',
          'annee_premiere_mise_en_circulation',
          'date_premiere_mise_en_circulation',
        ],
      ).replaceAll(RegExp(r'[^0-9]'), '').padLeft(4, '0').substring(0, 4);
      final couleur = _firstNonEmpty(data, ['couleur']);

      await saveIdentityPrefs(
        marque: marque,
        modele: modele,
        energie: energie,
        annee: annee,
        couleur: couleur,
        immat: plate,
        portes: null,
      );

      return VehicleLookupResult(
        success: true,
        vehicleDataFetched: true,
        showManualVehicleForm: false,
        showVehicleSummary: true,
        data: VehicleIdentityData(
          marque: marque,
          modele: modele,
          energie: energie,
          annee: annee,
          couleur: couleur,
          immat: plate,
          portes: null,
        ),
      );
    } catch (e, st) {
      // Catch volontairement silencieux côté UX, mais tracé en debug.
      mabLog('lookupVehicle fallback manuel: $e');
      mabLog('$st');
      return const VehicleLookupResult(
        success: false,
        vehicleDataFetched: false,
        showManualVehicleForm: true,
        showVehicleSummary: false,
        message:
            'Pas de souci ! Tu peux remplir les infos de ta voiture toi-même. Tu trouveras tout sur ta carte grise.',
      );
    }
  }

  Future<void> saveIdentityPrefs({
    required String marque,
    required String modele,
    required String energie,
    required String annee,
    required String couleur,
    required String immat,
    required int? portes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kVehicleMarque, marque);
      await prefs.setString(kVehicleModele, modele);
      await prefs.setString(kVehicleEnergie, energie);
      await prefs.setString(kVehicleAnnee, annee);
      await prefs.setString(kVehicleCouleur, couleur);
      await prefs.setString(kVehicleImmat, immat);

      if (portes != null) {
        await prefs.setInt(kVehiclePortes, portes);
      } else {
        await prefs.remove(kVehiclePortes);
      }

      await prefs.setBool(kVehicleDataFetched, true);
    } catch (e, st) {
      mabLog('Erreur SharedPreferences saveIdentityPrefs: $e');
      mabLog('$st');
      rethrow;
    }
  }

  Future<VehicleIdentityLoadResult> loadIdentityFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fetched = prefs.getBool(kVehicleDataFetched) ?? false;
      if (!fetched) {
        return const VehicleIdentityLoadResult(
          fetched: false,
          identity: null,
        );
      }

      return VehicleIdentityLoadResult(
        fetched: true,
        identity: VehicleIdentityData(
          marque: prefs.getString(kVehicleMarque) ?? '',
          modele: prefs.getString(kVehicleModele) ?? '',
          energie: prefs.getString(kVehicleEnergie) ?? '',
          annee: prefs.getString(kVehicleAnnee) ?? '',
          couleur: prefs.getString(kVehicleCouleur) ?? '',
          immat: prefs.getString(kVehicleImmat) ?? '',
          portes: prefs.getInt(kVehiclePortes),
        ),
      );
    } catch (e, st) {
      mabLog('Erreur SharedPreferences loadIdentityFromPrefs: $e');
      mabLog('$st');
      rethrow;
    }
  }

  Future<ExistingProfileLoadResult> loadExistingProfile(
    Object? routeArguments,
  ) async {
    if (routeArguments == 'NEW_PROFILE') {
      return const ExistingProfileLoadResult(
        isEditMode: false,
        existingProfileId: '',
        profile: null,
      );
    }

    int? profileId;
    if (routeArguments is int && routeArguments > 0) {
      profileId = routeArguments;
    } else if (routeArguments is String && routeArguments != 'NEW_PROFILE') {
      profileId = int.tryParse(routeArguments);
    }

    try {
      VehicleProfile? profile;
      if (profileId != null && profileId > 0) {
        profile = await _repository.getVehicleProfileById(profileId);
      } else {
        profile = await _repository.getVehicleProfile();
      }

      if (profile == null) {
        return const ExistingProfileLoadResult(
          isEditMode: false,
          existingProfileId: '',
          profile: null,
        );
      }

      return ExistingProfileLoadResult(
        isEditMode: true,
        existingProfileId: profile.id,
        profile: profile,
      );
    } catch (e, st) {
      mabLog('Erreur SQLite loadExistingProfile: $e');
      mabLog('$st');
      rethrow;
    }
  }

  Future<SaveProfileResult> saveProfile(VehicleProfileSaveInput input) async {
    try {
      final profile = VehicleProfile(
        id: input.isEditMode ? input.existingProfileId : '',
        brand: input.brand.trim(),
        model: input.model.trim(),
        year: int.tryParse(input.year) ?? 0,
        mileage: int.tryParse(input.mileage) ?? 0,
        gearboxType: input.selectedGearbox ?? '',
        fuelType: input.selectedFuel ?? '',
        licensePlate: input.plate.trim().toUpperCase(),
        vin: input.vin.trim().toUpperCase(),
        motorisation: input.motorisation.trim(),
        notes: input.notes.trim().isEmpty ? null : input.notes.trim(),
      );

      await _repository.saveVehicleProfile(profile);

      final saved = await _repository.getVehicleProfile();
      final vehicleId = saved != null ? int.tryParse(saved.id) : null;
      if (vehicleId != null && vehicleId > 0 && saved != null) {
        unawaited(
          VehicleReferenceService.instance.ensureReferenceValuesForProfile(
            vehicleProfileId: vehicleId,
            profile: saved,
          ),
        );
      }

      return SaveProfileResult(
        success: true,
        message: input.isEditMode
            ? 'Véhicule mis à jour ✓'
            : 'Véhicule enregistré ✓',
      );
    } on StateError catch (e, st) {
      mabLog('Erreur métier saveProfile: ${e.message}');
      mabLog('$st');
      return SaveProfileResult(
        success: false,
        message: e.message,
      );
    } catch (e, st) {
      mabLog('Erreur SQLite saveProfile: $e');
      mabLog('$st');
      return const SaveProfileResult(
        success: false,
        message: 'Une erreur est survenue. Veuillez réessayer.',
      );
    }
  }

  String _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  void dispose() {
    _httpClient.close();
  }
}

class VehicleIdentityData {
  const VehicleIdentityData({
    required this.marque,
    required this.modele,
    required this.energie,
    required this.annee,
    required this.couleur,
    required this.immat,
    required this.portes,
  });

  final String marque;
  final String modele;
  final String energie;
  final String annee;
  final String couleur;
  final String immat;
  final int? portes;
}

class VehicleLookupResult {
  const VehicleLookupResult({
    required this.success,
    required this.vehicleDataFetched,
    required this.showManualVehicleForm,
    required this.showVehicleSummary,
    this.message,
    this.data,
  });

  final bool success;
  final bool vehicleDataFetched;
  final bool showManualVehicleForm;
  final bool showVehicleSummary;
  final String? message;
  final VehicleIdentityData? data;
}

class VehicleIdentityLoadResult {
  const VehicleIdentityLoadResult({
    required this.fetched,
    required this.identity,
  });

  final bool fetched;
  final VehicleIdentityData? identity;
}

class ExistingProfileLoadResult {
  const ExistingProfileLoadResult({
    required this.isEditMode,
    required this.existingProfileId,
    required this.profile,
  });

  final bool isEditMode;
  final String existingProfileId;
  final VehicleProfile? profile;
}

class VehicleProfileSaveInput {
  const VehicleProfileSaveInput({
    required this.isEditMode,
    required this.existingProfileId,
    required this.brand,
    required this.model,
    required this.motorisation,
    required this.year,
    required this.plate,
    required this.vin,
    required this.mileage,
    required this.notes,
    required this.selectedGearbox,
    required this.selectedFuel,
  });

  final bool isEditMode;
  final String existingProfileId;
  final String brand;
  final String model;
  final String motorisation;
  final String year;
  final String plate;
  final String vin;
  final String mileage;
  final String notes;
  final String? selectedGearbox;
  final String? selectedFuel;
}

class SaveProfileResult {
  const SaveProfileResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}
