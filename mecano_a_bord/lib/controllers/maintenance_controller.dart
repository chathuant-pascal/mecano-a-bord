import 'package:flutter/material.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';

class MaintenanceControllerException implements Exception {
  final String message;
  final Object? cause;

  const MaintenanceControllerException(this.message, {this.cause});

  @override
  String toString() => message;
}

/// Titre de catégorie + types d'entretien affichés dans l'UI.
class MaintenanceCategoryDisplay {
  final String title;
  final List<String> types;

  const MaintenanceCategoryDisplay({
    required this.title,
    required this.types,
  });
}

/// Controller métier (étape 1) : données de référence + règles de calcul.
class MaintenanceController {
  static const List<MaintenanceCategoryDisplay> categoryDisplay = [
    MaintenanceCategoryDisplay(
      title: '🔧 ENTRETIEN COURANT',
      types: [
        'Vidange + filtre à huile',
        'Filtre à air',
        'Filtre à carburant / gazole',
        'Filtre habitacle (pollen)',
        'Liquide de refroidissement',
        'Essuie-glaces',
        'Ampoules / éclairage',
      ],
    ),
    MaintenanceCategoryDisplay(
      title: '⚙️ MOTEUR',
      types: [
        'Embrayage',
        'Calorstat',
        'Pompe à eau',
        'Courroie de distribution',
        'Courroie accessoire + galets',
        'Joint de culasse',
      ],
    ),
    MaintenanceCategoryDisplay(
      title: '🔋 ÉLECTRIQUE',
      types: [
        'Batterie',
        'Alternateur',
        'Démarreur',
        'Électronique / Électricité',
      ],
    ),
    MaintenanceCategoryDisplay(
      title: '❄️ CLIMATISATION',
      types: [
        'Climatisation — recharge gaz',
        'Climatisation — filtre déshydrateur',
      ],
    ),
    MaintenanceCategoryDisplay(
      title: '🚗 TRAIN ROULANT & SÉCURITÉ',
      types: [
        'Freins — plaquettes',
        'Freins — disques',
        'Pneumatiques (remplacement)',
        'Pneumatiques (équilibrage / permutation)',
        'Train avant (rotules / biellettes / triangles)',
        'Amortisseurs / Suspension',
      ],
    ),
    MaintenanceCategoryDisplay(
      title: '📋 ADMINISTRATIF & AUTRE',
      types: [
        'Contrôle technique',
        'Révision générale',
        'Autre intervention',
      ],
    ),
  ];

  static const List<String> maintenanceTypes = [
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
    'Embrayage',
    'Calorstat',
    'Pompe à eau',
    'Courroie accessoire + galets',
    'Joint de culasse',
    'Alternateur',
    'Démarreur',
    'Électronique / Électricité',
    'Climatisation — recharge gaz',
    'Climatisation — filtre déshydrateur',
    'Train avant (rotules / biellettes / triangles)',
    'Amortisseurs / Suspension',
    'Autre intervention',
  ];

  static const Map<String, IconData> typeIcons = {
    'Vidange + filtre à huile': Icons.oil_barrel,
    'Filtre à air': Icons.air,
    'Filtre à carburant / gazole': Icons.local_gas_station,
    'Filtre habitacle (pollen)': Icons.filter_alt,
    'Pneumatiques (remplacement)': Icons.tire_repair,
    'Pneumatiques (équilibrage / permutation)': Icons.rotate_right,
    'Freins — plaquettes': Icons.do_not_disturb_on,
    'Freins — disques': Icons.do_not_disturb_on_total_silence,
    'Courroie de distribution': Icons.settings,
    'Batterie': Icons.battery_charging_full,
    'Contrôle technique': Icons.fact_check,
    'Révision générale': Icons.build,
    'Liquide de refroidissement': Icons.water_drop,
    'Ampoules / éclairage': Icons.lightbulb,
    'Essuie-glaces': Icons.water,
    'Embrayage': Icons.settings_outlined,
    'Calorstat': Icons.thermostat_outlined,
    'Pompe à eau': Icons.water_outlined,
    'Courroie accessoire + galets': Icons.rotate_right_outlined,
    'Joint de culasse': Icons.layers_outlined,
    'Alternateur': Icons.electric_bolt_outlined,
    'Démarreur': Icons.power_settings_new_outlined,
    'Électronique / Électricité': Icons.electrical_services_outlined,
    'Climatisation — recharge gaz': Icons.ac_unit_outlined,
    'Climatisation — filtre déshydrateur': Icons.air_outlined,
    'Train avant (rotules / biellettes / triangles)':
        Icons.directions_car_outlined,
    'Amortisseurs / Suspension': Icons.expand_outlined,
    'Autre intervention': Icons.handyman,
  };

  ({int? nextKm, DateTime? nextDate, bool clearNextKm}) computeNextDefaults(
    String type,
    int currentKm,
    DateTime baseDate,
  ) {
    int? nextKmValue;
    var clearNextKm = false;
    DateTime? nextDate;

    switch (type) {
      case 'Vidange + filtre à huile':
        nextKmValue = currentKm + 15000;
        nextDate = _addYears(baseDate, 1);
        break;
      case 'Freins — plaquettes':
        nextKmValue = currentKm + 40000;
        nextDate = null;
        break;
      case 'Courroie de distribution':
        nextKmValue = currentKm + 120000;
        nextDate = _addYears(baseDate, 10);
        break;
      case 'Pneumatiques (remplacement)':
      case 'Pneumatiques (équilibrage / permutation)':
        clearNextKm = true;
        nextDate = _addYears(baseDate, 5);
        break;
      case 'Contrôle technique':
        clearNextKm = true;
        nextDate = _addYears(baseDate, 2);
        break;
      case 'Révision générale':
        nextKmValue = currentKm + 30000;
        nextDate = _addYears(baseDate, 2);
        break;
      case 'Embrayage':
        nextKmValue = currentKm + 80000;
        nextDate = null;
        break;
      case 'Calorstat':
        nextKmValue = currentKm + 100000;
        nextDate = _addYears(baseDate, 10);
        break;
      case 'Pompe à eau':
        nextKmValue = currentKm + 100000;
        nextDate = _addYears(baseDate, 10);
        break;
      case 'Courroie accessoire + galets':
        nextKmValue = currentKm + 60000;
        nextDate = _addYears(baseDate, 5);
        break;
      case 'Joint de culasse':
      case 'Alternateur':
      case 'Démarreur':
      case 'Électronique / Électricité':
      case 'Train avant (rotules / biellettes / triangles)':
        clearNextKm = true;
        nextDate = null;
        break;
      case 'Climatisation — recharge gaz':
        clearNextKm = true;
        nextDate = _addYears(baseDate, 2);
        break;
      case 'Climatisation — filtre déshydrateur':
        nextKmValue = currentKm + 30000;
        nextDate = _addYears(baseDate, 2);
        break;
      case 'Amortisseurs / Suspension':
        nextKmValue = currentKm + 80000;
        nextDate = _addYears(baseDate, 5);
        break;
      case 'Autre intervention':
        clearNextKm = true;
        nextDate = null;
        break;
      default:
        return (nextKm: null, nextDate: null, clearNextKm: false);
    }

    return (
      nextKm: nextKmValue,
      nextDate: nextDate,
      clearNextKm: clearNextKm,
    );
  }

  bool canSave(String? type, DateTime? date, String mileageText) {
    return type != null && date != null && mileageText.trim().isNotEmpty;
  }

  Future<MaintenanceEntry?> loadEntry(int id) async {
    try {
      return await MabRepository.instance.getMaintenanceEntryById(id);
    } on Exception {
      return null;
    } on Error catch (e) {
      throw MaintenanceControllerException(
        'Erreur critique lors du chargement de l\'entretien.',
        cause: e,
      );
    }
  }

  Future<void> saveEntry(
    MaintenanceEntry entry, {
    required bool isEditMode,
  }) async {
    try {
      if (isEditMode) {
        await MabRepository.instance.updateMaintenanceEntry(entry);
      } else {
        await MabRepository.instance.addMaintenanceEntry(entry);
      }
    } catch (e) {
      throw MaintenanceControllerException(
        'Impossible d\'enregistrer l\'entretien.',
        cause: e,
      );
    }
  }

  DateTime _addYears(DateTime date, int years) {
    return DateTime(date.year + years, date.month, date.day);
  }
}
