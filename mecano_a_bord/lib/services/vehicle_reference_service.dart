// vehicle_reference_service.dart — Récupération et stockage des valeurs constructeur (JSON IA + base communautaire).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/services/ai_conversation_service.dart';

/// Après enregistrement / mise à jour d’un profil véhicule complet : remplit [vehicle_reference_values].
class VehicleReferenceService {
  VehicleReferenceService._();
  static final VehicleReferenceService instance = VehicleReferenceService._();

  final MabRepository _repo = MabRepository.instance;
  final AiConversationService _ai = AiConversationService.instance;

  /// JSON de démonstration (pas d’appel réseau en mode démo).
  static const String _demoReferenceJson = '''
{"temperature_normale_min":85,"temperature_normale_max":105,"tension_batterie_min":12.4,"tension_batterie_max":14.8,"regime_ralenti_min":650,"regime_ralenti_max":900,"temperature_huile_min":80,"temperature_huile_max":120}
''';

  /// À appeler quand le profil est enregistré (id SQLite connu).
  Future<void> ensureReferenceValuesForProfile({
    required int vehicleProfileId,
    required VehicleProfile profile,
  }) async {
    if (await _repo.isDemoMode()) {
      await _repo.saveVehicleReferenceValues(
        vehicleProfileId: vehicleProfileId,
        fingerprint: MabRepository.vehicleFingerprint(profile),
        jsonValues: _demoReferenceJson.trim(),
      );
      return;
    }

    final existing = await _repo.getVehicleReferenceJson(vehicleProfileId);
    if (existing != null && existing.trim().isNotEmpty) {
      return;
    }

    final fp = MabRepository.vehicleFingerprint(profile);

    final community = await _repo.getCommunityReferenceJson(
      fp,
      excludeVehicleId: vehicleProfileId,
    );
    if (community != null && community.trim().isNotEmpty) {
      await _repo.saveVehicleReferenceValues(
        vehicleProfileId: vehicleProfileId,
        fingerprint: fp,
        jsonValues: community.trim(),
      );
      return;
    }

    final response = await _ai.askManufacturerReferenceJson(
      marque: profile.brand,
      modele: profile.model,
      annee: profile.year,
      motorisation: profile.motorisation,
    );

    if (response is AiSuccess) {
      final cleaned = _extractJsonObject(response.text);
      if (cleaned != null) {
        await _repo.saveVehicleReferenceValues(
          vehicleProfileId: vehicleProfileId,
          fingerprint: fp,
          jsonValues: cleaned,
        );
      }
    } else if (response is AiError) {
      if (response.message == 'assistant_ia_non_configuré') {
        debugPrint(
          'VehicleReferenceService: pas de clé IA — valeurs constructeur non chargées.',
        );
      } else {
        debugPrint('VehicleReferenceService IA: ${response.message}');
      }
    }
  }

  /// Retire balises markdown et extrait le premier objet JSON.
  String? _extractJsonObject(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      final lines = s.split('\n');
      if (lines.length > 2) {
        s = lines.sublist(1, lines.length - 1).join('\n').trim();
      }
    }
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    s = s.substring(start, end + 1);
    try {
      jsonDecode(s);
      return s;
    } catch (_) {
      return null;
    }
  }
}
