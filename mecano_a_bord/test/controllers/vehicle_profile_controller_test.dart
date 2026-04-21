import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mecano_a_bord/controllers/vehicle_profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VehicleProfileController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    controller = VehicleProfileController(
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('mapApiFuelToAppFuel', () {
    test('nominal : diesel -> Diesel (Gazole)', () {
      expect(
        controller.mapApiFuelToAppFuel('Diesel'),
        'Diesel (Gazole)',
      );
    });

    test('nominal : hybride -> Hybride essence', () {
      expect(
        controller.mapApiFuelToAppFuel('Hybride rechargeable'),
        'Hybride essence',
      );
    });

    test('cas limite : elect sans accent -> Électrique', () {
      expect(
        controller.mapApiFuelToAppFuel('electrique'),
        'Électrique',
      );
    });

    test('cas limite : valeur inconnue -> Essence (SP95, SP98)', () {
      expect(
        controller.mapApiFuelToAppFuel('Hydrogène'),
        'Essence (SP95, SP98)',
      );
    });
  });

  group('isVinValid', () {
    test('nominal : VIN alphanumérique 17 caractères -> true', () {
      expect(
        VehicleProfileController.isVinValid('WVWZZZ3CZWE123456'),
        isTrue,
      );
    });

    test('erreur : VIN trop court -> false', () {
      expect(
        VehicleProfileController.isVinValid('ABC123'),
        isFalse,
      );
    });

    test('erreur : VIN avec caractère interdit -> false', () {
      expect(
        VehicleProfileController.isVinValid('WVWZZZ3CZWE12345!'),
        isFalse,
      );
    });
  });

  group('normalizePlate', () {
    test('nominal : supprime espaces et met en majuscules', () {
      expect(
        controller.normalizePlate('ab 123 cd'),
        'AB-123-CD',
      );
    });

    test('cas limite : espaces multiples/externes', () {
      expect(
        controller.normalizePlate('  123   abc   12  '),
        '123-ABC-12',
      );
    });
  });

  group('canSave', () {
    test('nominal : tous les champs requis présents -> true', () {
      expect(
        controller.canSave(
          brand: 'Renault',
          model: 'Clio',
          year: '2019',
          plate: 'AB-123-CD',
          vin: 'WVWZZZ3CZWE123456',
          mileage: '125000',
          selectedGearbox: 'Boîte manuelle',
          selectedFuel: 'Diesel (Gazole)',
        ),
        isTrue,
      );
    });

    test('erreur : VIN invalide -> false', () {
      expect(
        controller.canSave(
          brand: 'Renault',
          model: 'Clio',
          year: '2019',
          plate: 'AB-123-CD',
          vin: 'INVALIDE',
          mileage: '125000',
          selectedGearbox: 'Boîte manuelle',
          selectedFuel: 'Diesel (Gazole)',
        ),
        isFalse,
      );
    });

    test('erreur : carburant null -> false', () {
      expect(
        controller.canSave(
          brand: 'Renault',
          model: 'Clio',
          year: '2019',
          plate: 'AB-123-CD',
          vin: 'WVWZZZ3CZWE123456',
          mileage: '125000',
          selectedGearbox: 'Boîte manuelle',
          selectedFuel: null,
        ),
        isFalse,
      );
    });

    test('cas limite : marque espaces -> false', () {
      expect(
        controller.canSave(
          brand: '   ',
          model: 'Clio',
          year: '2019',
          plate: 'AB-123-CD',
          vin: 'WVWZZZ3CZWE123456',
          mileage: '125000',
          selectedGearbox: 'Boîte manuelle',
          selectedFuel: 'Diesel (Gazole)',
        ),
        isFalse,
      );
    });
  });

  group('saveIdentityPrefs + loadIdentityFromPrefs', () {
    test('nominal : enregistre puis relit identité complète', () async {
      await controller.saveIdentityPrefs(
        marque: 'Peugeot',
        modele: '208',
        energie: 'Essence',
        annee: '2020',
        couleur: 'Bleu',
        immat: 'AB-123-CD',
        portes: 5,
      );

      final result = await controller.loadIdentityFromPrefs();

      expect(result.fetched, isTrue);
      expect(result.identity, isNotNull);
      expect(result.identity!.marque, 'Peugeot');
      expect(result.identity!.modele, '208');
      expect(result.identity!.energie, 'Essence');
      expect(result.identity!.annee, '2020');
      expect(result.identity!.couleur, 'Bleu');
      expect(result.identity!.immat, 'AB-123-CD');
      expect(result.identity!.portes, 5);
    });

    test('cas limite : aucune donnée -> fetched false', () async {
      final result = await controller.loadIdentityFromPrefs();

      expect(result.fetched, isFalse);
      expect(result.identity, isNull);
    });

    test('cas limite : portes null -> porte absente après reload', () async {
      await controller.saveIdentityPrefs(
        marque: 'Renault',
        modele: 'Clio',
        energie: 'Diesel',
        annee: '2018',
        couleur: '',
        immat: 'AA-111-AA',
        portes: null,
      );

      final result = await controller.loadIdentityFromPrefs();

      expect(result.fetched, isTrue);
      expect(result.identity, isNotNull);
      expect(result.identity!.portes, isNull);
    });
  });

  group('lookupVehicle', () {
    test('erreur : plaque vide -> message saisie', () async {
      final c = VehicleProfileController(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      final result = await c.lookupVehicle('   ');
      c.dispose();

      expect(result.success, isFalse);
      expect(result.showManualVehicleForm, isFalse);
      expect(result.showVehicleSummary, isFalse);
      expect(result.message, 'Entre une plaque pour continuer.');
    });

    test('nominal : HTTP 200 data imbriquée -> succès + prefs', () async {
      final c = VehicleProfileController(
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'data': {
                'marque': 'Renault',
                'modele': 'Clio',
                'energie': 'Diesel',
                'annee': '2019',
                'couleur': 'Gris',
              },
            }),
            200,
          );
        }),
      );

      final result = await c.lookupVehicle('ab 123 cd');
      final loaded = await c.loadIdentityFromPrefs();
      c.dispose();

      expect(result.success, isTrue);
      expect(result.vehicleDataFetched, isTrue);
      expect(result.showVehicleSummary, isTrue);
      expect(result.showManualVehicleForm, isFalse);
      expect(result.data, isNotNull);
      expect(result.data!.immat, 'AB-123-CD');
      expect(loaded.fetched, isTrue);
      expect(loaded.identity?.marque, 'Renault');
    });

    test('erreur : HTTP non 2xx -> fallback manuel', () async {
      final c = VehicleProfileController(
        httpClient: MockClient((_) async => http.Response('oops', 500)),
      );

      final result = await c.lookupVehicle('AA-123-BB');
      c.dispose();

      expect(result.success, isFalse);
      expect(result.showManualVehicleForm, isTrue);
      expect(result.message, isNotNull);
    });

    test('erreur : exception client HTTP -> fallback manuel', () async {
      final c = VehicleProfileController(
        httpClient: MockClient((_) async {
          throw Exception('network down');
        }),
      );

      final result = await c.lookupVehicle('AA-123-BB');
      c.dispose();

      expect(result.success, isFalse);
      expect(result.showManualVehicleForm, isTrue);
      expect(result.showVehicleSummary, isFalse);
    });

    test('cas limite : réponse JSON liste -> succès avec champs vides', () async {
      final c = VehicleProfileController(
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );

      final result = await c.lookupVehicle('AA-123-BB');
      c.dispose();

      expect(result.success, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.marque, '');
      expect(result.data!.modele, '');
    });
  });

  group('loadExistingProfile', () {
    test('nominal : route NEW_PROFILE -> mode création', () async {
      final result = await controller.loadExistingProfile('NEW_PROFILE');

      expect(result.isEditMode, isFalse);
      expect(result.existingProfileId, '');
      expect(result.profile, isNull);
    });

    test('erreur : accès repository impossible en test -> exception', () async {
      await expectLater(
        controller.loadExistingProfile(null),
        throwsA(isA<Object>()),
      );
    });
  });

  group('saveProfile', () {
    test('erreur : accès repository impossible en test -> résultat échec', () async {
      final result = await controller.saveProfile(
        const VehicleProfileSaveInput(
          isEditMode: false,
          existingProfileId: '',
          brand: 'Renault',
          model: 'Clio',
          motorisation: '1.5 dCi',
          year: '2019',
          plate: 'AB-123-CD',
          vin: 'WVWZZZ3CZWE123456',
          mileage: '120000',
          notes: '',
          selectedGearbox: 'Boîte manuelle',
          selectedFuel: 'Diesel (Gazole)',
        ),
      );

      expect(result.success, isFalse);
      expect(result.message, isNotEmpty);
    });

    test('cas limite : champs numériques invalides -> pas de crash, échec propre', () async {
      final result = await controller.saveProfile(
        const VehicleProfileSaveInput(
          isEditMode: false,
          existingProfileId: '',
          brand: 'Peugeot',
          model: '208',
          motorisation: '',
          year: 'XXXX',
          plate: 'AA-111-AA',
          vin: 'WVWZZZ3CZWE123456',
          mileage: 'ABC',
          notes: 'test',
          selectedGearbox: 'Boîte automatique',
          selectedFuel: 'Essence (SP95, SP98)',
        ),
      );

      expect(result.success, isFalse);
      expect(result.message, isNotEmpty);
    });
  });
}
