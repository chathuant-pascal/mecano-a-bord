// maintenance_entry.dart
// Mécano à Bord — Version Flutter/Dart (Android + iOS)
//
// Ce fichier gère tout le carnet d'entretien de l'application.
//
// Fonctionnalités :
//   - Saisie manuelle d'un entretien
//   - Scan de facture (photo → extraction des infos)
//   - Rappels automatiques (par kilométrage OU par date)
//   - Export PDF du dossier de revente
//   - Calcul de l'usure estimée

import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'mab_database.dart';

// ─────────────────────────────────────────────
// TYPES D'ENTRETIEN
// ─────────────────────────────────────────────

/// Les types d'entretien reconnus par l'application.
/// Chaque type a un intervalle recommandé (en km et en mois).
enum TypeEntretien {
  vidange(
    libelle: 'Vidange moteur',
    intervalleKm: 10000,
    intervalleMois: 12,
  ),
  filtres(
    libelle: 'Remplacement des filtres',
    intervalleKm: 15000,
    intervalleMois: 12,
  ),
  pneus(
    libelle: 'Pneus',
    intervalleKm: 40000,
    intervalleMois: 0,
  ),
  freins(
    libelle: 'Freins (plaquettes / disques)',
    intervalleKm: 30000,
    intervalleMois: 0,
  ),
  courroieDistribution(
    libelle: 'Courroie de distribution',
    intervalleKm: 120000,
    intervalleMois: 60,
  ),
  batterie(
    libelle: 'Batterie',
    intervalleKm: 0,
    intervalleMois: 48,
  ),
  climatisation(
    libelle: 'Entretien climatisation',
    intervalleKm: 0,
    intervalleMois: 24,
  ),
  liquideRefroidissement(
    libelle: 'Liquide de refroidissement',
    intervalleKm: 60000,
    intervalleMois: 24,
  ),
  bougies(
    libelle: "Bougies d'allumage",
    intervalleKm: 30000,
    intervalleMois: 0,
  ),
  amortisseurs(
    libelle: 'Amortisseurs',
    intervalleKm: 80000,
    intervalleMois: 0,
  ),
  controleTechnique(
    libelle: 'Contrôle technique',
    intervalleKm: 0,
    intervalleMois: 24,
  ),
  autre(
    libelle: 'Autre entretien',
    intervalleKm: 0,
    intervalleMois: 0,
  );

  final String libelle;
  final int intervalleKm;
  final int intervalleMois;

  const TypeEntretien({
    required this.libelle,
    required this.intervalleKm,
    required this.intervalleMois,
  });
}

// ─────────────────────────────────────────────
// MODÈLES DE DONNÉES
// ─────────────────────────────────────────────

/// Un rappel associé à une entrée d'entretien.
class RappelEntretien {
  final int rappelKilometrage;      // 0 = pas de rappel km
  final DateTime? rappelDate;       // null = pas de rappel date
  final String messagePersonnalise;

  const RappelEntretien({
    this.rappelKilometrage = 0,
    this.rappelDate,
    this.messagePersonnalise = '',
  });
}

/// Une entrée complète du carnet d'entretien.
class MaintenanceEntryModel {
  final int? id;
  final int vehicleProfileId;
  final TypeEntretien typeEntretien;
  final String descriptionLibre;
  final int kilometrageEntretien;
  final double coutEuros;
  final String nomGaragiste;
  final String facturePhotoPath;
  final DateTime dateEntretien;
  final RappelEntretien? rappel;

  const MaintenanceEntryModel({
    this.id,
    required this.vehicleProfileId,
    required this.typeEntretien,
    this.descriptionLibre = '',
    required this.kilometrageEntretien,
    this.coutEuros = 0.0,
    this.nomGaragiste = '',
    this.facturePhotoPath = '',
    required this.dateEntretien,
    this.rappel,
  });

  /// Convertit en entité base de données
  MaintenanceEntry toEntity() {
    return MaintenanceEntry(
      id: id,
      vehicleProfileId: vehicleProfileId,
      typeEntretien: typeEntretien.name,
      description: descriptionLibre,
      kilometrageEntretien: kilometrageEntretien,
      coutEuros: coutEuros,
      nomGaragiste: nomGaragiste,
      facturePhotoPath: facturePhotoPath,
      dateEntretien: dateEntretien.millisecondsSinceEpoch,
      rappelActif: rappel != null,
      rappelKilometrage: rappel?.rappelKilometrage ?? 0,
      rappelDateMs: rappel?.rappelDate?.millisecondsSinceEpoch ?? 0,
    );
  }

  /// Construit depuis une entité base de données
  static MaintenanceEntryModel fromEntity(MaintenanceEntry entity) {
    final rappel = entity.rappelActif
        ? RappelEntretien(
            rappelKilometrage: entity.rappelKilometrage,
            rappelDate: entity.rappelDateMs > 0
                ? DateTime.fromMillisecondsSinceEpoch(entity.rappelDateMs)
                : null,
          )
        : null;

    return MaintenanceEntryModel(
      id: entity.id,
      vehicleProfileId: entity.vehicleProfileId,
      typeEntretien: TypeEntretien.values.byName(entity.typeEntretien),
      descriptionLibre: entity.description,
      kilometrageEntretien: entity.kilometrageEntretien,
      coutEuros: entity.coutEuros,
      nomGaragiste: entity.nomGaragiste,
      facturePhotoPath: entity.facturePhotoPath,
      dateEntretien: DateTime.fromMillisecondsSinceEpoch(entity.dateEntretien),
      rappel: rappel,
    );
  }
}

/// Résultat de la vérification des rappels.
class RappelActif {
  final MaintenanceEntryModel entree;
  final String typeRappel;        // "KILOMETRAGE" ou "DATE"
  final String messageRappel;

  const RappelActif({
    required this.entree,
    required this.typeRappel,
    required this.messageRappel,
  });
}

// ─────────────────────────────────────────────
// GESTIONNAIRE DU CARNET D'ENTRETIEN
// ─────────────────────────────────────────────

class MaintenanceManager {
  final MabDatabase _db;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

  MaintenanceManager({required MabDatabase db}) : _db = db;

  /// Ajoute une entrée saisie manuellement
  Future<int> ajouterEntree(MaintenanceEntryModel entree) async {
    return _db.insertMaintenanceEntry(entree.toEntity());
  }

  /// Met à jour une entrée existante
  Future<int> modifierEntree(MaintenanceEntryModel entree) async {
    return _db.updateMaintenanceEntry(entree.toEntity());
  }

  /// Supprime une entrée
  Future<int> supprimerEntree(int id) async {
    return _db.deleteMaintenanceEntry(id);
  }

  /// Récupère tout le carnet d'entretien d'un véhicule
  Future<List<MaintenanceEntryModel>> getCarnet(int vehicleProfileId) async {
    final entities = await _db.getMaintenanceByVehicle(vehicleProfileId);
    return entities.map(MaintenanceEntryModel.fromEntity).toList();
  }

  /// Vérifie si des rappels sont actifs.
  /// Le rappel km s'active 500 km avant l'échéance.
  /// Le rappel date s'active 30 jours avant l'échéance.
  Future<List<RappelActif>> checkRappels(
    int vehicleProfileId,
    int kilometrageActuel,
  ) async {
    final rappelsActifs = <RappelActif>[];
    final maintenant = DateTime.now();
    final entities = await _db.getMaintenanceAvecRappel();

    for (final entity in entities) {
      if (entity.vehicleProfileId != vehicleProfileId) continue;
      final entree = MaintenanceEntryModel.fromEntity(entity);
      final rappel = entree.rappel;
      if (rappel == null) continue;

      // Vérification rappel kilométrage
      if (rappel.rappelKilometrage > 0) {
        final zoneAvertissement = rappel.rappelKilometrage - 500;
        if (kilometrageActuel >= zoneAvertissement) {
          rappelsActifs.add(RappelActif(
            entree: entree,
            typeRappel: 'KILOMETRAGE',
            messageRappel: _buildMessageRappel(
              entree.typeEntretien,
              'KILOMETRAGE',
              '${rappel.rappelKilometrage} km',
            ),
          ));
        }
      }

      // Vérification rappel date
      if (rappel.rappelDate != null) {
        final seuilAvertissement =
            rappel.rappelDate!.subtract(const Duration(days: 30));
        if (maintenant.isAfter(seuilAvertissement)) {
          rappelsActifs.add(RappelActif(
            entree: entree,
            typeRappel: 'DATE',
            messageRappel: _buildMessageRappel(
              entree.typeEntretien,
              'DATE',
              _dateFormat.format(rappel.rappelDate!),
            ),
          ));
        }
      }
    }

    return rappelsActifs;
  }

  /// Génère un PDF du dossier de revente.
  /// Contient tout l'historique d'entretien du véhicule.
  /// Retourne le chemin du fichier PDF généré.
  Future<String> exporterPdfRevente(int vehicleProfileId) async {
    final profil = await _db.getVehicleProfileById(vehicleProfileId);
    if (profil == null) return '';

    final entrees = await getCarnet(vehicleProfileId);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [

          // ── En-tête ──
          pw.Text(
            'Historique d\'entretien',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${profil.marque} ${profil.modele} (${profil.annee})',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Kilométrage actuel : ${profil.kilometrage} km',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Document généré le ${_dateFormat.format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey600,
            ),
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 12),

          // ── Tableau des entretiens ──
          if (entrees.isEmpty)
            pw.Text(
              'Aucun entretien enregistré.',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                // En-tête du tableau
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  children: [
                    _cellHeader('Entretien'),
                    _cellHeader('Date'),
                    _cellHeader('Kilométrage'),
                    _cellHeader('Coût'),
                  ],
                ),
                // Lignes de données
                ...entrees.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final bg = i.isEven ? PdfColors.grey100 : PdfColors.white;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _cell(e.typeEntretien.libelle),
                      _cell(_dateFormat.format(e.dateEntretien)),
                      _cell('${e.kilometrageEntretien} km'),
                      _cell(e.coutEuros > 0
                          ? '${e.coutEuros.toStringAsFixed(0)} €'
                          : '—'),
                    ],
                  );
                }),
              ],
            ),

          pw.SizedBox(height: 24),

          // ── Pied de page ──
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          pw.Text(
            'Document généré par Mécano à Bord — La Méthode Sans Stress Auto',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey500,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    // Sauvegarde du fichier
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'MAB_Historique_${profil.marque}_${profil.modele}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Analyse une photo de facture.
  /// En V1 : retourne une entrée vide pré-remplie que l'utilisateur complète.
  /// L'extraction automatique complète sera affinée dans les prochaines versions.
  Future<MaintenanceEntryModel?> analyserPhotoFacture(
    String photoPath,
    int vehicleProfileId,
  ) async {
    return MaintenanceEntryModel(
      vehicleProfileId: vehicleProfileId,
      typeEntretien: TypeEntretien.autre,
      facturePhotoPath: photoPath,
      kilometrageEntretien: 0,
      dateEntretien: DateTime.now(),
      descriptionLibre: 'Facture scannée — à compléter',
    );
  }

  // ─────────────────────────────────────────────
  // FONCTIONS INTERNES
  // ─────────────────────────────────────────────

  String _buildMessageRappel(
    TypeEntretien type,
    String typeRappel,
    String valeur,
  ) {
    return switch (typeRappel) {
      'KILOMETRAGE' =>
        'Ton ${type.libelle.toLowerCase()} approche ! '
        'Tu as prévu cet entretien autour de $valeur.',
      'DATE' =>
        'Ton ${type.libelle.toLowerCase()} est prévu '
        'autour du $valeur. Pense à prendre rendez-vous.',
      _ => 'Un entretien approche : ${type.libelle}',
    };
  }

  pw.Widget _cellHeader(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      );

  pw.Widget _cell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
      );
}
