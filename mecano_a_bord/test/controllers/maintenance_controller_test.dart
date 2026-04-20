import 'package:flutter_test/flutter_test.dart';
import 'package:mecano_a_bord/controllers/maintenance_controller.dart';

void main() {
  late MaintenanceController controller;
  final baseDate = DateTime(2026, 1, 15);
  const currentKm = 100000;

  void expectDateYmd(DateTime? actual, DateTime? expected) {
    if (expected == null) {
      expect(actual, isNull);
      return;
    }
    expect(actual, isNotNull);
    expect(actual!.year, expected.year);
    expect(actual.month, expected.month);
    expect(actual.day, expected.day);
  }

  void expectDefaults({
    required String type,
    required int? nextKm,
    required DateTime? nextDate,
    required bool clearNextKm,
  }) {
    final r = controller.computeNextDefaults(type, currentKm, baseDate);
    expect(r.nextKm, nextKm, reason: 'Type: $type');
    expectDateYmd(r.nextDate, nextDate);
    expect(r.clearNextKm, clearNextKm, reason: 'Type: $type');
  }

  setUp(() {
    controller = MaintenanceController();
  });

  group('computeNextDefaults - 28 types', () {
    test('Vidange + filtre à huile', () {
      expectDefaults(
        type: 'Vidange + filtre à huile',
        nextKm: 115000,
        nextDate: DateTime(2027, 1, 15),
        clearNextKm: false,
      );
    });

    test('Filtre à air', () {
      expectDefaults(
        type: 'Filtre à air',
        nextKm: null,
        nextDate: null,
        clearNextKm: false,
      );
    });

    test('Filtre à carburant / gazole', () {
      expectDefaults(
        type: 'Filtre à carburant / gazole',
        nextKm: null,
        nextDate: null,
        clearNextKm: false,
      );
    });

    test('Filtre habitacle (pollen)', () {
      expectDefaults(
        type: 'Filtre habitacle (pollen)',
        nextKm: null,
        nextDate: null,
        clearNextKm: false,
      );
    });

    test('Pneumatiques (remplacement)', () {
      expectDefaults(
        type: 'Pneumatiques (remplacement)',
        nextKm: null,
        nextDate: DateTime(2031, 1, 15),
        clearNextKm: true,
      );
    });

    test('Pneumatiques (équilibrage / permutation)', () {
      expectDefaults(
        type: 'Pneumatiques (équilibrage / permutation)',
        nextKm: null,
        nextDate: DateTime(2031, 1, 15),
        clearNextKm: true,
      );
    });

    test('Freins — plaquettes', () {
      expectDefaults(
        type: 'Freins — plaquettes',
        nextKm: 140000,
        nextDate: null,
        clearNextKm: false,
      );
    });

    test('Freins — disques', () {
      expectDefaults(
        type: 'Freins — disques',
        nextKm: null,
        nextDate: null,
        clearNextKm: false,
      );
    });

    test('Courroie de distribution', () {
      expectDefaults(
        type: 'Courroie de distribution',
        nextKm: 220000,
        nextDate: DateTime(2036, 1, 15),
        clearNextKm: false,
      );
    });

    test('Batterie', () {
      expectDefaults(
        type: 'Batterie',
        nextKm: null,
        nextDate: null,
        clearNextKm: false,
      );
    });

    test('Contrôle technique', () {
      expectDefaults(
        type: 'Contrôle technique',
        nextKm: null,
        nextDate: DateTime(2028, 1, 15),
        clearNextKm: true,
      );
    });

    test('Révision générale', () {
      expectDefaults(
        type: 'Révision générale',
        nextKm: 130000,
        nextDate: DateTime(2028, 1, 15),
        clearNextKm: false,
      );
    });

    test('Liquide de refroidissement', () {
      expectDefaults(
        type: 'Liquide de refroidissement',
        nextKm: null,
        nextDate: null,
        clearNextKm: false,
      );
    });

    test('Ampoules / éclairage', () {
      expectDefaults(
        type: 'Ampoules / éclairage',
        nextKm: null,
        nextDate: null,
        clearNextKm: false,
      );
    });

    test('Essuie-glaces', () {
      expectDefaults(
        type: 'Essuie-glaces',
        nextKm: null,
        nextDate: null,
        clearNextKm: false,
      );
    });

    test('Embrayage', () {
      expectDefaults(
        type: 'Embrayage',
        nextKm: 180000,
        nextDate: null,
        clearNextKm: false,
      );
    });

    test('Calorstat', () {
      expectDefaults(
        type: 'Calorstat',
        nextKm: 200000,
        nextDate: DateTime(2036, 1, 15),
        clearNextKm: false,
      );
    });

    test('Pompe à eau', () {
      expectDefaults(
        type: 'Pompe à eau',
        nextKm: 200000,
        nextDate: DateTime(2036, 1, 15),
        clearNextKm: false,
      );
    });

    test('Courroie accessoire + galets', () {
      expectDefaults(
        type: 'Courroie accessoire + galets',
        nextKm: 160000,
        nextDate: DateTime(2031, 1, 15),
        clearNextKm: false,
      );
    });

    test('Joint de culasse', () {
      expectDefaults(
        type: 'Joint de culasse',
        nextKm: null,
        nextDate: null,
        clearNextKm: true,
      );
    });

    test('Alternateur', () {
      expectDefaults(
        type: 'Alternateur',
        nextKm: null,
        nextDate: null,
        clearNextKm: true,
      );
    });

    test('Démarreur', () {
      expectDefaults(
        type: 'Démarreur',
        nextKm: null,
        nextDate: null,
        clearNextKm: true,
      );
    });

    test('Électronique / Électricité', () {
      expectDefaults(
        type: 'Électronique / Électricité',
        nextKm: null,
        nextDate: null,
        clearNextKm: true,
      );
    });

    test('Climatisation — recharge gaz', () {
      expectDefaults(
        type: 'Climatisation — recharge gaz',
        nextKm: null,
        nextDate: DateTime(2028, 1, 15),
        clearNextKm: true,
      );
    });

    test('Climatisation — filtre déshydrateur', () {
      expectDefaults(
        type: 'Climatisation — filtre déshydrateur',
        nextKm: 130000,
        nextDate: DateTime(2028, 1, 15),
        clearNextKm: false,
      );
    });

    test('Train avant (rotules / biellettes / triangles)', () {
      expectDefaults(
        type: 'Train avant (rotules / biellettes / triangles)',
        nextKm: null,
        nextDate: null,
        clearNextKm: true,
      );
    });

    test('Amortisseurs / Suspension', () {
      expectDefaults(
        type: 'Amortisseurs / Suspension',
        nextKm: 180000,
        nextDate: DateTime(2031, 1, 15),
        clearNextKm: false,
      );
    });

    test('Autre intervention', () {
      expectDefaults(
        type: 'Autre intervention',
        nextKm: null,
        nextDate: null,
        clearNextKm: true,
      );
    });
  });

  group('computeNextDefaults - cas complémentaire', () {
    test('type inconnu -> (null, null, false)', () {
      final r = controller.computeNextDefaults('Type inconnu', currentKm, baseDate);
      expect(r.nextKm, isNull);
      expect(r.nextDate, isNull);
      expect(r.clearNextKm, isFalse);
    });
  });

  group('canSave', () {
    test('type null -> false', () {
      expect(controller.canSave(null, baseDate, '100000'), isFalse);
    });

    test('date null -> false', () {
      expect(
        controller.canSave('Vidange + filtre à huile', null, '100000'),
        isFalse,
      );
    });

    test('tout rempli -> true', () {
      expect(
        controller.canSave('Vidange + filtre à huile', baseDate, '100000'),
        isTrue,
      );
    });
  });
}
