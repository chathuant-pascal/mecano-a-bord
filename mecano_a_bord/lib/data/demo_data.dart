// demo_data.dart — Mécano à Bord
// Données fixes pour le mode démo : profil véhicule, entretiens, documents, scénarios OBD.

import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/services/bluetooth_obd_service.dart';

/// Profil véhicule démo : Renault Clio 4, Diesel, 2015, 87 500 km.
VehicleProfile get demoVehicleProfile => VehicleProfile(
      id: 'demo',
      brand: 'Renault',
      model: 'Clio 4',
      year: 2015,
      mileage: 87500,
      gearboxType: 'Boîte manuelle',
      fuelType: 'Diesel (Gazole)',
      licensePlate: 'AB-123-CD',
      vin: 'VF1R0000054321098',
      motorisation: '1.5 dCi 90ch',
      notes: null,
    );

/// Dernières entrées du carnet d'entretien démo.
List<MaintenanceEntry> get demoMaintenanceEntries => [
      MaintenanceEntry(
        id: 'demo1',
        vehicleProfileId: 'demo',
        entryType: 'Vidange huile',
        date: DateTime.now().subtract(const Duration(days: 90)).millisecondsSinceEpoch,
        mileageAtService: 85000,
        nextServiceMileage: 95000,
        nextServiceDate: null,
        notes: 'Huile moteur 5W30',
        receiptPhotoPath: null,
        garage: 'Garage du Centre',
        cost: 89.0,
      ),
      MaintenanceEntry(
        id: 'demo2',
        vehicleProfileId: 'demo',
        entryType: 'Remplacement filtres',
        date: DateTime.now().subtract(const Duration(days: 180)).millisecondsSinceEpoch,
        mileageAtService: 82000,
        nextServiceMileage: null,
        nextServiceDate: null,
        notes: 'Filtre à huile, filtre habitacle',
        receiptPhotoPath: null,
        garage: 'Garage du Centre',
        cost: 65.0,
      ),
      MaintenanceEntry(
        id: 'demo3',
        vehicleProfileId: 'demo',
        entryType: 'Contrôle technique',
        date: DateTime.now().subtract(const Duration(days: 400)).millisecondsSinceEpoch,
        mileageAtService: 78000,
        nextServiceMileage: null,
        nextServiceDate: DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch,
        notes: 'Favorable',
        receiptPhotoPath: null,
        garage: null,
        cost: 54.90,
      ),
    ];

/// Documents démo pour la Boîte à gants.
List<GloveboxDocument> get demoDocuments => [
      GloveboxDocument(
        id: 'demodoc1',
        vehicleProfileId: 'demo',
        documentType: 'Carte grise',
        title: 'Carte grise démo',
        filePath: '',
        expiryDate: null,
        addedAt: DateTime.now().subtract(const Duration(days: 365)).millisecondsSinceEpoch,
      ),
      GloveboxDocument(
        id: 'demodoc2',
        vehicleProfileId: 'demo',
        documentType: 'Assurance',
        title: 'Attestation assurance démo',
        filePath: '',
        expiryDate: DateTime.now().add(const Duration(days: 180)).millisecondsSinceEpoch,
        addedAt: DateTime.now().subtract(const Duration(days: 60)).millisecondsSinceEpoch,
      ),
      GloveboxDocument(
        id: 'demodoc3',
        vehicleProfileId: 'demo',
        documentType: 'Contrôle technique',
        title: 'Rapport CT démo',
        filePath: '',
        expiryDate: DateTime.now().add(const Duration(days: 400)).millisecondsSinceEpoch,
        addedAt: DateTime.now().subtract(const Duration(days: 400)).millisecondsSinceEpoch,
      ),
    ];

/// Résultat OBD démo selon le scénario choisi.
ObdVehicleResult getDemoObdResult(String scenario) {
  switch (scenario) {
    case 'green':
      return const ObdVehicleResult(
        level: 'green',
        message: 'Aucun défaut détecté.',
        dtcs: [],
        milOn: false,
        storedDtcs: [],
        pendingDtcs: [],
        permanentDtcs: [],
      );
    case 'orange':
      return const ObdVehicleResult(
        level: 'orange',
        message: 'Défauts enregistrés (2 code(s)).',
        dtcs: ['P0171', 'P0420'],
        milOn: false,
        storedDtcs: ['P0171', 'P0420'],
        pendingDtcs: [],
        permanentDtcs: [],
      );
    case 'red':
      return const ObdVehicleResult(
        level: 'red',
        message: 'Défauts critiques : témoin moteur allumé.',
        dtcs: ['P0301', 'P0562', 'U0100'],
        milOn: true,
        storedDtcs: ['P0301', 'P0562'],
        pendingDtcs: [],
        permanentDtcs: ['U0100'],
      );
    default:
      return getDemoObdResult('green');
  }
}
