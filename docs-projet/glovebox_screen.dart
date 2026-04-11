// glovebox_screen.dart — Mécano à Bord (Flutter iOS + Android)
//
// La Boîte à gants numérique — source de vérité du véhicule.
//
// 4 onglets :
//  1. PROFIL     — Marque, modèle, année, kilométrage, boîte, carburant
//  2. DOCUMENTS  — Carte grise, assurance, contrôle technique
//  3. CARNET     — Historique des entretiens + rappels
//  4. HISTORIQUE — Diagnostics OBD (alertes rouges non effaçables)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'mab_repository.dart';
import 'mab_database.dart';

class GloveboxScreen extends StatefulWidget {
  /// Onglet à ouvrir directement : 'PROFILE', 'MAINTENANCE', null = Profil
  final String? initialTab;
  const GloveboxScreen({super.key, this.initialTab});

  @override
  State<GloveboxScreen> createState() => _GloveboxScreenState();
}

class _GloveboxScreenState extends State<GloveboxScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  late final MabRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = MabRepository(MabDatabase());
    _tabController = TabController(length: 4, vsync: this);
    // Ouvrir le bon onglet si demandé
    final initialIndex = switch (widget.initialTab) {
      'MAINTENANCE' => 2,
      'PROFILE'     => 0,
      _             => 0,
    };
    _tabController.index = initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Boîte à gants',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: const Color(0xFF9E9E9E),
          indicatorColor: const Color(0xFF2196F3),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.directions_car_outlined, size: 20), text: 'Profil'),
            Tab(icon: Icon(Icons.folder_outlined, size: 20),         text: 'Documents'),
            Tab(icon: Icon(Icons.build_outlined, size: 20),          text: 'Carnet'),
            Tab(icon: Icon(Icons.history_rounded, size: 20),         text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProfileTab(repository: _repository),
          _DocumentsTab(repository: _repository),
          _MaintenanceTab(repository: _repository),
          _HistoryTab(repository: _repository),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
// ONGLET 1 — PROFIL VÉHICULE
// ─────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  final MabRepository repository;
  const _ProfileTab({required this.repository});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  VehicleProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await widget.repository.getActiveVehicleProfile();
    if (mounted) setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut du profil
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _profile?.isComplete == true
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _profile?.isComplete == true
                  ? '✅ Profil complet — diagnostic activé'
                  : '⚠️ Profil à compléter pour activer le diagnostic',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _profile?.isComplete == true
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF6D4C00),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_profile != null) ...[
            _ProfileRow('Marque',      _profile!.brand),
            _ProfileRow('Modèle',      _profile!.model),
            _ProfileRow('Année',       '${_profile!.year}'),
            _ProfileRow('Kilométrage', '${_profile!.mileage} km'),
            _ProfileRow('Boîte',       _profile!.gearboxType),
            _ProfileRow('Carburant',   _profile!.fuelType),
            if (_profile!.licensePlate.isNotEmpty)
              _ProfileRow('Immatriculation', _profile!.licensePlate),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 32),
                child: Text(
                  'Aucun véhicule configuré',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: Text(_profile == null
                  ? 'Créer mon profil véhicule'
                  : 'Modifier le profil'),
              onPressed: () async {
                await Navigator.pushNamed(context, '/glovebox-profile');
                _loadProfile();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF9E9E9E), fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ONGLET 2 — DOCUMENTS
// ─────────────────────────────────────────────

class _DocumentsTab extends StatefulWidget {
  final MabRepository repository;
  const _DocumentsTab({required this.repository});

  @override
  State<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<_DocumentsTab> {
  List<GloveboxDocument> _docs = [];
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final docs = await widget.repository.getAllGloveboxDocuments();
    if (mounted) setState(() => _docs = docs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _docs.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _docs.length,
              itemBuilder: (_, i) => _DocumentCard(_docs[i], _dateFormat),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDocumentSheet,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.folder_open_outlined,
            size: 72, color: Color(0xFFBDBDBD)),
        const SizedBox(height: 16),
        const Text('Aucun document ajouté',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Ajoutez votre carte grise, assurance…',
            style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 13)),
      ],
    ),
  );

  void _showAddDocumentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quel document ?',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 16),
            for (final type in [
              ('CARTE_GRISE', 'Carte grise', Icons.credit_card_outlined),
              ('ASSURANCE', 'Assurance', Icons.security_outlined),
              ('CONTROLE_TECHNIQUE', 'Contrôle technique', Icons.check_circle_outline),
              ('AUTRE', 'Autre document', Icons.insert_drive_file_outlined),
            ])
              ListTile(
                leading: Icon(type.$3, color: const Color(0xFF2196F3)),
                title: Text(type.$2),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: ouvrir le sélecteur de fichier
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final GloveboxDocument doc;
  final DateFormat dateFormat;
  const _DocumentCard(this.doc, this.dateFormat);

  @override
  Widget build(BuildContext context) {
    final isExpiringSoon = doc.expiryDate != null &&
        doc.expiryDate! < DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isExpiringSoon
            ? Border.all(color: const Color(0xFFFF9800), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.insert_drive_file_outlined,
                color: Color(0xFF2196F3), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 3),
                Text(doc.documentType.replaceAll('_', ' '),
                    style: const TextStyle(
                        color: Color(0xFF9E9E9E), fontSize: 13)),
                if (doc.expiryDate != null)
                  Text(
                    isExpiringSoon
                        ? '⚠️ Expire le ${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(doc.expiryDate!))}'
                        : 'Expire le ${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(doc.expiryDate!))}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isExpiringSoon
                            ? const Color(0xFFE65100)
                            : const Color(0xFF9E9E9E)),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ONGLET 3 — CARNET D'ENTRETIEN
// ─────────────────────────────────────────────

class _MaintenanceTab extends StatefulWidget {
  final MabRepository repository;
  const _MaintenanceTab({required this.repository});

  @override
  State<_MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<_MaintenanceTab> {
  List<MaintenanceEntry> _entries = [];
  List<MaintenanceEntry> _alerts  = [];
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final profile = await widget.repository.getActiveVehicleProfile();
    final entries = await widget.repository.getAllMaintenanceEntries();
    final alerts  = await widget.repository
        .getUpcomingMaintenanceAlerts(profile?.mileage ?? 0);
    if (mounted) {
      setState(() {
        _entries = entries;
        _alerts  = alerts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          if (_alerts.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined,
                      color: Color(0xFFFF9800)),
                  const SizedBox(width: 10),
                  Text(
                    '${_alerts.length} entretien(s) bientôt prévu(s)',
                    style: const TextStyle(
                        color: Color(0xFF6D4C00),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _entries.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _entries.length,
                    itemBuilder: (_, i) =>
                        _MaintenanceCard(_entries[i], _dateFormat),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add-maintenance');
          _loadEntries();
        },
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.build_outlined, size: 72, color: Color(0xFFBDBDBD)),
        SizedBox(height: 16),
        Text('Carnet vide',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16)),
        SizedBox(height: 8),
        Text('Ajoutez votre première intervention',
            style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 13)),
      ],
    ),
  );
}

class _MaintenanceCard extends StatelessWidget {
  final MaintenanceEntry entry;
  final DateFormat dateFormat;
  const _MaintenanceCard(this.entry, this.dateFormat);

  @override
  Widget build(BuildContext context) {
    final nextInfo = entry.nextServiceMileage != null
        ? 'Prochain : ${entry.nextServiceMileage} km'
        : entry.nextServiceDate != null
            ? 'Prochain : ${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(entry.nextServiceDate!))}'
            : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.build_outlined,
                color: Color(0xFF4CAF50), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.entryType[0].toUpperCase() +
                      entry.entryType.substring(1).toLowerCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 3),
                Text(
                  '${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(entry.date))}  •  ${entry.mileageAtService} km',
                  style: const TextStyle(
                      color: Color(0xFF9E9E9E), fontSize: 13),
                ),
                if (nextInfo.isNotEmpty)
                  Text(nextInfo,
                      style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (entry.receiptPhotoPath != null)
            const Icon(Icons.photo_outlined,
                color: Color(0xFF9E9E9E), size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ONGLET 4 — HISTORIQUE DES DIAGNOSTICS
// ─────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  final MabRepository repository;
  const _HistoryTab({required this.repository});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<DiagnosticSession> _sessions = [];
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final s = await widget.repository.getAllDiagnosticSessions();
    if (mounted) setState(() => _sessions = s);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Note protection alertes rouges
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCE4EC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFFE91E63), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Les alertes rouges sont protégées et ne peuvent pas être supprimées.',
                  style: TextStyle(
                      color: Color(0xFFAD1457),
                      fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _sessions.isEmpty
              ? const Center(
                  child: Text('Aucun diagnostic enregistré',
                      style: TextStyle(
                          color: Color(0xFF9E9E9E), fontSize: 15)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _sessions.length,
                  itemBuilder: (_, i) =>
                      _HistoryCard(_sessions[i], _dateFormat),
                ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final DiagnosticSession session;
  final DateFormat dateFormat;
  const _HistoryCard(this.session, this.dateFormat);

  @override
  Widget build(BuildContext context) {
    final (color, emoji, label) = switch (session.riskLevel) {
      RiskLevel.green  => (const Color(0xFF4CAF50), '✅', 'Tout va bien'),
      RiskLevel.orange => (const Color(0xFFFF9800), '⚠️', 'Point à surveiller'),
      _                => (const Color(0xFFF44336), '🔴', 'Attention requise'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: session.riskLevel == RiskLevel.red
            ? Border.all(color: const Color(0xFFF44336).withOpacity(0.3))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: color)),
                    if (session.riskLevel == RiskLevel.red) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_outline,
                          size: 14, color: Color(0xFFF44336)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(
                      DateTime.fromMillisecondsSinceEpoch(session.timestamp)),
                  style: const TextStyle(
                      color: Color(0xFF9E9E9E), fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(session.humanSummary,
                    style: const TextStyle(
                        color: Color(0xFF5A5A72),
                        fontSize: 13,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
