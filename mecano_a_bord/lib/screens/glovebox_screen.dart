import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/widgets/mab_demo_banner.dart';
import 'package:mecano_a_bord/utils/mab_logger.dart';
import 'package:mecano_a_bord/widgets/glovebox_vehicle_health_tab.dart';

/// Boîte à gants — version MAB (thème sombre)
///
/// Onglets Profil, Documents, Carnet, Historique des diagnostics OBD, Santé véhicule.

class GloveboxScreen extends StatefulWidget {
  /// Onglet à ouvrir : 'PROFILE', 'MAINTENANCE', 'HEALTH', 'NEW_PROFILE' (ouvre le formulaire vierge), null = Profil
  final String? initialTab;
  const GloveboxScreen({super.key, this.initialTab});

  @override
  State<GloveboxScreen> createState() => _GloveboxScreenState();
}

class _GloveboxScreenState extends State<GloveboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final MabRepository _repository = MabRepository.instance;
  final GlobalKey<_DiagnosticHistoryTabState> _diagnosticHistoryKey =
      GlobalKey<_DiagnosticHistoryTabState>();
  bool _isDemoMode = false;

  void _onTabChanged() {
    if (!mounted) return;
    if (_tabController.index == 3 && !_tabController.indexIsChanging) {
      _diagnosticHistoryKey.currentState?.refresh();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _repository.isDemoMode().then((v) {
      if (mounted) setState(() => _isDemoMode = v);
    });
    final initialIndex = switch (widget.initialTab) {
      'MAINTENANCE' => 2,
      'HEALTH' => 4,
      'PROFILE' => 0,
      'NEW_PROFILE' => 0,
      _ => 0,
    };
    _tabController.index = initialIndex;
    if (widget.initialTab == 'NEW_PROFILE') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamed(context, '/glovebox-profile',
              arguments: 'NEW_PROFILE');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      appBar: AppBar(
        title: const Text('Boîte à gants'),
        backgroundColor: MabColors.noir,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: MabColors.rouge,
          unselectedLabelColor: MabColors.grisTexte,
          indicatorColor: MabColors.rouge,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.directions_car_outlined,
                  size: MabDimensions.iconeM),
              text: 'Profil',
            ),
            Tab(
              icon: Icon(Icons.folder_outlined, size: MabDimensions.iconeM),
              text: 'Documents',
            ),
            Tab(
              icon: Icon(Icons.build_outlined, size: MabDimensions.iconeM),
              text: 'Carnet',
            ),
            Tab(
              icon: Icon(Icons.history_rounded, size: MabDimensions.iconeM),
              text: 'Historique',
            ),
            Tab(
              icon: Icon(Icons.favorite_outline, size: MabDimensions.iconeM),
              text: 'Santé',
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDemoMode) const MabDemoBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ProfileTab(repository: _repository),
                _DocumentsTab(repository: _repository),
                _MaintenanceTab(repository: _repository),
                _DiagnosticHistoryTab(
                  key: _diagnosticHistoryKey,
                  repository: _repository,
                ),
                GloveboxVehicleHealthTab(repository: _repository),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }
}

/// Onglet 1 — Profil véhicule

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
      padding: MabDimensions.paddingEcran,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: MabDimensions.espacementL),
          if (_profile != null) ...[
            _ProfileRow('Marque', _profile!.brand),
            _ProfileRow('Modèle', _profile!.model),
            _ProfileRow('Année', '${_profile!.year}'),
            _ProfileRow('Kilométrage', '${_profile!.mileage} km'),
            _ProfileRow('Boîte', _profile!.gearboxType),
            _ProfileRow('Carburant', _profile!.fuelType),
            if (_profile!.licensePlate.isNotEmpty)
              _ProfileRow('Immatriculation', _profile!.licensePlate),
          ] else ...[
            const SizedBox(height: MabDimensions.espacementL),
            Center(
              child: Text(
                'Aucun véhicule configuré',
                style: MabTextStyles.corpsSecondaire,
              ),
            ),
          ],
          const SizedBox(height: MabDimensions.espacementL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                _profile == null
                    ? 'Créer mon profil véhicule'
                    : 'Modifier le profil',
              ),
              onPressed: () async {
                await Navigator.pushNamed(context, '/glovebox-profile');
                _loadProfile();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isComplete = _profile?.isComplete == true;
    final bgColor = isComplete
        ? MabColors.diagnosticVertClair.withOpacity(0.15)
        : MabColors.diagnosticOrangeClair.withOpacity(0.15);
    final borderColor =
        isComplete ? MabColors.diagnosticVert : MabColors.diagnosticOrange;
    final textColor =
        isComplete ? MabColors.diagnosticVert : MabColors.diagnosticOrange;
    final text = isComplete
        ? 'Profil complet — diagnostic activé'
        : 'Profil à compléter pour activer le diagnostic';

    return Container(
      width: double.infinity,
      padding: MabDimensions.paddingCard,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: MabTextStyles.corpsMedium.copyWith(color: textColor),
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
      padding:
          const EdgeInsets.symmetric(vertical: MabDimensions.espacementS),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: MabTextStyles.corpsSecondaire,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: MabTextStyles.corpsMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Onglet 2 — Documents (Boîte à gants)

class _DocumentsTab extends StatefulWidget {
  final MabRepository repository;
  const _DocumentsTab({required this.repository});

  @override
  State<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<_DocumentsTab> {
  final ImagePicker _imagePicker = ImagePicker();
  List<GloveboxDocument> _documents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final docs = await widget.repository.getAllGloveboxDocuments();
    if (!mounted) return;
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  Future<void> _onAddPressed() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: MabColors.noirMoyen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MabDimensions.rayonGrand),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: MabDimensions.paddingCard,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ajouter un document',
                  style: MabTextStyles.titreCard,
                ),
                const SizedBox(height: MabDimensions.espacementM),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined,
                      color: MabColors.blanc),
                  title: const Text(
                    'Photographier',
                    style: MabTextStyles.corpsNormal,
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _addFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.file_present_outlined,
                      color: MabColors.blanc),
                  title: const Text(
                    'Importer un fichier',
                    style: MabTextStyles.corpsNormal,
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _addFromFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addFromCamera() async {
    XFile? picked;
    try {
      picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
    } catch (e, st) {
      mabLog('Glovebox: caméra pickImage — $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d\'utiliser l\'appareil photo. Vérifie les autorisations dans les réglages du téléphone.',
            style: MabTextStyles.corpsNormal,
          ),
          backgroundColor: MabColors.diagnosticOrange,
        ),
      );
      return;
    }
    if (picked == null) return;
    try {
      final permanentPath = await widget.repository.copyDocumentToAppStorage(picked.path);
      await _selectTypeAndSave(permanentPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'enregistrer la photo : $e'),
            backgroundColor: MabColors.diagnosticRouge,
          ),
        );
      }
    }
  }

  Future<void> _addFromFile() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
    } catch (e, st) {
      mabLog('Glovebox: FilePicker — $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d\'ouvrir le sélecteur de fichiers. Réessaie ou vérifie les autorisations.',
            style: MabTextStyles.corpsNormal,
          ),
          backgroundColor: MabColors.diagnosticOrange,
        ),
      );
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    try {
      final permanentPath = await widget.repository.copyDocumentToAppStorage(path);
      await _selectTypeAndSave(permanentPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'enregistrer le fichier : $e'),
            backgroundColor: MabColors.diagnosticRouge,
          ),
        );
      }
    }
  }

  Future<void> _selectTypeAndSave(String filePath) async {
    final selected = await showModalBottomSheet<_DocumentTypeChoice>(
      context: context,
      backgroundColor: MabColors.noirMoyen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MabDimensions.rayonGrand),
        ),
      ),
      builder: (context) {
        final choices = [
          const _DocumentTypeChoice(
            code: 'CARTE_GRISE',
            label: 'Carte grise',
          ),
          const _DocumentTypeChoice(
            code: 'ASSURANCE',
            label: 'Assurance',
          ),
          const _DocumentTypeChoice(
            code: 'CONTROLE_TECHNIQUE',
            label: 'Contrôle technique',
          ),
          const _DocumentTypeChoice(
            code: 'AUTRE',
            label: 'Autre document',
          ),
        ];

        return SafeArea(
          child: Padding(
            padding: MabDimensions.paddingCard,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Type de document',
                  style: MabTextStyles.titreCard,
                ),
                const SizedBox(height: MabDimensions.espacementM),
                ...choices.map(
                  (choice) => ListTile(
                    title: Text(
                      choice.label,
                      style: MabTextStyles.corpsNormal,
                    ),
                    onTap: () => Navigator.pop(context, choice),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final mimeType = MabRepository.getMimeTypeFromPath(filePath);
    final doc = GloveboxDocument(
      id: '',
      vehicleProfileId: '',
      documentType: selected.code,
      title: selected.label,
      filePath: filePath,
      mimeType: mimeType,
      expiryDate: null,
      addedAt: now,
    );

    await widget.repository.addGloveboxDocument(doc);
    await _loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPressed,
        backgroundColor: MabColors.rouge,
        child: const Icon(Icons.add, color: MabColors.blanc),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(MabColors.rouge),
              ),
            )
          : _documents.isEmpty
              ? const _DocumentsEmpty()
              : ListView.builder(
                  padding: MabDimensions.paddingEcran,
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    return _DocumentCard(
                      document: doc,
                      onDeleted: _loadDocuments,
                    );
                  },
                ),
    );
  }
}

class _DocumentTypeChoice {
  final String code;
  final String label;
  const _DocumentTypeChoice({required this.code, required this.label});
}

class _DocumentsEmpty extends StatelessWidget {
  const _DocumentsEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.center,
      padding: MabDimensions.paddingEcran,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: MabDimensions.iconeXL,
            color: MabColors.grisTexte,
          ),
          const SizedBox(height: MabDimensions.espacementM),
          Text(
            'Aucun document enregistré',
            textAlign: TextAlign.center,
            style: MabTextStyles.corpsSecondaire,
          ),
          const SizedBox(height: MabDimensions.espacementS),
          Text(
            'Ajoutez vos documents : carte grise, assurance, contrôle technique…',
            textAlign: TextAlign.center,
            style: MabTextStyles.corpsSecondaire,
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final GloveboxDocument document;
  final VoidCallback? onDeleted;

  const _DocumentCard({required this.document, this.onDeleted});

  Future<void> _openDocument(BuildContext context) async {
    final path = document.filePath;
    if (path.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ce document n\'a pas de fichier associé.'),
            backgroundColor: MabColors.diagnosticRouge,
          ),
        );
      }
      return;
    }
    final file = File(path);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fichier introuvable. Il a peut-être été supprimé ou déplacé.'),
            backgroundColor: MabColors.diagnosticRouge,
          ),
        );
      }
      return;
    }
    final type = document.mimeType.isNotEmpty ? document.mimeType : null;
    OpenResult result;
    try {
      result = await OpenFile.open(path, type: type);
    } catch (e, st) {
      mabLog('Glovebox: OpenFile.open — $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Impossible d\'ouvrir le fichier pour le moment.',
              style: MabTextStyles.corpsNormal,
            ),
            backgroundColor: MabColors.diagnosticOrange,
          ),
        );
      }
      return;
    }
    if (context.mounted && result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isNotEmpty
                ? result.message
                : 'Impossible d\'ouvrir le fichier.',
          ),
          backgroundColor: MabColors.diagnosticOrange,
        ),
      );
    }
  }

  Future<void> _onLongPress(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MabColors.noirMoyen,
        title: const Text(
          'Supprimer ce document ?',
          style: MabTextStyles.titreCard,
        ),
        content: const Text(
          'Le document sera supprimé définitivement ainsi que le fichier associé.',
          style: MabTextStyles.corpsSecondaire,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: MabColors.diagnosticRouge,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await MabRepository.instance.deleteGloveboxDocument(document);
    if (context.mounted) {
      onDeleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: MabColors.noirMoyen,
      margin: const EdgeInsets.only(bottom: MabDimensions.espacementM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
        side: const BorderSide(color: MabColors.grisContour),
      ),
      child: ListTile(
        leading: Icon(
          Icons.insert_drive_file_outlined,
          color: MabColors.grisDore,
          size: MabDimensions.iconeM,
        ),
        title: Text(
          document.title,
          style: MabTextStyles.corpsMedium,
        ),
        subtitle: Text(
          document.documentType,
          style: MabTextStyles.corpsSecondaire,
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: MabColors.grisTexte,
        ),
        onTap: () => _openDocument(context),
        onLongPress: () => _onLongPress(context),
      ),
    );
  }
}

/// Onglet 4 — Historique des diagnostics OBD

class _DiagnosticHistoryTab extends StatefulWidget {
  final MabRepository repository;
  const _DiagnosticHistoryTab({super.key, required this.repository});

  @override
  State<_DiagnosticHistoryTab> createState() => _DiagnosticHistoryTabState();
}

class _DiagnosticHistoryTabState extends State<_DiagnosticHistoryTab> {
  bool _loading = true;
  bool _demoMode = false;
  int? _vehicleId;
  List<ObdDiagnosticHistoryEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Recharge la liste (ouverture de l’onglet ou tirer pour actualiser).
  Future<void> refresh() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    final demo = await widget.repository.isDemoMode();
    final profile = await widget.repository.getActiveVehicleProfile();
    final vid = int.tryParse(profile?.id ?? '');
    List<ObdDiagnosticHistoryEntry> list = [];
    if (!demo && vid != null) {
      list = await widget.repository.getObdDiagnosticsForVehicle(vid);
    }
    if (mounted) {
      setState(() {
        _demoMode = demo;
        _vehicleId = vid;
        _entries = list;
        _loading = false;
      });
    }
  }

  String _formatScanDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '· ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: MabColors.rouge,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_demoMode) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: MabDimensions.paddingEcran,
        child: Column(
          children: [
            Icon(Icons.history_rounded,
                size: MabDimensions.iconeXL, color: MabColors.grisTexte),
            const SizedBox(height: MabDimensions.espacementM),
            Text(
              'En mode démo, les lectures OBD ne sont pas enregistrées dans l\'historique.',
              textAlign: TextAlign.center,
              style: MabTextStyles.corpsSecondaire,
            ),
          ],
        ),
      );
    }

    if (_vehicleId == null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: MabDimensions.paddingEcran,
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined,
                size: MabDimensions.iconeXL, color: MabColors.grisTexte),
            const SizedBox(height: MabDimensions.espacementM),
            Text(
              'Crée un profil véhicule pour afficher l\'historique des diagnostics.',
              textAlign: TextAlign.center,
              style: MabTextStyles.corpsSecondaire,
            ),
          ],
        ),
      );
    }

    if (_entries.isEmpty) {
      return RefreshIndicator(
        color: MabColors.rouge,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: MabDimensions.paddingEcran,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded,
                    size: MabDimensions.iconeXL,
                    color: MabColors.grisTexte),
                const SizedBox(height: MabDimensions.espacementM),
                Text(
                  'Aucun diagnostic pour l\'instant. '
                  'Lance ta première lecture OBD depuis l\'accueil !',
                  textAlign: TextAlign.center,
                  style: MabTextStyles.corpsNormal.copyWith(
                    color: MabColors.grisTexte,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: MabColors.rouge,
      onRefresh: _load,
      child: ListView.builder(
        padding: MabDimensions.paddingEcran,
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final e = _entries[index];
          return _ObdHistoryCard(
            entry: e,
            formatScanDate: _formatScanDate,
          );
        },
      ),
    );
  }
}

class _ObdHistoryCard extends StatelessWidget {
  final ObdDiagnosticHistoryEntry entry;
  final String Function(DateTime) formatScanDate;

  const _ObdHistoryCard({
    required this.entry,
    required this.formatScanDate,
  });

  @override
  Widget build(BuildContext context) {
    final n = entry.totalCodeCount;
    final codeLabel = n == 0
        ? 'Aucun code défaut'
        : n == 1
            ? '1 code détecté'
            : '$n codes détectés';
    final milLabel = entry.milOn ? '🔴 Check Engine allumé' : '🟢 Check Engine éteint';

    return Card(
      color: MabColors.noirMoyen,
      margin: const EdgeInsets.only(bottom: MabDimensions.espacementM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
        side: const BorderSide(color: MabColors.grisContour),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: MabDimensions.espacementM,
            vertical: MabDimensions.espacementS,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            MabDimensions.espacementM,
            0,
            MabDimensions.espacementM,
            MabDimensions.espacementM,
          ),
          iconColor: MabColors.grisDore,
          collapsedIconColor: MabColors.grisTexte,
          title: Text(
            formatScanDate(entry.scanDate),
            style: MabTextStyles.titreCard.copyWith(fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: MabDimensions.espacementXS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.kilometrageAuScan} km au moment du scan',
                  style: MabTextStyles.corpsSecondaire,
                ),
                const SizedBox(height: 4),
                Text(milLabel, style: MabTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  codeLabel,
                  style: MabTextStyles.corpsNormal.copyWith(
                    color: MabColors.grisDore,
                  ),
                ),
              ],
            ),
          ),
          children: [
            if (entry.resumeGlobal.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: MabDimensions.espacementS),
                child: Text(
                  entry.resumeGlobal,
                  style: MabTextStyles.corpsNormal.copyWith(height: 1.4),
                ),
              ),
            _codeBlock('Codes mémorisés', entry.storedDtcs),
            _codeBlock('Codes en attente', entry.pendingDtcs),
            _codeBlock('Codes permanents', entry.permanentDtcs),
          ],
        ),
      ),
    );
  }

  Widget _codeBlock(String label, List<String> codes) {
    final text = codes.isEmpty ? '—' : codes.join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: MabDimensions.espacementS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: MabTextStyles.label.copyWith(color: MabColors.grisTexte),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: MabTextStyles.corpsNormal.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Onglet 3 — Carnet d'entretien

class _MaintenanceTab extends StatefulWidget {
  final MabRepository repository;
  const _MaintenanceTab({required this.repository});

  @override
  State<_MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<_MaintenanceTab> {
  List<MaintenanceEntry> _entries = [];
  List<MaintenanceEntry> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final profile = await widget.repository.getActiveVehicleProfile();
    final entries = await widget.repository.getAllMaintenanceEntries();
    final alerts = await widget.repository
        .getUpcomingMaintenanceAlerts(profile?.mileage ?? 0);
    if (mounted) {
      setState(() {
        _entries = entries;
        _alerts = alerts;
      });
    }
  }

  Future<void> _confirmDeleteMaintenance(
    BuildContext context,
    MaintenanceEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MabColors.noirMoyen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MabDimensions.rayonGrand),
        ),
        title: Text(
          'Supprimer l\'intervention',
          style: MabTextStyles.titreCard,
        ),
        content: Text(
          'Cette intervention sera supprimée définitivement.\n'
          'Si tu as joint une facture, elle sera aussi supprimée.\n'
          'Tu confirmes ?',
          style: MabTextStyles.corpsNormal,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              minimumSize: const Size(MabDimensions.zoneTactileMin, MabDimensions.zoneTactileMin),
            ),
            child: Text(
              'Annuler',
              style: MabTextStyles.boutonSecondaire.copyWith(
                color: MabColors.grisTexte,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              minimumSize: const Size(MabDimensions.zoneTactileMin, MabDimensions.zoneTactileMin),
            ),
            child: Text(
              'Oui, supprimer',
              style: MabTextStyles.boutonPrincipal.copyWith(
                color: MabColors.rouge,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await widget.repository.deleteMaintenanceEntry(entry.id);
    if (context.mounted) _loadEntries();
  }

  Future<void> _openEditMaintenance(
    BuildContext context,
    MaintenanceEntry entry,
  ) async {
    final id = int.tryParse(entry.id);
    if (id == null) return;
    await Navigator.pushNamed(
      context,
      '/add-maintenance',
      arguments: <String, dynamic>{'editEntryId': id},
    );
    if (context.mounted) _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          if (_alerts.isNotEmpty)
            Container(
              margin: MabDimensions.paddingEcran,
              padding: MabDimensions.paddingCard,
              decoration: BoxDecoration(
                color: MabColors.diagnosticOrangeClair.withOpacity(0.2),
                borderRadius:
                    BorderRadius.circular(MabDimensions.rayonMoyen),
                border: Border.all(color: MabColors.diagnosticOrange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined,
                      color: MabColors.diagnosticOrange),
                  const SizedBox(width: MabDimensions.espacementS),
                  Expanded(
                    child: Text(
                      '${_alerts.length} entretien(s) bientôt prévu(s)',
                      style: MabTextStyles.corpsMedium.copyWith(
                        color: MabColors.diagnosticOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _entries.isEmpty
                ? const _MaintenanceEmpty()
                : ListView.builder(
                    padding: MabDimensions.paddingEcran,
                    itemCount: _entries.length,
                    itemBuilder: (_, i) => _MaintenanceCard(
                      entry: _entries[i],
                      onTap: () => _openEditMaintenance(context, _entries[i]),
                      onDelete: () => _confirmDeleteMaintenance(context, _entries[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add-maintenance');
          _loadEntries();
        },
        backgroundColor: MabColors.rouge,
        child: const Icon(Icons.add, color: MabColors.blanc),
      ),
    );
  }
}

class _MaintenanceEmpty extends StatelessWidget {
  const _MaintenanceEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.build_outlined,
              size: MabDimensions.iconeXL, color: MabColors.grisTexte),
          const SizedBox(height: MabDimensions.espacementM),
          Text(
            'Carnet vide',
            style: MabTextStyles.corpsSecondaire,
          ),
          const SizedBox(height: MabDimensions.espacementS),
          Text(
            'Ajoutez votre première intervention',
            style: MabTextStyles.corpsSecondaire,
          ),
        ],
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final MaintenanceEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MaintenanceCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nextInfo = entry.nextServiceMileage != null
        ? 'Prochain : ${entry.nextServiceMileage} km'
        : entry.nextServiceDate != null
            ? 'Prochain : ${DateTime.fromMillisecondsSinceEpoch(entry.nextServiceDate!).day.toString().padLeft(2, '0')}/'
                '${DateTime.fromMillisecondsSinceEpoch(entry.nextServiceDate!).month.toString().padLeft(2, '0')}/'
                '${DateTime.fromMillisecondsSinceEpoch(entry.nextServiceDate!).year}'
            : '';

    final date = DateTime.fromMillisecondsSinceEpoch(entry.date);
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: MabDimensions.espacementS),
      decoration: BoxDecoration(
        color: MabColors.noirMoyen,
        borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
        border: Border.all(color: MabColors.grisContour),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
          child: Padding(
            padding: MabDimensions.paddingCard,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MabColors.diagnosticVertClair.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(MabDimensions.rayonPetit),
                  ),
                  child: const Icon(Icons.build_outlined,
                      color: MabColors.diagnosticVert, size: 22),
                ),
                const SizedBox(width: MabDimensions.espacementS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.entryType[0].toUpperCase() +
                            entry.entryType.substring(1).toLowerCase(),
                        style: MabTextStyles.titreCard,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$dateLabel  •  ${entry.mileageAtService} km',
                        style: MabTextStyles.corpsSecondaire,
                      ),
                      if (nextInfo.isNotEmpty)
                        Text(
                          nextInfo,
                          style: MabTextStyles.corpsSecondaire
                              .copyWith(color: MabColors.rougeClair),
                        ),
                    ],
                  ),
                ),
                if (entry.receiptPhotoPath != null)
                  const Icon(Icons.photo_outlined,
                      color: MabColors.grisTexte, size: 18),
                IconButton(
                  tooltip: 'Supprimer l\'intervention',
                  icon: const Icon(Icons.delete_outline,
                      color: MabColors.grisTexte),
                  iconSize: MabDimensions.iconeM,
                  constraints: const BoxConstraints(
                    minWidth: MabDimensions.zoneTactileMin,
                    minHeight: MabDimensions.zoneTactileMin,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


