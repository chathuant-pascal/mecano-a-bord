import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mecano_a_bord/data/mab_database.dart' as db;
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MabRepository repo;

  VehicleProfile buildProfile({
    String id = '',
    String brand = 'Peugeot',
    String model = '308',
    int year = 2020,
    int mileage = 120000,
    String gearboxType = 'Manuelle',
    String fuelType = 'Diesel',
    String licensePlate = 'AB-123-CD',
    String vin = 'VF3ABCDEFGH123456',
    String motorisation = '1.5 BlueHDi',
  }) {
    return VehicleProfile(
      id: id,
      brand: brand,
      model: model,
      year: year,
      mileage: mileage,
      gearboxType: gearboxType,
      fuelType: fuelType,
      licensePlate: licensePlate,
      vin: vin,
      motorisation: motorisation,
    );
  }

  MaintenanceEntry buildMaintenance({
    String id = '',
    String vehicleProfileId = '',
    String entryType = 'Vidange',
    int? date,
    int mileageAtService = 100000,
    int? nextServiceMileage,
    int? nextServiceDate,
    String notes = 'RAS',
  }) {
    return MaintenanceEntry(
      id: id,
      vehicleProfileId: vehicleProfileId,
      entryType: entryType,
      date: date ?? DateTime(2026, 1, 15).millisecondsSinceEpoch,
      mileageAtService: mileageAtService,
      nextServiceMileage: nextServiceMileage,
      nextServiceDate: nextServiceDate,
      notes: notes,
    );
  }

  GloveboxDocument buildDoc({
    String id = '',
    String vehicleProfileId = '',
    String documentType = 'assurance',
    String title = 'Attestation 2026',
    String filePath = '/tmp/attestation.pdf',
    String mimeType = 'application/pdf',
    int? expiryDate,
  }) {
    return GloveboxDocument(
      id: id,
      vehicleProfileId: vehicleProfileId,
      documentType: documentType,
      title: title,
      filePath: filePath,
      mimeType: mimeType,
      expiryDate: expiryDate,
      addedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<VehicleProfile> createAndGetActiveProfile({
    String brand = 'Peugeot',
    String model = '308',
    int year = 2020,
  }) async {
    await repo.saveVehicleProfile(
      buildProfile(brand: brand, model: model, year: year),
    );
    final active = await repo.getActiveVehicleProfile();
    expect(active, isNotNull);
    return active!;
  }

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await db.MabDatabase.instance.closeAndDeleteDatabaseFile();
    repo = MabRepository.instance;
  });

  tearDownAll(() async {
    await db.MabDatabase.instance.closeAndDeleteDatabaseFile();
  });

  group('1) Méthodes statiques / pures', () {
    test('getMimeTypeFromPath .jpg -> image/jpeg', () {
      expect(
        MabRepository.getMimeTypeFromPath('/a/photo.jpg'),
        'image/jpeg',
      );
    });

    test('getMimeTypeFromPath .PNG -> image/png', () {
      expect(
        MabRepository.getMimeTypeFromPath('/a/photo.PNG'),
        'image/png',
      );
    });

    test('getMimeTypeFromPath .pdf -> application/pdf', () {
      expect(
        MabRepository.getMimeTypeFromPath('/a/doc.pdf'),
        'application/pdf',
      );
    });

    test('getMimeTypeFromPath extension inconnue -> vide', () {
      expect(
        MabRepository.getMimeTypeFromPath('/a/doc.xyz'),
        '',
      );
    });

    test('vehicleFingerprint normalise trim/lowercase/espaces', () {
      final fp = MabRepository.vehicleFingerprint(
        buildProfile(
          brand: '  PEUGEOT ',
          model: '  308   SW ',
          year: 2020,
          motorisation: '  1.5   BLUEHDI ',
        ),
      );
      expect(fp, 'peugeot|308 sw|2020|1.5 bluehdi');
    });
  });

  group('2) Mode démo / SharedPreferences', () {
    test('isDemoMode par défaut -> false', () async {
      expect(await repo.isDemoMode(), isFalse);
    });

    test('setDemoMode(true) active le mode démo', () async {
      await repo.setDemoMode(true);
      expect(await repo.isDemoMode(), isTrue);
    });

    test('setDemoMode(false) désactive + efface scénario', () async {
      await repo.setDemoMode(true);
      await repo.setDemoObdScenario('red');
      await repo.setDemoMode(false);
      expect(await repo.isDemoMode(), isFalse);
      expect(await repo.getDemoObdScenario(), 'green');
    });

    test('getDemoObdScenario par défaut -> green', () async {
      expect(await repo.getDemoObdScenario(), 'green');
    });

    test('setDemoObdScenario red puis get -> red', () async {
      await repo.setDemoObdScenario('red');
      expect(await repo.getDemoObdScenario(), 'red');
    });

    test('getActiveVehicleProfile en démo -> non null', () async {
      await repo.setDemoMode(true);
      final profile = await repo.getActiveVehicleProfile();
      expect(profile, isNotNull);
    });

    test('getAllMaintenanceEntries en démo -> non vide', () async {
      await repo.setDemoMode(true);
      final list = await repo.getAllMaintenanceEntries();
      expect(list, isNotEmpty);
    });

    test('getObdDiagnosticsForVehicle en démo -> []', () async {
      await repo.setDemoMode(true);
      final list = await repo.getObdDiagnosticsForVehicle(1);
      expect(list, isEmpty);
    });
  });

  group('3) Profils véhicule', () {
    test('getActiveVehicleProfile sans profil -> null', () async {
      expect(await repo.getActiveVehicleProfile(), isNull);
    });

    test('saveVehicleProfile nouveau -> id actif mémorisé', () async {
      await repo.saveVehicleProfile(buildProfile());
      final activeId = await repo.getActiveVehicleId();
      expect(activeId, isNotNull);
    });

    test('getActiveVehicleProfile après save -> profil retourné', () async {
      await repo.saveVehicleProfile(buildProfile(brand: 'Renault', model: 'Clio'));
      final profile = await repo.getActiveVehicleProfile();
      expect(profile, isNotNull);
      expect(profile!.brand, 'Renault');
      expect(profile.model, 'Clio');
    });

    test('saveVehicleProfile update conserve le même id', () async {
      final created = await createAndGetActiveProfile();
      final beforeId = created.id;
      final updated = buildProfile(
        id: beforeId,
        brand: created.brand,
        model: '308 GT',
        year: created.year,
        mileage: 130000,
        gearboxType: created.gearboxType,
        fuelType: created.fuelType,
        licensePlate: created.licensePlate,
        vin: created.vin,
        motorisation: created.motorisation,
      );
      await repo.saveVehicleProfile(updated);
      final fetched = await repo.getVehicleProfileById(int.parse(beforeId));
      expect(fetched, isNotNull);
      expect(fetched!.id, beforeId);
      expect(fetched.model, '308 GT');
    });

    test('getAllVehicleProfiles avec 3 inserts -> StateError (règle 5)', () async {
      await repo.saveVehicleProfile(buildProfile(model: '308'));
      await repo.saveVehicleProfile(buildProfile(model: '208', vin: 'VF3ABCDEFGH123457'));
      expect(
        () => repo.saveVehicleProfile(buildProfile(model: '2008', vin: 'VF3ABCDEFGH123458')),
        throwsA(isA<StateError>()),
      );
      final list = await repo.getAllVehicleProfiles();
      expect(list.length, 2);
    });

    test('getVehicleProfileById existant -> profil correct', () async {
      final profile = await createAndGetActiveProfile(brand: 'Citroen', model: 'C3');
      final fetched = await repo.getVehicleProfileById(int.parse(profile.id));
      expect(fetched, isNotNull);
      expect(fetched!.brand, 'Citroen');
      expect(fetched.model, 'C3');
    });

    test('getVehicleProfileById inexistant -> null', () async {
      expect(await repo.getVehicleProfileById(99999), isNull);
    });

    test('deleteVehicleProfile supprime le profil', () async {
      final profile = await createAndGetActiveProfile();
      final id = int.parse(profile.id);
      await repo.deleteVehicleProfile(id);
      expect(await repo.getVehicleProfileById(id), isNull);
    });
  });

  group('4) Carnet d\'entretien', () {
    test('getAllMaintenanceEntries sans profil -> []', () async {
      expect(await repo.getAllMaintenanceEntries(), isEmpty);
    });

    test('addMaintenanceEntry sans profil actif -> StateError', () async {
      expect(
        () => repo.addMaintenanceEntry(buildMaintenance()),
        throwsA(isA<StateError>()),
      );
    });

    test('addMaintenanceEntry avec profil -> entrée insérée', () async {
      await createAndGetActiveProfile();
      await repo.addMaintenanceEntry(buildMaintenance(entryType: 'Vidange moteur'));
      final entries = await repo.getAllMaintenanceEntries();
      expect(entries.length, 1);
      expect(entries.first.entryType, 'Vidange moteur');
    });

    test('getMaintenanceEntryById existant -> entrée correcte', () async {
      await createAndGetActiveProfile();
      await repo.addMaintenanceEntry(buildMaintenance(entryType: 'Freins'));
      final all = await repo.getAllMaintenanceEntries();
      final targetId = int.parse(all.first.id);
      final one = await repo.getMaintenanceEntryById(targetId);
      expect(one, isNotNull);
      expect(one!.entryType, 'Freins');
    });

    test('updateMaintenanceEntry met à jour les champs', () async {
      await createAndGetActiveProfile();
      await repo.addMaintenanceEntry(buildMaintenance(entryType: 'Filtre air'));
      final all = await repo.getAllMaintenanceEntries();
      final existing = all.first;
      await repo.updateMaintenanceEntry(
        buildMaintenance(
          id: existing.id,
          vehicleProfileId: existing.vehicleProfileId,
          entryType: 'Filtre air + huile',
          mileageAtService: 110500,
        ),
      );
      final fetched = await repo.getMaintenanceEntryById(int.parse(existing.id));
      expect(fetched, isNotNull);
      expect(fetched!.entryType, 'Filtre air + huile');
      expect(fetched.mileageAtService, 110500);
    });

    test('deleteMaintenanceEntry supprime l\'entrée', () async {
      await createAndGetActiveProfile();
      await repo.addMaintenanceEntry(buildMaintenance(entryType: 'Pneus'));
      final before = await repo.getAllMaintenanceEntries();
      expect(before, isNotEmpty);
      await repo.deleteMaintenanceEntry(before.first.id);
      expect(await repo.getAllMaintenanceEntries(), isEmpty);
    });

    test('getLast3MaintenanceEntries sur 5 -> 3 en ordre décroissant', () async {
      await createAndGetActiveProfile();
      final dates = <DateTime>[
        DateTime(2025, 1, 10),
        DateTime(2025, 3, 10),
        DateTime(2025, 6, 10),
        DateTime(2025, 9, 10),
        DateTime(2025, 12, 10),
      ];
      for (final d in dates) {
        await repo.addMaintenanceEntry(
          buildMaintenance(
            entryType: 'Entry ${d.month}',
            date: d.millisecondsSinceEpoch,
          ),
        );
      }
      final last3 = await repo.getLast3MaintenanceEntries();
      expect(last3.length, 3);
      expect(last3[0].date >= last3[1].date, isTrue);
      expect(last3[1].date >= last3[2].date, isTrue);
    });
  });

  group('5) OBD (prefs + historique)', () {
    test('getLastObdDiagnostic sans données -> null + listes vides', () async {
      final diag = await repo.getLastObdDiagnostic();
      expect(diag.date, isNull);
      expect(diag.kmAtScan, 0);
      expect(diag.storedDtcs, isEmpty);
      expect(diag.pendingDtcs, isEmpty);
      expect(diag.permanentDtcs, isEmpty);
      expect(diag.dtcs, isEmpty);
    });

    test('saveLastObdDiagnostic + get -> données fidèles', () async {
      await createAndGetActiveProfile();
      final when = DateTime(2026, 1, 20, 10, 30);
      await repo.saveLastObdDiagnostic(
        when,
        milOn: true,
        storedDtcs: const ['P0300'],
        pendingDtcs: const ['P0171'],
        permanentDtcs: const ['P0420'],
        kmAtScan: 125500,
      );
      final diag = await repo.getLastObdDiagnostic();
      expect(diag.date?.toIso8601String(), when.toIso8601String());
      expect(diag.milOn, isTrue);
      expect(diag.kmAtScan, 125500);
      expect(diag.storedDtcs, ['P0300']);
      expect(diag.pendingDtcs, ['P0171']);
      expect(diag.permanentDtcs, ['P0420']);
      expect(diag.dtcs, ['P0300', 'P0171', 'P0420']);
    });

    test('setLastObdDeviceAddress + get -> adresse restituée', () async {
      await createAndGetActiveProfile();
      await repo.setLastObdDeviceAddress('AA:BB:CC:11:22:33');
      expect(await repo.getLastObdDeviceAddress(), 'AA:BB:CC:11:22:33');
    });

    test('appendObdDiagnosticHistory + get -> historique contient entrée', () async {
      final profile = await createAndGetActiveProfile();
      final id = int.parse(profile.id);
      await repo.appendObdDiagnosticHistory(
        scanDate: DateTime(2026, 2, 1),
        kmAtScan: 126000,
        milOn: true,
        storedDtcs: const ['P0300'],
        pendingDtcs: const ['P0171'],
        permanentDtcs: const ['P0420'],
        urgenceLevel: 'orange',
        resumeGlobal: 'Alerte modérée',
      );
      final history = await repo.getObdDiagnosticsForVehicle(id);
      expect(history, isNotEmpty);
      expect(history.first.vehicleProfileId, id);
      expect(history.first.storedDtcs, ['P0300']);
      expect(history.first.pendingDtcs, ['P0171']);
      expect(history.first.permanentDtcs, ['P0420']);
    });

    test('getUpcomingMaintenanceAlerts km proche rappel -> incluse', () async {
      await createAndGetActiveProfile();
      await repo.addMaintenanceEntry(
        buildMaintenance(
          entryType: 'Courroie',
          mileageAtService: 120000,
          nextServiceMileage: 130000,
        ),
      );
      final alerts = await repo.getUpcomingMaintenanceAlerts(129600);
      expect(alerts, isNotEmpty);
      expect(alerts.first.entryType, 'Courroie');
    });
  });

  group('6) Documents boîte à gants', () {
    test('getAllGloveboxDocuments sans profil -> []', () async {
      expect(await repo.getAllGloveboxDocuments(), isEmpty);
    });

    test('addGloveboxDocument sans profil -> StateError', () async {
      expect(
        () => repo.addGloveboxDocument(buildDoc()),
        throwsA(isA<StateError>()),
      );
    });

    test('addGloveboxDocument avec profil -> document inséré', () async {
      await createAndGetActiveProfile();
      await repo.addGloveboxDocument(buildDoc(title: 'Carte grise'));
      final docs = await repo.getAllGloveboxDocuments();
      expect(docs.length, 1);
      expect(docs.first.title, 'Carte grise');
    });

    test('mimeType intégré au document', () async {
      await createAndGetActiveProfile();
      final mime = MabRepository.getMimeTypeFromPath('/tmp/carte_grise.JPG');
      await repo.addGloveboxDocument(
        buildDoc(
          title: 'Carte grise JPG',
          filePath: '/tmp/carte_grise.JPG',
          mimeType: mime,
        ),
      );
      final docs = await repo.getAllGloveboxDocuments();
      expect(docs.first.mimeType, 'image/jpeg');
    });
  });

  group('7) Références constructeur + santé', () {
    test('saveVehicleReferenceValues + getVehicleReferenceJson', () async {
      final profile = await createAndGetActiveProfile();
      final id = int.parse(profile.id);
      await repo.saveVehicleReferenceValues(
        vehicleProfileId: id,
        fingerprint: 'peugeot|308|2020|1.5 bluehdi',
        jsonValues: '{"coolant_min":85,"coolant_max":105}',
      );
      final raw = await repo.getVehicleReferenceJson(id);
      expect(raw, isNotNull);
      final map = jsonDecode(raw!) as Map<String, dynamic>;
      expect(map['coolant_min'], 85);
      expect(map['coolant_max'], 105);
    });

    test('getCommunityReferenceJson même empreinte -> trouvé', () async {
      final p1 = await createAndGetActiveProfile(brand: 'Peugeot', model: '308', year: 2020);
      await repo.saveVehicleReferenceValues(
        vehicleProfileId: int.parse(p1.id),
        fingerprint: 'peugeot|308|2020|1.5 bluehdi',
        jsonValues: '{"rpm_idle":750}',
      );
      await repo.saveVehicleProfile(
        buildProfile(
          brand: 'Peugeot',
          model: '308',
          year: 2020,
          vin: 'VF3ABCDEFGH123457',
        ),
      );
      final all = await repo.getAllVehicleProfiles();
      final second = all.firstWhere((e) => e.id != p1.id);
      final reused = await repo.getCommunityReferenceJson(
        'peugeot|308|2020|1.5 bluehdi',
        excludeVehicleId: int.parse(second.id),
      );
      expect(reused, '{"rpm_idle":750}');
    });

    test('getCommunityReferenceJson empreinte différente -> null', () async {
      final profile = await createAndGetActiveProfile();
      await repo.saveVehicleReferenceValues(
        vehicleProfileId: int.parse(profile.id),
        fingerprint: 'peugeot|308|2020|1.5 bluehdi',
        jsonValues: '{"x":1}',
      );
      final notFound = await repo.getCommunityReferenceJson('renault|clio|2018|1.5 dci');
      expect(notFound, isNull);
    });

    test('appendVehicleHealthAlert + list -> alerte présente', () async {
      final profile = await createAndGetActiveProfile();
      final id = int.parse(profile.id);
      await repo.appendVehicleHealthAlert(
        vehicleProfileId: id,
        level: 2,
        message: 'Surveillance recommandée',
        technicalDetail: 'Température haute ponctuelle',
      );
      final alerts = await repo.listVehicleHealthAlerts(id);
      expect(alerts, isNotEmpty);
      expect(alerts.first.level, 2);
      expect(alerts.first.message, 'Surveillance recommandée');
    });

    test('upsert/getVehicleLearnedValuesEntry -> entrée restituée', () async {
      final profile = await createAndGetActiveProfile();
      final id = int.parse(profile.id);
      final row = db.VehicleLearnedValuesEntry(
        vehicleProfileId: id,
        learningStartedMs: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        lastSampleMs: DateTime(2026, 1, 2).millisecondsSinceEpoch,
        learningCompleted: true,
        aggregatesJson: '{"ltft":{"avg":1.2}}',
        sampleCount: 42,
        lastPositiveBilanMs: DateTime(2026, 1, 3).millisecondsSinceEpoch,
      );
      await repo.upsertVehicleLearnedValuesEntry(row);
      final fetched = await repo.getVehicleLearnedValuesEntry(id);
      expect(fetched, isNotNull);
      expect(fetched!.sampleCount, 42);
      expect(fetched.learningCompleted, isTrue);
    });
  });

  group('8) Contexte IA — getAiSystemContextString', () {
    test('profil incomplet (pas de marque/modèle) -> null', () async {
      await repo.saveVehicleProfile(
        buildProfile(
          brand: '',
          model: '',
          vin: 'SHORTVIN',
        ),
      );
      final context = await repo.getAiSystemContextString();
      expect(context, isNull);
    });

    test('profil complet sans historique OBD -> bloc "Aucun diagnostic"', () async {
      await createAndGetActiveProfile(
        brand: 'Peugeot',
        model: '308',
        year: 2020,
      );
      final context = await repo.getAiSystemContextString();
      expect(context, isNotNull);
      expect(context!, contains('Véhicule de l\'utilisateur : Peugeot 308'));
      expect(context, contains('Aucun diagnostic OBD enregistré récemment.'));
    });

    test('profil complet avec OBD vide -> catégories "aucun"', () async {
      await createAndGetActiveProfile(
        brand: 'Peugeot',
        model: '308',
        year: 2020,
      );
      await repo.saveLastObdDiagnostic(
        DateTime(2026, 4, 20, 9, 0),
        milOn: false,
        storedDtcs: const [],
        pendingDtcs: const [],
        permanentDtcs: const [],
        kmAtScan: 120500,
      );
      final context = await repo.getAiSystemContextString();
      expect(context, isNotNull);
      expect(context!, contains('Dernier diagnostic OBD du'));
      expect(context, contains('Témoin Check Engine : éteint'));
      expect(context, contains('Codes mémorisés : aucun'));
      expect(context, contains('Codes en attente : aucun'));
      expect(context, contains('Codes permanents : aucun'));
    });

    test('mode démo scénario green -> mode démo + témoin éteint', () async {
      await repo.setDemoMode(true);
      await repo.setDemoObdScenario('green');
      final context = await repo.getAiSystemContextString();
      expect(context, isNotNull);
      expect(context!, contains('mode démo'));
      expect(context, contains('Dernier diagnostic OBD (démo)'));
      expect(context, contains('Témoin Check Engine : éteint'));
      expect(context, contains('Codes mémorisés : aucun'));
    });

    test('mode démo scénario red -> mode démo + témoin allumé', () async {
      await repo.setDemoMode(true);
      await repo.setDemoObdScenario('red');
      final context = await repo.getAiSystemContextString();
      expect(context, isNotNull);
      expect(context!, contains('mode démo'));
      expect(context, contains('Dernier diagnostic OBD (démo)'));
      expect(context, contains('Témoin Check Engine : ALLUMÉ'));
      expect(context, contains('Codes mémorisés : P0301, P0562'));
      expect(context, contains('Codes permanents : U0100'));
    });
  });
}
