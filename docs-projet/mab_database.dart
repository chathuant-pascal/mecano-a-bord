// mab_database.dart
// Mécano à Bord — Version Flutter/Dart (Android + iOS)
//
// Ce fichier gère toute la base de données locale de l'application.
// Technologie : sqflite (SQLite pour Flutter) + flutter_secure_storage (chiffrement clé)
//
// Structure :
//   - VehicleProfile     → profil du véhicule (Boîte à gants)
//   - DiagnosticEntry    → historique des scans OBD
//   - MaintenanceEntry   → carnet d'entretien
//   - Document           → documents stockés (carte grise, etc.)
//   - Alert              → alertes rouges (non effaçables)

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// ─────────────────────────────────────────────
// MODÈLES DE DONNÉES
// ─────────────────────────────────────────────

/// Profil du véhicule (Boîte à gants)
///
/// RÈGLE FONDAMENTALE : sans profil complet (kilométrage + type de boîte),
/// le scan OBD réel ne peut pas démarrer.
class VehicleProfile {
  final int? id;
  final String marque;
  final String modele;
  final int annee;
  final int kilometrage;
  final String typeBoite;       // "MANUELLE" ou "AUTOMATIQUE"
  final String carburant;       // "ESSENCE", "DIESEL", "HYBRIDE", "ELECTRIQUE"
  final String numeroPlaqueImmat;
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
    estProfilComplet: map['est_profil_complet'] == 1,
    dateCreation: map['date_creation'],
    dateDerniereModif: map['date_derniere_modif'],
  );
}

/// Entrée de diagnostic (résultat d'un scan OBD)
///
/// Les entrées de niveau ROUGE ne peuvent pas être effacées.
class DiagnosticEntry {
  final int? id;
  final int vehicleProfileId;
  final String dtcCodesJson;        // Liste des codes DTC (format JSON)
  final String urgenceLevel;        // "VERT", "ORANGE", "ROUGE", "ROUGE_CRITIQUE"
  final String resumeGlobal;
  final int kilometrageAuScan;
  final bool estEffacable;          // false si niveau ROUGE ou ROUGE_CRITIQUE
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

/// Entrée du carnet d'entretien
class MaintenanceEntry {
  final int? id;
  final int vehicleProfileId;
  final String typeEntretien;       // Ex: "Vidange", "Pneus", "Freins"
  final String description;
  final int kilometrageEntretien;
  final double coutEuros;
  final String nomGaragiste;
  final String facturePhotoPath;    // Chemin vers la photo de facture
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

/// Document stocké (carte grise, assurance, contrôle technique...)
class DocumentEntry {
  final int? id;
  final int vehicleProfileId;
  final String typeDocument;        // "CARTE_GRISE", "ASSURANCE", "CT", "AUTRE"
  final String nomFichier;
  final String cheminLocal;
  final int? dateExpiration;        // null si pas de date d'expiration
  final int dateAjout;

  DocumentEntry({
    this.id,
    required this.vehicleProfileId,
    required this.typeDocument,
    required this.nomFichier,
    required this.cheminLocal,
    this.dateExpiration,
    int? dateAjout,
  }) : dateAjout = dateAjout ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'vehicle_profile_id': vehicleProfileId,
    'type_document': typeDocument,
    'nom_fichier': nomFichier,
    'chemin_local': cheminLocal,
    'date_expiration': dateExpiration,
    'date_ajout': dateAjout,
  };

  factory DocumentEntry.fromMap(Map<String, dynamic> map) => DocumentEntry(
    id: map['id'],
    vehicleProfileId: map['vehicle_profile_id'],
    typeDocument: map['type_document'],
    nomFichier: map['nom_fichier'],
    cheminLocal: map['chemin_local'],
    dateExpiration: map['date_expiration'],
    dateAjout: map['date_ajout'],
  );
}

/// Alerte rouge (non effaçable par l'utilisateur)
class AlertEntry {
  final int? id;
  final int vehicleProfileId;
  final String dtcCode;
  final String urgenceLevel;        // "ROUGE" ou "ROUGE_CRITIQUE"
  final String messageAlerte;
  final bool estResolue;            // Peut passer à true UNIQUEMENT via un professionnel
  final bool estEffacable;          // Toujours false pour les alertes rouges
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

// ─────────────────────────────────────────────
// BASE DE DONNÉES PRINCIPALE
// ─────────────────────────────────────────────

class MabDatabase {
  static const String _dbName = 'mab_database.db';
  static const int _dbVersion = 1;

  static MabDatabase? _instance;
  static Database? _database;

  MabDatabase._internal();

  /// Singleton : une seule instance de la base de données dans l'application.
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
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Création des tables à la première ouverture.
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Les migrations seront ajoutées ici lors des prochaines versions
  }

  // ─────────────────────────────────────────────
  // OPÉRATIONS — VehicleProfile
  // ─────────────────────────────────────────────

  Future<int> insertVehicleProfile(VehicleProfile profile) async {
    final db = await database;
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

  /// Vérifie si un profil complet existe (nécessaire avant tout scan OBD réel).
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

  // ─────────────────────────────────────────────
  // OPÉRATIONS — DiagnosticEntry
  // ─────────────────────────────────────────────

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

  /// Suppression protégée : ignore les alertes rouges non effaçables.
  Future<int> deleteDiagnosticIfEffacable(int id) async {
    final db = await database;
    return db.delete(
      'diagnostic_entries',
      where: 'id = ? AND est_effacable = 1',
      whereArgs: [id],
    );
  }

  // ─────────────────────────────────────────────
  // OPÉRATIONS — MaintenanceEntry
  // ─────────────────────────────────────────────

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

  Future<List<MaintenanceEntry>> getMaintenanceAvecRappel() async {
    final db = await database;
    final maps = await db.query(
      'maintenance_entries',
      where: 'rappel_actif = 1 AND rappel_kilometrage > 0',
      orderBy: 'rappel_kilometrage ASC',
    );
    return maps.map(MaintenanceEntry.fromMap).toList();
  }

  Future<int> updateMaintenanceEntry(MaintenanceEntry entry) async {
    final db = await database;
    return db.update(
      'maintenance_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteMaintenanceEntry(int id) async {
    final db = await database;
    return db.delete('maintenance_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────
  // OPÉRATIONS — Documents
  // ─────────────────────────────────────────────

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

  Future<int> deleteDocument(int id) async {
    final db = await database;
    return db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────
  // OPÉRATIONS — Alertes
  // ─────────────────────────────────────────────

  Future<int> insertAlert(AlertEntry alert) async {
    final db = await database;
    return db.insert('alerts', alert.toMap());
  }

  Future<List<AlertEntry>> getAlertsByVehicle(int vehicleId) async {
    final db = await database;
    final maps = await db.query(
      'alerts',
      where: 'vehicle_profile_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date_creation DESC',
    );
    return maps.map(AlertEntry.fromMap).toList();
  }

  Future<List<AlertEntry>> getAlertsActives() async {
    final db = await database;
    final maps = await db.query(
      'alerts',
      where: 'est_resolue = 0',
      orderBy: 'date_creation DESC',
    );
    return maps.map(AlertEntry.fromMap).toList();
  }

  /// Marque une alerte comme résolue.
  /// Ne supprime JAMAIS l'alerte — elle reste dans l'historique.
  Future<int> marquerAlerteResolue(int id) async {
    final db = await database;
    return db.update(
      'alerts',
      {
        'est_resolue': 1,
        'date_resolution': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Fermeture propre de la base de données.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
