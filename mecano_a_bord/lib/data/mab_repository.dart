// mab_repository.dart — Mécano à Bord
// Pont entre MabDatabase et l'application. Modèles de domaine + mapping.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:mecano_a_bord/data/mab_database.dart' as db;
import 'package:mecano_a_bord/data/demo_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// MODÈLES DE DOMAINE (écrans / services)
// ─────────────────────────────────────────────

/// Profil véhicule — utilisé par les écrans (glovebox, accueil, IA).
class VehicleProfile {
  final String id;
  final String brand;
  final String model;
  final int year;
  final int mileage;
  final String gearboxType;
  final String fuelType;
  final String licensePlate;
  final String vin;
  final String motorisation;
  final String? notes;

  VehicleProfile({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.mileage,
    required this.gearboxType,
    required this.fuelType,
    this.licensePlate = '',
    this.vin = '',
    this.motorisation = '',
    this.notes,
  });

  String get plate => licensePlate;

  bool get isComplete => mileage > 0 && gearboxType.isNotEmpty && vin.length == 17;
}

/// Entrée carnet d'entretien (domaine) — pour rappels à l'accueil.
class MaintenanceEntry {
  final String id;
  final String vehicleProfileId;
  final String entryType;
  final int date;
  final int mileageAtService;
  final int? nextServiceMileage;
  final int? nextServiceDate;
  final String? notes;
  final String? receiptPhotoPath;
  final String? garage;
  final double? cost;

  MaintenanceEntry({
    required this.id,
    required this.vehicleProfileId,
    required this.entryType,
    required this.date,
    required this.mileageAtService,
    this.nextServiceMileage,
    this.nextServiceDate,
    this.notes,
    this.receiptPhotoPath,
    this.garage,
    this.cost,
  });
}

/// Document Boîte à gants (domaine).
class GloveboxDocument {
  final String id;
  final String vehicleProfileId;
  final String documentType;
  final String title;
  final String filePath;
  /// Type MIME enregistré à l'ajout (ex. image/jpeg, application/pdf) pour ouvrir sans demander l'app.
  final String mimeType;
  final int? expiryDate;
  final int addedAt;

  GloveboxDocument({
    required this.id,
    required this.vehicleProfileId,
    required this.documentType,
    required this.title,
    required this.filePath,
    this.mimeType = '',
    this.expiryDate,
    required this.addedAt,
  });
}

/// Une entrée d'historique diagnostic OBD (table SQLite `diagnostic_entries`).
class ObdDiagnosticHistoryEntry {
  final String id;
  final int vehicleProfileId;
  final DateTime scanDate;
  final int kilometrageAuScan;
  final bool milOn;
  final List<String> storedDtcs;
  final List<String> pendingDtcs;
  final List<String> permanentDtcs;
  final String urgenceLevel;
  final String resumeGlobal;

  ObdDiagnosticHistoryEntry({
    required this.id,
    required this.vehicleProfileId,
    required this.scanDate,
    required this.kilometrageAuScan,
    required this.milOn,
    required this.storedDtcs,
    required this.pendingDtcs,
    required this.permanentDtcs,
    required this.urgenceLevel,
    required this.resumeGlobal,
  });

  int get totalCodeCount =>
      storedDtcs.length + pendingDtcs.length + permanentDtcs.length;
}

/// Entrée d’historique « santé véhicule » (bilan ou alerte graduée).
class VehicleHealthAlertItem {
  final String id;
  final int level;
  final String message;
  final String? technicalDetail;
  final DateTime createdAt;

  VehicleHealthAlertItem({
    required this.id,
    required this.level,
    required this.message,
    this.technicalDetail,
    required this.createdAt,
  });
}

// ─────────────────────────────────────────────
// REPOSITORY
// ─────────────────────────────────────────────

class MabRepository {
  static MabRepository? _instance;
  static MabRepository get instance {
    _instance ??= MabRepository._();
    return _instance!;
  }

  MabRepository._();

  VehicleProfile _mapToDomain(db.VehicleProfile p) {
    return VehicleProfile(
      id: p.id?.toString() ?? '',
      brand: p.marque,
      model: p.modele,
      year: p.annee,
      mileage: p.kilometrage,
      gearboxType: p.typeBoite,
      fuelType: p.carburant,
      licensePlate: p.numeroPlaqueImmat,
      vin: p.numeroVin,
      motorisation: p.motorisation,
      notes: null,
    );
  }

  db.VehicleProfile _mapToDb(VehicleProfile p) {
    return db.VehicleProfile(
      id: p.id.isNotEmpty ? int.tryParse(p.id) : null,
      marque: p.brand,
      modele: p.model,
      annee: p.year,
      kilometrage: p.mileage,
      typeBoite: p.gearboxType,
      carburant: p.fuelType,
      numeroPlaqueImmat: p.licensePlate,
      numeroVin: p.vin,
      motorisation: p.motorisation,
      estProfilComplet: p.isComplete,
    );
  }

  /// Ligne « véhicule » pour le system prompt IA (motorisation / boîte inclus si renseignés).
  String _vehicleLineForAi(VehicleProfile profile) {
    final motor = profile.motorisation.trim();
    final motorSuffix = motor.isEmpty ? '' : ' $motor';
    return 'Véhicule de l\'utilisateur : ${profile.brand} ${profile.model}$motorSuffix, '
        '${profile.fuelType}, ${profile.gearboxType}, ${profile.year}, ${profile.mileage} km, '
        'VIN ${profile.vin}.';
  }

  MaintenanceEntry _mapMaintenanceToDomain(db.MaintenanceEntry e) {
    return MaintenanceEntry(
      id: e.id?.toString() ?? '',
      vehicleProfileId: e.vehicleProfileId.toString(),
      entryType: e.typeEntretien,
      date: e.dateEntretien,
      mileageAtService: e.kilometrageEntretien,
      nextServiceMileage: e.rappelKilometrage != 0 ? e.rappelKilometrage : null,
      nextServiceDate: e.rappelDateMs != 0 ? e.rappelDateMs : null,
      notes: e.description.isNotEmpty ? e.description : null,
      receiptPhotoPath:
          e.facturePhotoPath.isNotEmpty ? e.facturePhotoPath : null,
      garage: e.nomGaragiste.isNotEmpty ? e.nomGaragiste : null,
      cost: e.coutEuros,
    );
  }

  db.MaintenanceEntry _mapMaintenanceToDb(
    MaintenanceEntry e,
    int vehicleProfileId,
  ) {
    return db.MaintenanceEntry(
      id: e.id.isNotEmpty ? int.tryParse(e.id) : null,
      vehicleProfileId: vehicleProfileId,
      typeEntretien: e.entryType,
      description: e.notes ?? '',
      kilometrageEntretien: e.mileageAtService,
      coutEuros: e.cost ?? 0.0,
      nomGaragiste: e.garage ?? '',
      facturePhotoPath: e.receiptPhotoPath ?? '',
      dateEntretien: e.date,
      rappelActif: (e.nextServiceMileage != null &&
              e.nextServiceMileage! > 0) ||
          (e.nextServiceDate != null && e.nextServiceDate! > 0),
      rappelKilometrage: e.nextServiceMileage ?? 0,
      rappelDateMs: e.nextServiceDate ?? 0,
    );
  }

  GloveboxDocument _mapDocumentToDomain(db.DocumentEntry e) {
    return GloveboxDocument(
      id: e.id?.toString() ?? '',
      vehicleProfileId: e.vehicleProfileId.toString(),
      documentType: e.typeDocument,
      title: e.nomFichier,
      filePath: e.cheminLocal,
      mimeType: e.typeMime,
      expiryDate: e.dateExpiration == 0 ? null : e.dateExpiration,
      addedAt: e.dateAjout,
    );
  }

  db.DocumentEntry _mapDocumentToDb(
    GloveboxDocument d,
    int vehicleProfileId,
  ) {
    return db.DocumentEntry(
      id: d.id.isNotEmpty ? int.tryParse(d.id) : null,
      vehicleProfileId: vehicleProfileId,
      typeDocument: d.documentType,
      nomFichier: d.title,
      cheminLocal: d.filePath,
      typeMime: d.mimeType,
      dateExpiration: d.expiryDate ?? 0,
      dateAjout: d.addedAt,
    );
  }

  /// Retourne le type MIME à partir de l'extension du fichier (pour enregistrement à l'ajout).
  static String getMimeTypeFromPath(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    const map = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.heic': 'image/heic',
      '.pdf': 'application/pdf',
    };
    return map[ext] ?? '';
  }

  /// Supprime le document de la base et le fichier physique du stockage.
  Future<void> deleteGloveboxDocument(GloveboxDocument doc) async {
    if (await isDemoMode()) return;
    final path = doc.filePath;
    if (path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    final id = int.tryParse(doc.id);
    if (id != null) await db.MabDatabase.instance.deleteDocument(id);
  }

  /// Profil véhicule actif (id mémorisé ou repli). Alias pour l'écran profil.
  Future<VehicleProfile?> getVehicleProfile() => getActiveVehicleProfile();

  /// Id du véhicule actif en base (SharedPreferences). `null` en mode démo ou si non défini.
  Future<int?> getActiveVehicleId() async {
    if (await isDemoMode()) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyActiveVehicleId);
  }

  /// Mémorise le véhicule actif. Sans effet en mode démo.
  Future<void> setActiveVehicleId(int id) async {
    if (await isDemoMode()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyActiveVehicleId, id);
  }

  /// Résout le profil SQLite actif : id mémorisé s'il existe, sinon premier de la liste (tri DB).
  Future<db.VehicleProfile?> _resolveActiveDbProfile() async {
    final list = await db.MabDatabase.instance.getAllVehicleProfiles();
    if (list.isEmpty) return null;
    final activeId = await getActiveVehicleId();
    if (activeId != null) {
      final p =
          await db.MabDatabase.instance.getVehicleProfileById(activeId);
      if (p != null) return p;
    }
    return list.first;
  }

  Future<VehicleProfile?> getActiveVehicleProfile() async {
    if (await isDemoMode()) return demoVehicleProfile;
    final p = await _resolveActiveDbProfile();
    return p == null ? null : _mapToDomain(p);
  }

  /// Tous les profils véhicules (domaine), ordre base de données ; **au plus 2** résultats.
  Future<List<VehicleProfile>> getAllVehicleProfiles() async {
    if (await isDemoMode()) return [];
    final list = await db.MabDatabase.instance.getAllVehicleProfiles();
    return list.take(2).map(_mapToDomain).toList();
  }

  /// Profil par id SQLite (hors démo). En démo : `null`.
  Future<VehicleProfile?> getVehicleProfileById(int id) async {
    if (await isDemoMode()) return null;
    final p = await db.MabDatabase.instance.getVehicleProfileById(id);
    return p == null ? null : _mapToDomain(p);
  }

  /// Supprime un profil et nettoie les prefs OBD associées. Sans effet en démo.
  Future<void> deleteVehicleProfile(int id) async {
    if (await isDemoMode()) return;
    final docEntries =
        await db.MabDatabase.instance.getDocumentsByVehicle(id);
    for (final e in docEntries) {
      await deleteGloveboxDocument(_mapDocumentToDomain(e));
    }
    await db.MabDatabase.instance.deleteVehicleProfile(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefLastObdDate(id));
    await prefs.remove(_prefLastObdDtcs(id));
    await prefs.remove(_prefLastObdMilOn(id));
    await prefs.remove(_prefLastObdDtcsStored(id));
    await prefs.remove(_prefLastObdDtcsPending(id));
    await prefs.remove(_prefLastObdDtcsPermanent(id));
    await prefs.remove(_prefLastObdKm(id));
    await prefs.remove(_prefLastObdDeviceAddress(id));
  }

  /// Résumé texte pour l'IA (ex. "Peugeot 308 2020").
  Future<String?> getVehicleContextSummary() async {
    final profile = await getActiveVehicleProfile();
    if (profile == null) return null;
    return '${profile.brand} ${profile.model} ${profile.year}';
  }

  Future<bool> saveVehicleProfile(VehicleProfile profile) async {
    final d = db.MabDatabase.instance;
    final dbProfile = _mapToDb(profile);
    if (profile.id.isNotEmpty) {
      final id = int.tryParse(profile.id);
      if (id != null && id > 0) {
        await d.updateVehicleProfile(dbProfile);
        return profile.isComplete;
      }
    }
    final newId = await d.insertVehicleProfile(dbProfile);
    if (await getActiveVehicleId() == null) {
      await setActiveVehicleId(newId);
    }
    return profile.isComplete;
  }

  Future<bool> isVehicleProfileComplete() async {
    if (await isDemoMode()) return true;
    return db.MabDatabase.instance.hasProfilComplet();
  }

  Future<List<MaintenanceEntry>> getAllMaintenanceEntries() async {
    if (await isDemoMode()) return demoMaintenanceEntries;
    final profile = await getActiveVehicleProfile();
    if (profile == null || profile.id.isEmpty) return [];
    final vehicleId = int.tryParse(profile.id);
    if (vehicleId == null) return [];
    final list =
        await db.MabDatabase.instance.getMaintenanceByVehicle(vehicleId);
    return list.map(_mapMaintenanceToDomain).toList();
  }

  Future<void> addMaintenanceEntry(MaintenanceEntry entry) async {
    final profile = await getActiveVehicleProfile();
    if (profile == null || profile.id.isEmpty) {
      throw StateError('Aucun profil véhicule actif pour enregistrer un entretien.');
    }
    final vehicleId = int.tryParse(profile.id);
    if (vehicleId == null) {
      throw StateError('Identifiant de véhicule invalide : ${profile.id}.');
    }
    final dbEntry = _mapMaintenanceToDb(entry, vehicleId);
    await db.MabDatabase.instance.insertMaintenanceEntry(dbEntry);
  }

  Future<void> updateMaintenanceEntry(MaintenanceEntry entry) async {
    final profile = await getActiveVehicleProfile();
    if (profile == null || profile.id.isEmpty) {
      throw StateError('Aucun profil véhicule actif pour mettre à jour un entretien.');
    }
    final vehicleId = int.tryParse(profile.id);
    if (vehicleId == null) {
      throw StateError('Identifiant de véhicule invalide : ${profile.id}.');
    }
    final dbEntry = _mapMaintenanceToDb(entry, vehicleId);
    await db.MabDatabase.instance.updateMaintenanceEntry(dbEntry);
  }

  /// Supprime une intervention du carnet (fichier facture inclus si présent). Ignoré en mode démo.
  Future<void> deleteMaintenanceEntry(String id) async {
    if (await isDemoMode()) return;
    final parsed = int.tryParse(id);
    if (parsed == null) return;
    final entry = await getMaintenanceEntryById(parsed);
    if (entry == null) return;
    final profile = await getActiveVehicleProfile();
    if (profile == null || profile.id.isEmpty) return;
    if (entry.vehicleProfileId != profile.id) return;
    await db.MabDatabase.instance.deleteMaintenanceEntry(id);
  }

  Future<MaintenanceEntry?> getMaintenanceEntryById(int id) async {
    final e = await db.MabDatabase.instance.getMaintenanceEntryById(id);
    if (e == null) return null;
    return _mapMaintenanceToDomain(e);
  }

  static const _keyActiveVehicleId = 'mab_active_vehicle_id';
  static const _keyDemoMode = 'mab_demo_mode';
  static const _keyDemoObdScenario = 'mab_demo_obd_scenario';

  static String _prefLastObdDate(int vehicleId) =>
      'mab_last_obd_date_$vehicleId';
  /// Ancienne clé (liste plate) — conservée uniquement pour `remove` lors de la suppression de profil.
  static String _prefLastObdDtcs(int vehicleId) =>
      'mab_last_obd_dtcs_$vehicleId';
  static String _prefLastObdMilOn(int vehicleId) =>
      'mab_last_obd_mil_$vehicleId';
  static String _prefLastObdDtcsStored(int vehicleId) =>
      'mab_last_obd_dtcs_stored_$vehicleId';
  static String _prefLastObdDtcsPending(int vehicleId) =>
      'mab_last_obd_dtcs_pending_$vehicleId';
  static String _prefLastObdDtcsPermanent(int vehicleId) =>
      'mab_last_obd_dtcs_permanent_$vehicleId';
  static String _prefLastObdDeviceAddress(int vehicleId) =>
      'mab_last_obd_device_address_$vehicleId';
  static String _prefLastObdKm(int vehicleId) => 'mab_last_obd_km_$vehicleId';

  /// Id du véhicule actif pour les prefs OBD (hors démo). `null` si aucun profil.
  Future<int?> _activeVehicleIdForObdPrefs() async {
    if (await isDemoMode()) return null;
    final p = await _resolveActiveDbProfile();
    return p?.id;
  }

  /// Adresse MAC du dernier dongle OBD pour le véhicule actif (Bluetooth).
  Future<void> setLastObdDeviceAddress(String address) async {
    if (address.isEmpty) return;
    if (await isDemoMode()) return;
    final vid = await _activeVehicleIdForObdPrefs();
    if (vid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLastObdDeviceAddress(vid), address);
  }

  Future<String?> getLastObdDeviceAddress() async {
    if (await isDemoMode()) return null;
    final vid = await _activeVehicleIdForObdPrefs();
    if (vid == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefLastObdDeviceAddress(vid));
  }

  Future<bool> isDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDemoMode) ?? false;
  }

  Future<void> setDemoMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDemoMode, value);
    if (!value) await prefs.remove(_keyDemoObdScenario);
  }

  Future<String> getDemoObdScenario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDemoObdScenario) ?? 'green';
  }

  Future<void> setDemoObdScenario(String scenario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDemoObdScenario, scenario);
  }

  /// Enregistre le dernier diagnostic OBD pour le véhicule actif (hors démo).
  Future<void> saveLastObdDiagnostic(
    DateTime date, {
    required bool milOn,
    required List<String> storedDtcs,
    required List<String> pendingDtcs,
    required List<String> permanentDtcs,
    required int kmAtScan,
  }) async {
    if (await isDemoMode()) return;
    final vid = await _activeVehicleIdForObdPrefs();
    if (vid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLastObdDate(vid), date.toIso8601String());
    await prefs.setBool(_prefLastObdMilOn(vid), milOn);
    await prefs.setStringList(_prefLastObdDtcsStored(vid), storedDtcs);
    await prefs.setStringList(_prefLastObdDtcsPending(vid), pendingDtcs);
    await prefs.setStringList(_prefLastObdDtcsPermanent(vid), permanentDtcs);
    await prefs.setInt(_prefLastObdKm(vid), kmAtScan);
  }

  /// Enregistre une ligne dans [diagnostic_entries] (historique complet), même conditions que [saveLastObdDiagnostic].
  Future<void> appendObdDiagnosticHistory({
    required DateTime scanDate,
    required int kmAtScan,
    required bool milOn,
    required List<String> storedDtcs,
    required List<String> pendingDtcs,
    required List<String> permanentDtcs,
    required String urgenceLevel,
    required String resumeGlobal,
  }) async {
    if (await isDemoMode()) return;
    final vid = await _activeVehicleIdForObdPrefs();
    if (vid == null) return;
    final payload = jsonEncode({
      'milOn': milOn,
      'stored': storedDtcs,
      'pending': pendingDtcs,
      'permanent': permanentDtcs,
    });
    await db.MabDatabase.instance.insertDiagnosticEntry(
      db.DiagnosticEntry(
        vehicleProfileId: vid,
        dtcCodesJson: payload,
        urgenceLevel: urgenceLevel,
        resumeGlobal: resumeGlobal,
        kilometrageAuScan: kmAtScan,
        estEffacable: true,
        dateCreation: scanDate.millisecondsSinceEpoch,
      ),
    );
  }

  /// Liste des diagnostics OBD enregistrés pour un véhicule (plus récent en premier). Vide en mode démo.
  Future<List<ObdDiagnosticHistoryEntry>> getObdDiagnosticsForVehicle(
    int vehicleId,
  ) async {
    if (await isDemoMode()) return [];
    final list =
        await db.MabDatabase.instance.getDiagnosticsByVehicle(vehicleId);
    return list.map(_mapDiagnosticHistoryToDomain).toList();
  }

  ObdDiagnosticHistoryEntry _mapDiagnosticHistoryToDomain(
    db.DiagnosticEntry e,
  ) {
    var milOn = false;
    var stored = <String>[];
    var pending = <String>[];
    var permanent = <String>[];
    try {
      final decoded = jsonDecode(e.dtcCodesJson);
      if (decoded is Map<String, dynamic>) {
        milOn = decoded['milOn'] as bool? ?? false;
        stored = _stringListFromJson(decoded['stored']);
        pending = _stringListFromJson(decoded['pending']);
        permanent = _stringListFromJson(decoded['permanent']);
      }
    } catch (_) {
      // JSON absent ou invalide : champs codes restent vides
    }
    return ObdDiagnosticHistoryEntry(
      id: e.id?.toString() ?? '',
      vehicleProfileId: e.vehicleProfileId,
      scanDate: DateTime.fromMillisecondsSinceEpoch(e.dateCreation),
      kilometrageAuScan: e.kilometrageAuScan,
      milOn: milOn,
      storedDtcs: stored,
      pendingDtcs: pending,
      permanentDtcs: permanent,
      urgenceLevel: e.urgenceLevel,
      resumeGlobal: e.resumeGlobal,
    );
  }

  List<String> _stringListFromJson(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  /// Empreinte « communautaire » : même marque / modèle / année / motorisation (normalisé).
  static String vehicleFingerprint(VehicleProfile profile) {
    String norm(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return '${norm(profile.brand)}|${norm(profile.model)}|${profile.year}|'
        '${norm(profile.motorisation)}';
  }

  /// JSON brut des valeurs constructeur pour ce profil SQLite. `null` si absent ou démo.
  Future<String?> getVehicleReferenceJson(int vehicleProfileId) async {
    if (await isDemoMode()) return null;
    final row = await db.MabDatabase.instance
        .getVehicleReferenceByVehicleId(vehicleProfileId);
    return row?.jsonValues;
  }

  /// Référence déjà connue pour la même empreinte (autre véhicule). `null` si aucune.
  Future<String?> getCommunityReferenceJson(
    String fingerprint, {
    int? excludeVehicleId,
  }) async {
    if (await isDemoMode()) return null;
    final row = await db.MabDatabase.instance.getReferenceByFingerprintForReuse(
      fingerprint,
      excludeVehicleId: excludeVehicleId,
    );
    return row?.jsonValues;
  }

  /// Enregistre les valeurs constructeur pour un profil (remplace si déjà présent).
  Future<void> saveVehicleReferenceValues({
    required int vehicleProfileId,
    required String fingerprint,
    required String jsonValues,
  }) async {
    if (await isDemoMode()) return;
    await db.MabDatabase.instance.deleteVehicleReferenceByVehicleId(
      vehicleProfileId,
    );
    await db.MabDatabase.instance.insertVehicleReferenceValue(
      db.VehicleReferenceValueEntry(
        vehicleProfileId: vehicleProfileId,
        fingerprint: fingerprint,
        jsonValues: jsonValues,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<db.VehicleLearnedValuesEntry?> getVehicleLearnedValuesEntry(
    int vehicleProfileId,
  ) async {
    if (await isDemoMode()) return null;
    return db.MabDatabase.instance.getVehicleLearnedValues(vehicleProfileId);
  }

  Future<void> upsertVehicleLearnedValuesEntry(
    db.VehicleLearnedValuesEntry entry,
  ) async {
    if (await isDemoMode()) return;
    await db.MabDatabase.instance.upsertVehicleLearnedValues(entry);
  }

  Future<void> appendVehicleHealthAlert({
    required int vehicleProfileId,
    required int level,
    required String message,
    String? technicalDetail,
  }) async {
    if (await isDemoMode()) return;
    await db.MabDatabase.instance.insertVehicleHealthAlert(
      db.VehicleHealthAlertHistoryEntry(
        vehicleProfileId: vehicleProfileId,
        level: level,
        message: message,
        technicalDetail: technicalDetail,
        createdMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<List<VehicleHealthAlertItem>> listVehicleHealthAlerts(
    int vehicleProfileId, {
    int limit = 50,
  }) async {
    if (await isDemoMode()) return [];
    final rows = await db.MabDatabase.instance.getVehicleHealthAlerts(
      vehicleProfileId,
      limit: limit,
    );
    return rows
        .map(
          (e) => VehicleHealthAlertItem(
            id: e.id?.toString() ?? '',
            level: e.level,
            message: e.message,
            technicalDetail: e.technicalDetail,
            createdAt: DateTime.fromMillisecondsSinceEpoch(e.createdMs),
          ),
        )
        .toList();
  }

  /// Dernier diagnostic OBD (date, MIL, km au scan, codes par catégorie, liste combinée).
  Future<
      ({
        DateTime? date,
        bool milOn,
        int kmAtScan,
        List<String> storedDtcs,
        List<String> pendingDtcs,
        List<String> permanentDtcs,
        List<String> dtcs,
      })> getLastObdDiagnostic() async {
    if (await isDemoMode()) {
      final scenario = await getDemoObdScenario();
      final result = getDemoObdResult(scenario);
      return (
        date: DateTime.now(),
        milOn: result.milOn,
        kmAtScan: demoVehicleProfile.mileage,
        storedDtcs: result.storedDtcs,
        pendingDtcs: result.pendingDtcs,
        permanentDtcs: result.permanentDtcs,
        dtcs: result.dtcs,
      );
    }
    final vid = await _activeVehicleIdForObdPrefs();
    if (vid == null) {
      return (
        date: null,
        milOn: false,
        kmAtScan: 0,
        storedDtcs: <String>[],
        pendingDtcs: <String>[],
        permanentDtcs: <String>[],
        dtcs: <String>[],
      );
    }
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_prefLastObdDate(vid));
    final parsed = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final milOn = prefs.getBool(_prefLastObdMilOn(vid)) ?? false;
    final kmAtScan = prefs.getInt(_prefLastObdKm(vid)) ?? 0;
    final storedDtcs = prefs.getStringList(_prefLastObdDtcsStored(vid)) ?? [];
    final pendingDtcs = prefs.getStringList(_prefLastObdDtcsPending(vid)) ?? [];
    final permanentDtcs =
        prefs.getStringList(_prefLastObdDtcsPermanent(vid)) ?? [];
    final dtcs = <String>[
      ...storedDtcs,
      ...pendingDtcs,
      ...permanentDtcs,
    ];
    return (
      date: parsed,
      milOn: milOn,
      kmAtScan: kmAtScan,
      storedDtcs: storedDtcs,
      pendingDtcs: pendingDtcs,
      permanentDtcs: permanentDtcs,
      dtcs: dtcs,
    );
  }

  static String _obdCodeCategoryLine(String label, List<String> codes) {
    return codes.isEmpty ? '$label : aucun' : '$label : ${codes.join(", ")}';
  }

  /// Les 3 dernières entrées du carnet d'entretien (par date décroissante).
  Future<List<MaintenanceEntry>> getLast3MaintenanceEntries() async {
    if (await isDemoMode()) return demoMaintenanceEntries.take(3).toList();
    final all = await getAllMaintenanceEntries();
    final sorted = List<MaintenanceEntry>.from(all)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(3).toList();
  }

  /// Contexte véhicule formaté pour le system prompt IA (invisible à l'utilisateur).
  /// Retourne null si le profil véhicule est incomplet (en mode normal).
  Future<String?> getAiSystemContextString() async {
    if (await isDemoMode()) {
      final profile = demoVehicleProfile;
      final scenario = await getDemoObdScenario();
      final result = getDemoObdResult(scenario);
      final last3 = demoMaintenanceEntries.take(3).toList();
      final vehicleLine = _vehicleLineForAi(profile);
      final now = DateTime.now();
      final df =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final milText = result.milOn
          ? 'Témoin Check Engine : ALLUMÉ'
          : 'Témoin Check Engine : éteint';
      final obdBlock = 'Dernier diagnostic OBD (démo) du $df. '
          'Kilométrage au diagnostic : ${profile.mileage} km. $milText '
          '${_obdCodeCategoryLine('Codes mémorisés', result.storedDtcs)} '
          '${_obdCodeCategoryLine('Codes en attente', result.pendingDtcs)} '
          '${_obdCodeCategoryLine('Codes permanents', result.permanentDtcs)}.';
      final maintenanceLine = last3.isEmpty
          ? 'Aucun entretien enregistré.'
          : 'Derniers entretiens : ${last3.map((e) => '${e.entryType} ${e.mileageAtService} km').join(", ")}.';
      return '$vehicleLine $obdBlock $maintenanceLine '
          'Réponds en tenant compte de ce véhicule (mode démo).';
    }
    final profile = await getActiveVehicleProfile();
    if (profile == null || !profile.isComplete) return null;

    final lastObd = await getLastObdDiagnostic();
    final last3 = await getLast3MaintenanceEntries();

    final vehicleLine = _vehicleLineForAi(profile);

    final String obdBlock;
    if (lastObd.date != null) {
      final dateFormatted =
          '${lastObd.date!.day.toString().padLeft(2, '0')}/${lastObd.date!.month.toString().padLeft(2, '0')}/${lastObd.date!.year}';
      final milText = lastObd.milOn
          ? 'Témoin Check Engine : ALLUMÉ'
          : 'Témoin Check Engine : éteint';
      obdBlock = 'Dernier diagnostic OBD du $dateFormatted. '
          'Kilométrage au diagnostic : ${lastObd.kmAtScan} km. $milText '
          '${_obdCodeCategoryLine('Codes mémorisés', lastObd.storedDtcs)} '
          '${_obdCodeCategoryLine('Codes en attente', lastObd.pendingDtcs)} '
          '${_obdCodeCategoryLine('Codes permanents', lastObd.permanentDtcs)}.';
    } else {
      obdBlock = 'Aucun diagnostic OBD enregistré récemment.';
    }

    String maintenanceLine;
    if (last3.isEmpty) {
      maintenanceLine = 'Aucun entretien enregistré dans le carnet.';
    } else {
      final parts = last3.map((e) => '${e.entryType} ${e.mileageAtService} km').toList();
      maintenanceLine = 'Derniers entretiens : ${parts.join(", ")}.';
    }

    return '$vehicleLine $obdBlock $maintenanceLine '
        'Réponds toujours en tenant compte de ce véhicule précis. '
        'Si des codes défaut sont mentionnés, précise à l\'utilisateur qu\'ils datent du dernier diagnostic '
        'et qu\'il peut les effacer s\'ils ont déjà été réparés.';
  }

  /// Rappels entretien (basés sur rappel_kilometrage / rappel_date_ms).
  Future<List<MaintenanceEntry>> getUpcomingMaintenanceAlerts(int currentKm) async {
    if (await isDemoMode()) {
      return demoMaintenanceEntries.where((e) =>
          (e.nextServiceMileage != null && currentKm >= e.nextServiceMileage! - 500) ||
          (e.nextServiceDate != null &&
              DateTime.now().isAfter(DateTime.fromMillisecondsSinceEpoch(e.nextServiceDate!)
                  .subtract(const Duration(days: 30))))).toList();
    }
    final profile = await getActiveVehicleProfile();
    if (profile == null || profile.id.isEmpty) return [];
    final vehicleId = int.tryParse(profile.id);
    if (vehicleId == null) return [];

    final now = DateTime.now();
    final list = await db.MabDatabase.instance.getMaintenanceAvecRappel();
    final result = <MaintenanceEntry>[];

    for (final e in list) {
      if (e.vehicleProfileId != vehicleId) continue;

      final hasKmReminder = e.rappelKilometrage > 0;
      final hasDateReminder = e.rappelDateMs > 0;

      var include = false;

      if (hasKmReminder) {
        final warnKm = e.rappelKilometrage - 500;
        if (currentKm >= warnKm) {
          include = true;
        }
      }

      if (!include && hasDateReminder) {
        final reminderDate =
            DateTime.fromMillisecondsSinceEpoch(e.rappelDateMs);
        final warnDate = reminderDate.subtract(const Duration(days: 30));
        if (now.isAfter(warnDate)) {
          include = true;
        }
      }

      if (include) {
        result.add(_mapMaintenanceToDomain(e));
      }
    }

    return result;
  }

  Future<List<GloveboxDocument>> getAllGloveboxDocuments() async {
    if (await isDemoMode()) return demoDocuments;
    final profile = await getActiveVehicleProfile();
    if (profile == null || profile.id.isEmpty) return [];
    final vehicleId = int.tryParse(profile.id);
    if (vehicleId == null) return [];
    final list = await db.MabDatabase.instance.getDocumentsByVehicle(vehicleId);
    return list.map(_mapDocumentToDomain).toList();
  }

  /// Copie un fichier (photo ou import) dans le répertoire permanent de l'app.
  /// À appeler avant d'enregistrer le document en base pour que le chemin
  /// reste valide après fermeture de l'app et suppression des fichiers temporaires.
  /// Retourne le chemin absolu du fichier copié.
  Future<String> copyDocumentToAppStorage(String sourceFilePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final subdir = Directory(p.join(dir.path, 'glovebox_documents'));
    if (!await subdir.exists()) await subdir.create(recursive: true);
    final ext = p.extension(sourceFilePath).isEmpty ? '.jpg' : p.extension(sourceFilePath);
    final name = 'doc_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(subdir.path, name);
    await File(sourceFilePath).copy(destPath);
    return destPath;
  }

  Future<void> addGloveboxDocument(GloveboxDocument doc) async {
    final profile = await getActiveVehicleProfile();
    if (profile == null || profile.id.isEmpty) {
      throw StateError(
          'Aucun profil véhicule actif pour enregistrer un document.');
    }
    final vehicleId = int.tryParse(profile.id);
    if (vehicleId == null) {
      throw StateError('Identifiant de véhicule invalide : ${profile.id}.');
    }
    final dbDoc = _mapDocumentToDb(doc, vehicleId);
    await db.MabDatabase.instance.insertDocument(dbDoc);
  }

  /// Documents proches d'expiration (stub : liste vide). En démo, renvoie les docs avec date.
  Future<List<GloveboxDocument>> getExpiringDocuments() async {
    if (await isDemoMode()) {
      final now = DateTime.now();
      return demoDocuments.where((d) {
        if (d.expiryDate == null) return false;
        final exp = DateTime.fromMillisecondsSinceEpoch(d.expiryDate!);
        return exp.isBefore(now.add(const Duration(days: 60)));
      }).toList();
    }
    return [];
  }
}
