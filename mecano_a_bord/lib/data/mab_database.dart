// mab_database.dart — Mécano à Bord (Flutter)
// Base de données locale : sqflite.

import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// ─────────────────────────────────────────────
// MODÈLES DE DONNÉES (persistance)
// ─────────────────────────────────────────────

class VehicleProfile {
  final int? id;
  final String marque;
  final String modele;
  final int annee;
  final int kilometrage;
  final String typeBoite;
  final String carburant;
  final String numeroPlaqueImmat;
  final String numeroVin;
  final String motorisation;
  final bool estProfilComplet;
  final int dateCreation;
  final int dateDerniereModif;

  VehicleProfile({
    this.id,
    required this.marque,
    required this.modele,
    required this.annee,
    required this.kilometrage,
    required this.typeBoite,
    required this.carburant,
    this.numeroPlaqueImmat = '',
    this.numeroVin = '',
    this.motorisation = '',
    this.estProfilComplet = false,
    int? dateCreation,
    int? dateDerniereModif,
  })  : dateCreation = dateCreation ?? DateTime.now().millisecondsSinceEpoch,
        dateDerniereModif = dateDerniereModif ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'marque': marque,
    'modele': modele,
    'annee': annee,
    'kilometrage': kilometrage,
    'type_boite': typeBoite,
    'carburant': carburant,
    'numero_plaque_immat': numeroPlaqueImmat,
    'numero_vin': numeroVin,
    'motorisation': motorisation,
    'est_profil_complet': estProfilComplet ? 1 : 0,
    'date_creation': dateCreation,
    'date_derniere_modif': dateDerniereModif,
  };

  factory VehicleProfile.fromMap(Map<String, dynamic> map) => VehicleProfile(
    id: map['id'],
    marque: map['marque'],
    modele: map['modele'],
    annee: map['annee'],
    kilometrage: map['kilometrage'],
    typeBoite: map['type_boite'],
    carburant: map['carburant'],
    numeroPlaqueImmat: map['numero_plaque_immat'] ?? '',
    numeroVin: map['numero_vin'] ?? '',
    motorisation: map['motorisation'] ?? '',
    estProfilComplet: map['est_profil_complet'] == 1,
    dateCreation: map['date_creation'],
    dateDerniereModif: map['date_derniere_modif'],
  );
}

class DiagnosticEntry {
  final int? id;
  final int vehicleProfileId;
  final String dtcCodesJson;
  final String urgenceLevel;
  final String resumeGlobal;
  final int kilometrageAuScan;
  final bool estEffacable;
  final int dateCreation;

  DiagnosticEntry({
    this.id,
    required this.vehicleProfileId,
    required this.dtcCodesJson,
    required this.urgenceLevel,
    required this.resumeGlobal,
    required this.kilometrageAuScan,
    required this.estEffacable,
    int? dateCreation,
  }) : dateCreation = dateCreation ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'vehicle_profile_id': vehicleProfileId,
    'dtc_codes_json': dtcCodesJson,
    'urgence_level': urgenceLevel,
    'resume_global': resumeGlobal,
    'kilometrage_au_scan': kilometrageAuScan,
    'est_effacable': estEffacable ? 1 : 0,
    'date_creation': dateCreation,
  };

  factory DiagnosticEntry.fromMap(Map<String, dynamic> map) => DiagnosticEntry(
    id: map['id'],
    vehicleProfileId: map['vehicle_profile_id'],
    dtcCodesJson: map['dtc_codes_json'],
    urgenceLevel: map['urgence_level'],
    resumeGlobal: map['resume_global'],
    kilometrageAuScan: map['kilometrage_au_scan'],
    estEffacable: map['est_effacable'] == 1,
    dateCreation: map['date_creation'],
  );
}

class MaintenanceEntry {
  final int? id;
  final int vehicleProfileId;
  final String typeEntretien;
  final String description;
  final int kilometrageEntretien;
  final double coutEuros;
  final String nomGaragiste;
  final String facturePhotoPath;
  final int dateEntretien;
  final int dateCreation;
  final bool rappelActif;
  final int rappelKilometrage;
  final int rappelDateMs;

  MaintenanceEntry({
    this.id,
    required this.vehicleProfileId,
    required this.typeEntretien,
    required this.description,
    required this.kilometrageEntretien,
    this.coutEuros = 0.0,
    this.nomGaragiste = '',
    this.facturePhotoPath = '',
    required this.dateEntretien,
    int? dateCreation,
    this.rappelActif = false,
    this.rappelKilometrage = 0,
    this.rappelDateMs = 0,
  }) : dateCreation = dateCreation ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'vehicle_profile_id': vehicleProfileId,
    'type_entretien': typeEntretien,
    'description': description,
    'kilometrage_entretien': kilometrageEntretien,
    'cout_euros': coutEuros,
    'nom_garagiste': nomGaragiste,
    'facture_photo_path': facturePhotoPath,
    'date_entretien': dateEntretien,
    'date_creation': dateCreation,
    'rappel_actif': rappelActif ? 1 : 0,
    'rappel_kilometrage': rappelKilometrage,
    'rappel_date_ms': rappelDateMs,
  };

  factory MaintenanceEntry.fromMap(Map<String, dynamic> map) => MaintenanceEntry(
    id: map['id'],
    vehicleProfileId: map['vehicle_profile_id'],
    typeEntretien: map['type_entretien'],
    description: map['description'],
    kilometrageEntretien: map['kilometrage_entretien'],
    coutEuros: map['cout_euros'] ?? 0.0,
    nomGaragiste: map['nom_garagiste'] ?? '',
    facturePhotoPath: map['facture_photo_path'] ?? '',
    dateEntretien: map['date_entretien'],
    dateCreation: map['date_creation'],
    rappelActif: map['rappel_actif'] == 1,
    rappelKilometrage: map['rappel_kilometrage'] ?? 0,
    rappelDateMs: map['rappel_date_ms'] ?? 0,
  );
}

class DocumentEntry {
  final int? id;
  final int vehicleProfileId;
  final String typeDocument;
  final String nomFichier;
  final String cheminLocal;
  final String typeMime;
  final int? dateExpiration;
  final int dateAjout;

  DocumentEntry({
    this.id,
    required this.vehicleProfileId,
    required this.typeDocument,
    required this.nomFichier,
    required this.cheminLocal,
    this.typeMime = '',
    this.dateExpiration,
    int? dateAjout,
  }) : dateAjout = dateAjout ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'vehicle_profile_id': vehicleProfileId,
    'type_document': typeDocument,
    'nom_fichier': nomFichier,
    'chemin_local': cheminLocal,
    'type_mime': typeMime,
    'date_expiration': dateExpiration,
    'date_ajout': dateAjout,
  };

  factory DocumentEntry.fromMap(Map<String, dynamic> map) => DocumentEntry(
    id: map['id'],
    vehicleProfileId: map['vehicle_profile_id'],
    typeDocument: map['type_document'],
    nomFichier: map['nom_fichier'],
    cheminLocal: map['chemin_local'],
    typeMime: map['type_mime'] as String? ?? '',
    dateExpiration: map['date_expiration'],
    dateAjout: map['date_ajout'],
  );
}

class AlertEntry {
  final int? id;
  final int vehicleProfileId;
  final String dtcCode;
  final String urgenceLevel;
  final String messageAlerte;
  final bool estResolue;
  final bool estEffacable;
  final int dateCreation;
  final int? dateResolution;

  AlertEntry({
    this.id,
    required this.vehicleProfileId,
    required this.dtcCode,
    required this.urgenceLevel,
    required this.messageAlerte,
    this.estResolue = false,
    this.estEffacable = false,
    int? dateCreation,
    this.dateResolution,
  }) : dateCreation = dateCreation ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'vehicle_profile_id': vehicleProfileId,
    'dtc_code': dtcCode,
    'urgence_level': urgenceLevel,
    'message_alerte': messageAlerte,
    'est_resolue': estResolue ? 1 : 0,
    'est_effacable': estEffacable ? 1 : 0,
    'date_creation': dateCreation,
    'date_resolution': dateResolution,
  };

  factory AlertEntry.fromMap(Map<String, dynamic> map) => AlertEntry(
    id: map['id'],
    vehicleProfileId: map['vehicle_profile_id'],
    dtcCode: map['dtc_code'],
    urgenceLevel: map['urgence_level'],
    messageAlerte: map['message_alerte'],
    estResolue: map['est_resolue'] == 1,
    estEffacable: map['est_effacable'] == 1,
    dateCreation: map['date_creation'],
    dateResolution: map['date_resolution'],
  );
}

/// Valeurs de référence constructeur (JSON) pour un profil véhicule.
class VehicleReferenceValueEntry {
  final int? id;
  final int vehicleProfileId;
  final String fingerprint;
  final String jsonValues;
  final int createdAt;

  VehicleReferenceValueEntry({
    this.id,
    required this.vehicleProfileId,
    required this.fingerprint,
    required this.jsonValues,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'vehicle_profile_id': vehicleProfileId,
    'fingerprint': fingerprint,
    'json_values': jsonValues,
    'created_at': createdAt,
  };

  factory VehicleReferenceValueEntry.fromMap(Map<String, dynamic> map) =>
      VehicleReferenceValueEntry(
        id: map['id'] as int?,
        vehicleProfileId: map['vehicle_profile_id'] as int,
        fingerprint: map['fingerprint'] as String,
        jsonValues: map['json_values'] as String,
        createdAt: map['created_at'] as int,
      );
}

/// Agrégats d’apprentissage OBD (14 jours) pour un profil.
class VehicleLearnedValuesEntry {
  final int vehicleProfileId;
  final int learningStartedMs;
  final int? lastSampleMs;
  final bool learningCompleted;
  final String aggregatesJson;
  final int sampleCount;
  final int? lastPositiveBilanMs;

  VehicleLearnedValuesEntry({
    required this.vehicleProfileId,
    required this.learningStartedMs,
    this.lastSampleMs,
    required this.learningCompleted,
    required this.aggregatesJson,
    required this.sampleCount,
    this.lastPositiveBilanMs,
  });

  Map<String, dynamic> toMap() => {
    'vehicle_profile_id': vehicleProfileId,
    'learning_started_ms': learningStartedMs,
    'last_sample_ms': lastSampleMs,
    'learning_completed': learningCompleted ? 1 : 0,
    'aggregates_json': aggregatesJson,
    'sample_count': sampleCount,
    'last_positive_bilan_ms': lastPositiveBilanMs,
  };

  factory VehicleLearnedValuesEntry.fromMap(Map<String, dynamic> map) =>
      VehicleLearnedValuesEntry(
        vehicleProfileId: map['vehicle_profile_id'] as int,
        learningStartedMs: map['learning_started_ms'] as int,
        lastSampleMs: map['last_sample_ms'] as int?,
        learningCompleted: map['learning_completed'] == 1,
        aggregatesJson: map['aggregates_json'] as String? ?? '{}',
        sampleCount: map['sample_count'] as int? ?? 0,
        lastPositiveBilanMs: map['last_positive_bilan_ms'] as int?,
      );
}

/// Ligne d’historique d’alerte / bilan « santé véhicule ».
class VehicleHealthAlertHistoryEntry {
  final int? id;
  final int vehicleProfileId;
  final int level;
  final String message;
  final String? technicalDetail;
  final int createdMs;

  VehicleHealthAlertHistoryEntry({
    this.id,
    required this.vehicleProfileId,
    required this.level,
    required this.message,
    this.technicalDetail,
    required this.createdMs,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'vehicle_profile_id': vehicleProfileId,
    'level': level,
    'message': message,
    'technical_detail': technicalDetail,
    'created_ms': createdMs,
  };

  factory VehicleHealthAlertHistoryEntry.fromMap(Map<String, dynamic> map) =>
      VehicleHealthAlertHistoryEntry(
        id: map['id'] as int?,
        vehicleProfileId: map['vehicle_profile_id'] as int,
        level: map['level'] as int,
        message: map['message'] as String,
        technicalDetail: map['technical_detail'] as String?,
        createdMs: map['created_ms'] as int,
      );
}

// ─────────────────────────────────────────────
// BASE DE DONNÉES
// ─────────────────────────────────────────────

class MabDatabase {
  static const String _dbName = 'mab_database.db';
  static const int _dbVersion = 5;

  static MabDatabase? _instance;
  static Database? _database;

  MabDatabase._internal();

  static MabDatabase get instance {
    _instance ??= MabDatabase._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final p = join(dbPath, _dbName);
    return openDatabase(
      p,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicle_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        marque TEXT NOT NULL,
        modele TEXT NOT NULL,
        annee INTEGER NOT NULL,
        kilometrage INTEGER NOT NULL DEFAULT 0,
        type_boite TEXT NOT NULL DEFAULT '',
        carburant TEXT NOT NULL DEFAULT '',
        numero_plaque_immat TEXT DEFAULT '',
        numero_vin TEXT DEFAULT '',
        motorisation TEXT NOT NULL DEFAULT '',
        est_profil_complet INTEGER NOT NULL DEFAULT 0,
        date_creation INTEGER NOT NULL,
        date_derniere_modif INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE diagnostic_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_profile_id INTEGER NOT NULL,
        dtc_codes_json TEXT NOT NULL,
        urgence_level TEXT NOT NULL,
        resume_global TEXT NOT NULL,
        kilometrage_au_scan INTEGER NOT NULL DEFAULT 0,
        est_effacable INTEGER NOT NULL DEFAULT 1,
        date_creation INTEGER NOT NULL,
        FOREIGN KEY (vehicle_profile_id) REFERENCES vehicle_profiles(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE maintenance_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_profile_id INTEGER NOT NULL,
        type_entretien TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        kilometrage_entretien INTEGER NOT NULL DEFAULT 0,
        cout_euros REAL DEFAULT 0.0,
        nom_garagiste TEXT DEFAULT '',
        facture_photo_path TEXT DEFAULT '',
        date_entretien INTEGER NOT NULL,
        date_creation INTEGER NOT NULL,
        rappel_actif INTEGER DEFAULT 0,
        rappel_kilometrage INTEGER DEFAULT 0,
        rappel_date_ms INTEGER DEFAULT 0,
        FOREIGN KEY (vehicle_profile_id) REFERENCES vehicle_profiles(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_profile_id INTEGER NOT NULL,
        type_document TEXT NOT NULL,
        nom_fichier TEXT NOT NULL,
        chemin_local TEXT NOT NULL,
        type_mime TEXT DEFAULT '',
        date_expiration INTEGER,
        date_ajout INTEGER NOT NULL,
        FOREIGN KEY (vehicle_profile_id) REFERENCES vehicle_profiles(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_profile_id INTEGER NOT NULL,
        dtc_code TEXT NOT NULL,
        urgence_level TEXT NOT NULL,
        message_alerte TEXT NOT NULL,
        est_resolue INTEGER NOT NULL DEFAULT 0,
        est_effacable INTEGER NOT NULL DEFAULT 0,
        date_creation INTEGER NOT NULL,
        date_resolution INTEGER,
        FOREIGN KEY (vehicle_profile_id) REFERENCES vehicle_profiles(id)
      )
    ''');
    await _createVehicleHealthTables(db);
  }

  /// Tables surveillance « santé véhicule » (réf. constructeur, apprentissage, historique alertes).
  Future<void> _createVehicleHealthTables(Database db) async {
    await db.execute('''
      CREATE TABLE vehicle_reference_values (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_profile_id INTEGER NOT NULL UNIQUE,
        fingerprint TEXT NOT NULL,
        json_values TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (vehicle_profile_id) REFERENCES vehicle_profiles(id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_vehicle_ref_fingerprint ON vehicle_reference_values(fingerprint)',
    );
    await db.execute('''
      CREATE TABLE vehicle_learned_values (
        vehicle_profile_id INTEGER PRIMARY KEY,
        learning_started_ms INTEGER NOT NULL,
        last_sample_ms INTEGER,
        learning_completed INTEGER NOT NULL DEFAULT 0,
        aggregates_json TEXT NOT NULL DEFAULT '{}',
        sample_count INTEGER NOT NULL DEFAULT 0,
        last_positive_bilan_ms INTEGER,
        FOREIGN KEY (vehicle_profile_id) REFERENCES vehicle_profiles(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE vehicle_health_alert_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_profile_id INTEGER NOT NULL,
        level INTEGER NOT NULL,
        message TEXT NOT NULL,
        technical_detail TEXT,
        created_ms INTEGER NOT NULL,
        FOREIGN KEY (vehicle_profile_id) REFERENCES vehicle_profiles(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE vehicle_profiles ADD COLUMN numero_vin TEXT DEFAULT \'\'');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE documents ADD COLUMN type_mime TEXT DEFAULT \'\'');
    }
    if (oldVersion < 4) {
      await db.execute(
          'ALTER TABLE vehicle_profiles ADD COLUMN motorisation TEXT NOT NULL DEFAULT \'\'');
    }
    if (oldVersion < 5) {
      await _createVehicleHealthTables(db);
    }
  }

  /// Nombre de lignes dans [vehicle_profiles].
  Future<int> countVehicleProfiles() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as c FROM vehicle_profiles');
    return (result.first['c'] as int?) ?? 0;
  }

  /// Insère un profil. Refus si [countVehicleProfiles] >= 2.
  Future<int> insertVehicleProfile(VehicleProfile profile) async {
    final db = await database;
    final n = await countVehicleProfiles();
    if (n >= 2) {
      throw StateError(
        'Nombre maximum de profils véhicules atteint (2).',
      );
    }
    return db.insert('vehicle_profiles', profile.toMap());
  }

  Future<List<VehicleProfile>> getAllVehicleProfiles() async {
    final db = await database;
    final maps = await db.query('vehicle_profiles', orderBy: 'date_derniere_modif DESC');
    return maps.map(VehicleProfile.fromMap).toList();
  }

  Future<VehicleProfile?> getVehicleProfileById(int id) async {
    final db = await database;
    final maps = await db.query('vehicle_profiles', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return VehicleProfile.fromMap(maps.first);
  }

  Future<bool> hasProfilComplet() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM vehicle_profiles 
      WHERE kilometrage > 0 AND type_boite != '' AND est_profil_complet = 1
    ''');
    return (result.first['count'] as int) > 0;
  }

  Future<int> updateVehicleProfile(VehicleProfile profile) async {
    final db = await database;
    return db.update(
      'vehicle_profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  /// Supprime le profil et les entrées liées (ordre respectant les FK).
  Future<void> deleteVehicleProfile(int id) async {
    final db = await database;
    await db.delete(
      'maintenance_entries',
      where: 'vehicle_profile_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'documents',
      where: 'vehicle_profile_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'diagnostic_entries',
      where: 'vehicle_profile_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'alerts',
      where: 'vehicle_profile_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'vehicle_health_alert_history',
      where: 'vehicle_profile_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'vehicle_learned_values',
      where: 'vehicle_profile_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'vehicle_reference_values',
      where: 'vehicle_profile_id = ?',
      whereArgs: [id],
    );
    await db.delete('vehicle_profiles', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertDiagnosticEntry(DiagnosticEntry entry) async {
    final db = await database;
    return db.insert('diagnostic_entries', entry.toMap());
  }

  Future<List<DiagnosticEntry>> getDiagnosticsByVehicle(int vehicleId) async {
    final db = await database;
    final maps = await db.query(
      'diagnostic_entries',
      where: 'vehicle_profile_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date_creation DESC',
    );
    return maps.map(DiagnosticEntry.fromMap).toList();
  }

  Future<int> insertMaintenanceEntry(MaintenanceEntry entry) async {
    final db = await database;
    return db.insert('maintenance_entries', entry.toMap());
  }

  Future<List<MaintenanceEntry>> getMaintenanceByVehicle(int vehicleId) async {
    final db = await database;
    final maps = await db.query(
      'maintenance_entries',
      where: 'vehicle_profile_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date_entretien DESC',
    );
    return maps.map(MaintenanceEntry.fromMap).toList();
  }

  /// Entrées avec rappel actif : au moins un critère km ou date.
  /// Inclut les rappels uniquement par date (km = 0) grâce à `rappel_date_ms > 0`.
  Future<List<MaintenanceEntry>> getMaintenanceAvecRappel() async {
    final db = await database;
    final maps = await db.query(
      'maintenance_entries',
      where:
          'rappel_actif = 1 AND (rappel_kilometrage > 0 OR rappel_date_ms > 0)',
      orderBy: 'rappel_kilometrage ASC, rappel_date_ms ASC',
    );
    return maps.map(MaintenanceEntry.fromMap).toList();
  }

  Future<MaintenanceEntry?> getMaintenanceEntryById(int id) async {
    final db = await database;
    final maps = await db.query(
      'maintenance_entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MaintenanceEntry.fromMap(maps.first);
  }

  Future<int> updateMaintenanceEntry(MaintenanceEntry entry) async {
    final db = await database;
    if (entry.id == null) {
      return insertMaintenanceEntry(entry);
    }
    return db.update(
      'maintenance_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Supprime une ligne du carnet et le fichier photo de facture local s'il existe.
  Future<int> deleteMaintenanceEntry(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return 0;
    final existing = await getMaintenanceEntryById(intId);
    if (existing == null) return 0;
    final path = existing.facturePhotoPath.trim();
    if (path.isNotEmpty) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {
        // Fichier déjà absent ou non supprimable : on continue la suppression en base.
      }
    }
    final db = await database;
    return db.delete(
      'maintenance_entries',
      where: 'id = ?',
      whereArgs: [intId],
    );
  }

  Future<int> insertDocument(DocumentEntry document) async {
    final db = await database;
    return db.insert('documents', document.toMap());
  }

  Future<List<DocumentEntry>> getDocumentsByVehicle(int vehicleId) async {
    final db = await database;
    final maps = await db.query(
      'documents',
      where: 'vehicle_profile_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date_ajout DESC',
    );
    return maps.map(DocumentEntry.fromMap).toList();
  }

  Future<void> deleteDocument(int id) async {
    final db = await database;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DocumentEntry>> getDocumentsExpires() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.query(
      'documents',
      where: 'date_expiration IS NOT NULL AND date_expiration < ?',
      whereArgs: [now],
    );
    return maps.map(DocumentEntry.fromMap).toList();
  }

  // ─── Santé véhicule (réf. constructeur, apprentissage, alertes) ───

  Future<int> insertVehicleReferenceValue(VehicleReferenceValueEntry e) async {
    final db = await database;
    return db.insert('vehicle_reference_values', e.toMap());
  }

  Future<VehicleReferenceValueEntry?> getVehicleReferenceByVehicleId(
    int vehicleProfileId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'vehicle_reference_values',
      where: 'vehicle_profile_id = ?',
      whereArgs: [vehicleProfileId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return VehicleReferenceValueEntry.fromMap(maps.first);
  }

  /// Première ligne avec ce [fingerprint] (optionnellement autre que [excludeVehicleId]).
  Future<VehicleReferenceValueEntry?> getReferenceByFingerprintForReuse(
    String fingerprint, {
    int? excludeVehicleId,
  }) async {
    final db = await database;
    final maps = excludeVehicleId == null
        ? await db.query(
            'vehicle_reference_values',
            where: 'fingerprint = ?',
            whereArgs: [fingerprint],
            limit: 1,
          )
        : await db.query(
            'vehicle_reference_values',
            where: 'fingerprint = ? AND vehicle_profile_id != ?',
            whereArgs: [fingerprint, excludeVehicleId],
            limit: 1,
          );
    if (maps.isEmpty) return null;
    return VehicleReferenceValueEntry.fromMap(maps.first);
  }

  Future<int> deleteVehicleReferenceByVehicleId(int vehicleProfileId) async {
    final db = await database;
    return db.delete(
      'vehicle_reference_values',
      where: 'vehicle_profile_id = ?',
      whereArgs: [vehicleProfileId],
    );
  }

  Future<void> upsertVehicleLearnedValues(VehicleLearnedValuesEntry e) async {
    final db = await database;
    await db.insert(
      'vehicle_learned_values',
      e.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<VehicleLearnedValuesEntry?> getVehicleLearnedValues(
    int vehicleProfileId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'vehicle_learned_values',
      where: 'vehicle_profile_id = ?',
      whereArgs: [vehicleProfileId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return VehicleLearnedValuesEntry.fromMap(maps.first);
  }

  Future<int> insertVehicleHealthAlert(VehicleHealthAlertHistoryEntry e) async {
    final db = await database;
    return db.insert('vehicle_health_alert_history', e.toMap());
  }

  Future<List<VehicleHealthAlertHistoryEntry>> getVehicleHealthAlerts(
    int vehicleProfileId, {
    int limit = 100,
  }) async {
    final db = await database;
    final maps = await db.query(
      'vehicle_health_alert_history',
      where: 'vehicle_profile_id = ?',
      whereArgs: [vehicleProfileId],
      orderBy: 'created_ms DESC',
      limit: limit,
    );
    return maps.map(VehicleHealthAlertHistoryEntry.fromMap).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Chemins absolus des fichiers utilisateur référencés en base (factures carnet, documents boîte à gants).
  Future<List<String>> getAllReferencedUserFilePaths() async {
    final db = await database;
    final paths = <String>{};
    final maintenanceRows = await db.query(
      'maintenance_entries',
      columns: ['facture_photo_path'],
    );
    for (final row in maintenanceRows) {
      final s = (row['facture_photo_path'] as String?)?.trim() ?? '';
      if (s.isNotEmpty) paths.add(s);
    }
    final docRows = await db.query(
      'documents',
      columns: ['chemin_local'],
    );
    for (final row in docRows) {
      final s = (row['chemin_local'] as String?)?.trim() ?? '';
      if (s.isNotEmpty) paths.add(s);
    }
    return paths.toList();
  }

  /// Ferme la connexion, supprime le fichier SQLite ; la prochaine ouverture recrée une base vide.
  Future<void> closeAndDeleteDatabaseFile() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    final dbPath = await getDatabasesPath();
    final filePath = join(dbPath, _dbName);
    await deleteDatabase(filePath);
  }
}
