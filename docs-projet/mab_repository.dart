// mab_repository.dart — Mécano à Bord (Flutter iOS + Android)
//
// Rôle : pont entre la base de données (MabDatabase) et le reste de l'application.
// L'application ne parle JAMAIS directement à la base de données.
// Elle passe toujours par ce Repository.
//
// Contient :
//  - Gestion du profil véhicule (VehicleProfile)
//  - Gestion des diagnostics OBD (DiagnosticSession)
//  - Gestion du carnet d'entretien (MaintenanceEntry)
//  - Gestion des documents Boîte à gants (GloveboxDocument)
//  - Règle de sécurité : pas de diagnostic OBD sans profil véhicule complet

import 'package:sqflite/sqflite.dart';
import 'mab_database.dart';

// ─────────────────────────────────────────────
// MODÈLES DE DOMAINE
// ─────────────────────────────────────────────

/// Niveaux de risque d'un diagnostic (3 couleurs)
enum RiskLevel { green, orange, red }

/// Profil du véhicule — source de vérité unique
class VehicleProfile {
  final String id;
  final String brand;
  final String model;
  final int year;
  final int mileage;
  final String gearboxType;   // "MANUELLE" ou "AUTOMATIQUE"
  final String fuelType;
  final String licensePlate;
  final String vin;

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
  });

  /// Un profil est "complet" uniquement si le kilométrage ET
  /// le type de boîte sont renseignés.
  bool get isComplete => mileage > 0 && gearboxType.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'id': id,
    'brand': brand,
    'model': model,
    'year': year,
    'mileage': mileage,
    'gearboxType': gearboxType,
    'fuelType': fuelType,
    'licensePlate': licensePlate,
    'vin': vin,
    'isActive': 1,
  };

  factory VehicleProfile.fromMap(Map<String, dynamic> map) => VehicleProfile(
    id: map['id'] as String,
    brand: map['brand'] as String,
    model: map['model'] as String,
    year: map['year'] as int,
    mileage: map['mileage'] as int,
    gearboxType: map['gearboxType'] as String,
    fuelType: map['fuelType'] as String,
    licensePlate: map['licensePlate'] as String? ?? '',
    vin: map['vin'] as String? ?? '',
  );
}

/// Résultat d'un scan OBD (une session de diagnostic)
class DiagnosticSession {
  final String id;
  final String vehicleProfileId;
  final int timestamp;         // Date/heure en millisecondes
  final RiskLevel riskLevel;   // VERT / ORANGE / ROUGE
  final List<String> dtcCodes; // Codes d'erreur détectés
  final String humanSummary;   // Explication en langage humain

  DiagnosticSession({
    required this.id,
    required this.vehicleProfileId,
    required this.timestamp,
    required this.riskLevel,
    required this.dtcCodes,
    required this.humanSummary,
  });

  bool get isCritical => riskLevel == RiskLevel.red;

  Map<String, dynamic> toMap() => {
    'id': id,
    'vehicleProfileId': vehicleProfileId,
    'timestamp': timestamp,
    'riskLevel': riskLevel.name,
    'dtcCodes': dtcCodes.join(','),
    'humanSummary': humanSummary,
    'isCritical': isCritical ? 1 : 0,
  };

  factory DiagnosticSession.fromMap(Map<String, dynamic> map) => DiagnosticSession(
    id: map['id'] as String,
    vehicleProfileId: map['vehicleProfileId'] as String,
    timestamp: map['timestamp'] as int,
    riskLevel: RiskLevel.values.firstWhere(
      (e) => e.name == map['riskLevel'],
      orElse: () => RiskLevel.green,
    ),
    dtcCodes: (map['dtcCodes'] as String).isEmpty
        ? []
        : (map['dtcCodes'] as String).split(','),
    humanSummary: map['humanSummary'] as String,
  );
}

/// Entrée dans le carnet d'entretien
class MaintenanceEntry {
  final String id;
  final String vehicleProfileId;
  final String entryType;           // Ex: "VIDANGE", "PNEUS", "FREINS"
  final int date;                   // Date de l'entretien (millisecondes)
  final int mileageAtService;       // Kilométrage au moment de l'entretien
  final int? nextServiceMileage;    // Kilométrage du prochain entretien
  final int? nextServiceDate;       // Date du prochain entretien
  final String? notes;
  final String? receiptPhotoPath;   // Chemin vers la photo de la facture

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
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'vehicleProfileId': vehicleProfileId,
    'entryType': entryType,
    'date': date,
    'mileageAtService': mileageAtService,
    'nextServiceMileage': nextServiceMileage,
    'nextServiceDate': nextServiceDate,
    'notes': notes,
    'receiptPhotoPath': receiptPhotoPath,
  };

  factory MaintenanceEntry.fromMap(Map<String, dynamic> map) => MaintenanceEntry(
    id: map['id'] as String,
    vehicleProfileId: map['vehicleProfileId'] as String,
    entryType: map['entryType'] as String,
    date: map['date'] as int,
    mileageAtService: map['mileageAtService'] as int,
    nextServiceMileage: map['nextServiceMileage'] as int?,
    nextServiceDate: map['nextServiceDate'] as int?,
    notes: map['notes'] as String?,
    receiptPhotoPath: map['receiptPhotoPath'] as String?,
  );
}

/// Document stocké dans la Boîte à gants
class GloveboxDocument {
  final String id;
  final String vehicleProfileId;
  final String documentType;   // Ex: "CARTE_GRISE", "ASSURANCE", "CONTROLE_TECHNIQUE"
  final String title;
  final String filePath;
  final int? expiryDate;       // Date d'expiration (millisecondes), peut être null
  final int addedAt;

  GloveboxDocument({
    required this.id,
    required this.vehicleProfileId,
    required this.documentType,
    required this.title,
    required this.filePath,
    this.expiryDate,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'vehicleProfileId': vehicleProfileId,
    'documentType': documentType,
    'title': title,
    'filePath': filePath,
    'expiryDate': expiryDate,
    'addedAt': addedAt,
  };

  factory GloveboxDocument.fromMap(Map<String, dynamic> map) => GloveboxDocument(
    id: map['id'] as String,
    vehicleProfileId: map['vehicleProfileId'] as String,
    documentType: map['documentType'] as String,
    title: map['title'] as String,
    filePath: map['filePath'] as String,
    expiryDate: map['expiryDate'] as int?,
    addedAt: map['addedAt'] as int,
  );
}

// ─────────────────────────────────────────────
// REPOSITORY PRINCIPAL
// ─────────────────────────────────────────────

class MabRepository {
  final MabDatabase _mabDatabase;

  MabRepository(this._mabDatabase);

  Future<Database> get _db async => await _mabDatabase.database;

  // ─────────────────────────────────────────────
  // PROFIL VÉHICULE
  // ─────────────────────────────────────────────

  /// Récupère le profil véhicule actif.
  /// Retourne null si aucun profil n'existe encore.
  Future<VehicleProfile?> getActiveVehicleProfile() async {
    final db = await _db;
    final results = await db.query(
      'vehicle_profiles',
      where: 'isActive = 1',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return VehicleProfile.fromMap(results.first);
  }

  /// Enregistre ou met à jour un profil véhicule.
  /// Retourne true si le profil est complet.
  Future<bool> saveVehicleProfile(VehicleProfile profile) async {
    final db = await _db;
    await db.insert(
      'vehicle_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return profile.isComplete;
  }

  /// Règle de sécurité : vérifie qu'un profil complet existe
  /// avant d'autoriser le démarrage d'un diagnostic OBD réel.
  Future<bool> isVehicleProfileComplete() async {
    final profile = await getActiveVehicleProfile();
    if (profile == null) return false;
    return profile.isComplete;
  }

  // ─────────────────────────────────────────────
  // DIAGNOSTICS OBD
  // ─────────────────────────────────────────────

  /// Enregistre une session de diagnostic.
  Future<void> saveDiagnosticSession(DiagnosticSession session) async {
    final db = await _db;
    await db.insert(
      'diagnostic_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère toutes les sessions, de la plus récente à la plus ancienne.
  Future<List<DiagnosticSession>> getAllDiagnosticSessions() async {
    final db = await _db;
    final results = await db.query(
      'diagnostic_sessions',
      orderBy: 'timestamp DESC',
    );
    return results.map((map) => DiagnosticSession.fromMap(map)).toList();
  }

  /// Récupère une session par son identifiant unique.
  Future<DiagnosticSession?> getDiagnosticSessionById(String id) async {
    final db = await _db;
    final results = await db.query(
      'diagnostic_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return DiagnosticSession.fromMap(results.first);
  }

  /// Règle de sécurité : supprime uniquement les diagnostics verts et oranges.
  /// Les alertes ROUGES ne peuvent jamais être supprimées.
  Future<void> clearNonCriticalDiagnostics() async {
    final db = await _db;
    await db.delete(
      'diagnostic_sessions',
      where: 'isCritical = 0',
    );
  }

  // ─────────────────────────────────────────────
  // CARNET D'ENTRETIEN
  // ─────────────────────────────────────────────

  /// Enregistre une nouvelle entrée dans le carnet.
  Future<void> saveMaintenanceEntry(MaintenanceEntry entry) async {
    final db = await _db;
    await db.insert(
      'maintenance_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Met à jour une entrée existante du carnet.
  Future<void> updateMaintenanceEntry(MaintenanceEntry entry) async {
    final db = await _db;
    await db.update(
      'maintenance_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Supprime une entrée du carnet.
  Future<void> deleteMaintenanceEntry(String entryId) async {
    final db = await _db;
    await db.delete(
      'maintenance_entries',
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  /// Récupère tout le carnet d'entretien, du plus récent au plus ancien.
  Future<List<MaintenanceEntry>> getAllMaintenanceEntries() async {
    final db = await _db;
    final results = await db.query(
      'maintenance_entries',
      orderBy: 'date DESC',
    );
    return results.map((map) => MaintenanceEntry.fromMap(map)).toList();
  }

  /// Récupère les entretiens dont le rappel approche.
  /// Seuil kilométrage : 500 km avant la limite.
  /// Seuil date : 30 jours avant la date limite.
  Future<List<MaintenanceEntry>> getUpcomingMaintenanceAlerts(int currentKm) async {
    final db = await _db;
    final kmThreshold = currentKm + 500;
    final dateThreshold = DateTime.now()
        .add(const Duration(days: 30))
        .millisecondsSinceEpoch;

    final results = await db.query(
      'maintenance_entries',
      where: '(nextServiceMileage IS NOT NULL AND nextServiceMileage <= ?) '
             'OR (nextServiceDate IS NOT NULL AND nextServiceDate <= ?)',
      whereArgs: [kmThreshold, dateThreshold],
      orderBy: 'date DESC',
    );
    return results.map((map) => MaintenanceEntry.fromMap(map)).toList();
  }

  // ─────────────────────────────────────────────
  // BOÎTE À GANTS — DOCUMENTS
  // ─────────────────────────────────────────────

  /// Enregistre un document dans la Boîte à gants.
  Future<void> saveGloveboxDocument(GloveboxDocument document) async {
    final db = await _db;
    await db.insert(
      'glovebox_documents',
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Supprime un document de la Boîte à gants.
  Future<void> deleteGloveboxDocument(String documentId) async {
    final db = await _db;
    await db.delete(
      'glovebox_documents',
      where: 'id = ?',
      whereArgs: [documentId],
    );
  }

  /// Récupère tous les documents de la Boîte à gants.
  Future<List<GloveboxDocument>> getAllGloveboxDocuments() async {
    final db = await _db;
    final results = await db.query(
      'glovebox_documents',
      orderBy: 'addedAt DESC',
    );
    return results.map((map) => GloveboxDocument.fromMap(map)).toList();
  }

  /// Récupère les documents proches de leur date d'expiration (dans les 30 prochains jours).
  Future<List<GloveboxDocument>> getExpiringDocuments() async {
    final db = await _db;
    final threshold = DateTime.now()
        .add(const Duration(days: 30))
        .millisecondsSinceEpoch;

    final results = await db.query(
      'glovebox_documents',
      where: 'expiryDate IS NOT NULL AND expiryDate <= ?',
      whereArgs: [threshold],
      orderBy: 'expiryDate ASC',
    );
    return results.map((map) => GloveboxDocument.fromMap(map)).toList();
  }
}
