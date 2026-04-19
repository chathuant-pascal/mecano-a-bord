// home_screen.dart — Mécano à Bord
// Accueil : bandeaux harmonisés (même hauteur / style), ordre défini produit.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/utils/mab_logger.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/services/bluetooth_obd_service.dart';
import 'package:mecano_a_bord/services/update_check_service.dart';
import 'package:mecano_a_bord/widgets/mab_logo.dart';
import 'package:mecano_a_bord/widgets/mab_watermark_background.dart';
import 'package:mecano_a_bord/widgets/mab_demo_banner.dart';
import 'package:mecano_a_bord/widgets/mab_obd_not_responding_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

/// Hauteur unique des bandeaux « menu » accueil (hors carte entretien alerte).
const double _kHomeBandHeight = 80;
const double _kHomeBandLeading = 80;
const double _kVehicleSwitcherBannerMaxHeight = 56;

/// Image « assistant » bandeau Poser une question (48×48 dp, ronde).
const String _kIaMecanoAbordAsset = 'assets/images/iamecanoabord.png';
/// Illustration bandeau « Lancer un diagnostic » (48×48 dp, ronde).
const String _kSuvImagesAsset = 'assets/images/suv_images.png';
/// Illustration bandeau « Mode conduite » (48×48 dp, ronde).
const String _kModeConduiteAsset = 'assets/images/modeconduite.png';
const double _kPoserQuestionAvatarDp = 48;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = MabRepository.instance;
  final BluetoothObdService _obdService = BluetoothObdService();

  VehicleProfile? _vehicleProfile;
  List<MaintenanceEntry> _maintenanceAlerts = [];
  List<GloveboxDocument> _expiringDocs = [];
  ObdConnectionState _obdState = const ObdDisconnected();
  bool _isDemoMode = false;
  List<VehicleProfile> _allVehicleProfiles = [];
  int? _activeVehicleId;

  int _selectedNavIndex = 0;

  StreamSubscription<ObdConnectionState>? _obdConnSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _obdConnSub = _obdService.connectionState.listen((state) {
      if (mounted) setState(() => _obdState = state);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      UpdateCheckService.instance.checkForUpdateAndPromptIfNeeded(context);
    });
  }

  Future<void> _loadData() async {
    final demoMode = await _repository.isDemoMode();
    List<VehicleProfile> allProfiles = [];
    int? activeId;
    if (!demoMode) {
      allProfiles = await _repository.getAllVehicleProfiles();
      activeId = await _repository.getActiveVehicleId();
    }
    final profile = await _repository.getActiveVehicleProfile();
    final alerts = await _repository.getUpcomingMaintenanceAlerts(profile?.mileage ?? 0);
    final expiring = await _repository.getExpiringDocuments();
    if (mounted) {
      setState(() {
        _isDemoMode = demoMode;
        _allVehicleProfiles = allProfiles;
        _activeVehicleId = activeId;
        _vehicleProfile = profile;
        _maintenanceAlerts = alerts;
        _expiringDocs = expiring;
      });
    }
  }

  bool _profileIsActive(VehicleProfile p) {
    final pid = int.tryParse(p.id);
    if (pid == null) return false;
    if (_activeVehicleId != null) return _activeVehicleId == pid;
    return _vehicleProfile?.id == p.id;
  }

  Future<void> _switchToVehicle(int id) async {
    if (_activeVehicleId == id) return;
    final currentPid = int.tryParse(_vehicleProfile?.id ?? '');
    if (currentPid == id) return;
    await _repository.setActiveVehicleId(id);
    if (mounted) await _loadData();
  }

  Widget _buildVehicleSwitcherBanner() {
    if (_isDemoMode || _allVehicleProfiles.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_allVehicleProfiles.length == 1) {
      final p = _allVehicleProfiles.first;
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _kVehicleSwitcherBannerMaxHeight),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: MabColors.noirMoyen,
            borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
            border: Border.all(color: MabColors.rouge),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.directions_car_rounded,
                color: MabColors.grisDore,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${p.brand} ${p.model}',
                  style: MabTextStyles.corpsMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/glovebox',
                    arguments: 'NEW_PROFILE',
                  ),
                  child: const Text(
                    '+ Ajouter un véhicule',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final a = _allVehicleProfiles[0];
    final b = _allVehicleProfiles[1];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: _kVehicleSwitcherBannerMaxHeight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildVehicleSwitcherTile(a)),
          const SizedBox(width: 8),
          Expanded(child: _buildVehicleSwitcherTile(b)),
        ],
      ),
    );
  }

  Widget _buildVehicleSwitcherTile(VehicleProfile p) {
    final pid = int.tryParse(p.id);
    final active = _profileIsActive(p);
    final borderColor =
        active ? MabColors.rouge : MabColors.grisContour;

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: MabColors.noirMoyen,
        borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_car_rounded,
            color: MabColors.grisDore,
            size: 22,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${p.brand} ${p.model}',
              style: MabTextStyles.corpsMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (active || pid == null) {
      return Semantics(
        label: 'Véhicule actif ${p.brand} ${p.model}',
        child: content,
      );
    }

    return Semantics(
      label: 'Basculer vers ${p.brand} ${p.model}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _switchToVehicle(pid),
          borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
          child: content,
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    setState(() => _selectedNavIndex = index);
    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/obd-scan');
        break;
      case 2:
        Navigator.pushNamed(context, '/glovebox');
        break;
      case 3:
        Navigator.pushNamed(context, '/ai-chat');
        break;
      case 4:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  Future<void> _launchDiagnostic() async {
    final complete = await _repository.isVehicleProfileComplete();
    if (!mounted) return;
    if (!complete) {
      _showProfileIncompleteDialog();
      return;
    }
    if (await _repository.isDemoMode()) {
      Navigator.pushNamed(context, '/obd-scan');
      return;
    }
    final status = await Permission.bluetoothConnect.request();
    final ok = status.isGranted || status.isLimited;
    if (!mounted) return;
    if (!ok) {
      await showMabObdNotRespondingDialog(
        context,
        onRelancer: () => _launchDiagnostic(),
        onAnnuler: () {},
      );
      return;
    }
    try {
      final devices = await _obdService.getBondedDevices();
      if (!mounted) return;
      if (devices.isEmpty) {
        await showMabObdNotRespondingDialog(
          context,
          onRelancer: () => _launchDiagnostic(),
          onAnnuler: () {},
        );
        return;
      }
      Navigator.pushNamed(
        context,
        '/obd-scan',
        arguments: {'autoStartDiagnostic': true},
      );
    } on ObdScanException {
      if (!mounted) return;
      await showMabObdNotRespondingDialog(
        context,
        onRelancer: () => _launchDiagnostic(),
        onAnnuler: () {},
      );
    }
  }

  void _launchDrivingModeToSettings() {
    Navigator.pushNamed(context, '/surveillance-only');
  }

  Future<void> _launchDemo() async {
    await _repository.setDemoMode(true);
    if (!mounted) return;
    await _loadData();
  }

  void _launchAi() => Navigator.pushNamed(context, '/ai-chat');

  void _launchSystemeIo() => Navigator.pushNamed(context, '/systeme-io');

  void _showProfileIncompleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MabDimensions.rayonGrand)),
        title: const Text('Profil véhicule incomplet'),
        content: const Text(
          'Pour lancer un diagnostic réel, j\'ai besoin de connaître votre véhicule. '
          'Cela prend moins de 2 minutes dans la Boîte à gants.\n\n'
          'Vous pouvez aussi essayer le Mode démo sans véhicule.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/glovebox', arguments: 'PROFILE');
            },
            child: const Text('Compléter mon profil'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchDemo();
            },
            child: const Text('Mode démo'),
          ),
        ],
      ),
    );
  }

  /// Bandeau harmonisé : fond noir moyen, bordure, image 80×80 à gauche, texte + chevron.
  Widget _buildHomeBand({
    required VoidCallback onTap,
    required String semanticsLabel,
    required Widget leading,
    required Widget centerColumn,
  }) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: _kHomeBandHeight,
          padding: const EdgeInsets.only(
            top: MabDimensions.espacementM,
            bottom: MabDimensions.espacementM,
            right: MabDimensions.espacementM,
          ),
          decoration: BoxDecoration(
            color: MabColors.noirMoyen,
            borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
            border: Border.all(color: MabColors.grisContour),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              SizedBox(
                width: _kHomeBandLeading,
                height: _kHomeBandLeading,
                child: leading,
              ),
              const SizedBox(width: 14),
              Expanded(child: centerColumn),
              const Icon(Icons.chevron_right, color: MabColors.grisTexte),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSubtitleColumn(String title, String? subtitle,
      {TextStyle? subtitleStyle}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: MabTextStyles.titreCard),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: subtitleStyle ?? MabTextStyles.corpsSecondaire,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MabWatermarkBackground(
              watermarkOpacity: 0.15,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isDemoMode) const MabDemoBanner(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadData,
                        color: MabColors.rouge,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: MabDimensions.paddingEcran,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 12),
                              _buildVehicleSwitcherBanner(),
                              const SizedBox(height: 16),
                              // 1. Méthode sans stress auto
                              _buildSystemeIoCard(),
                              const SizedBox(height: 16),
                              // 2. Boîte à gants
                              _buildGloveboxCard(),
                              const SizedBox(height: 16),
                              // 3. OBD
                              _buildObdStatusCard(),
                              if (_maintenanceAlerts.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildMaintenanceCard(),
                              ],
                              const SizedBox(height: 16),
                              // 4. Diagnostic
                              _buildDiagnosticBand(),
                              const SizedBox(height: 16),
                              // 5. Mode conduite → Réglages > Surveillance
                              _buildModeConduiteBand(),
                              const SizedBox(height: 16),
                              // 6. Mode démo (logo MAB à gauche)
                              _buildModeDemoBand(),
                              const SizedBox(height: 16),
                              // 7. Poser une question
                              _buildPoserQuestionBand(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    final vehicleName = _vehicleProfile != null
        ? '${_vehicleProfile!.brand} ${_vehicleProfile!.model}'
        : 'Mon véhicule';
    final mileage = _vehicleProfile != null
        ? '${_vehicleProfile!.mileage} km'
        : 'Profil à compléter';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vehicleName, style: MabTextStyles.titreSection),
              const SizedBox(height: 2),
              Text(mileage, style: MabTextStyles.corpsSecondaire),
            ],
          ),
        ),
        Semantics(
          label: 'Ouvrir les réglages',
          child: SizedBox(
            width: MabDimensions.zoneTactileMin,
            height: MabDimensions.zoneTactileMin,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              style: IconButton.styleFrom(
                minimumSize: const Size(MabDimensions.zoneTactileMin, MabDimensions.zoneTactileMin),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildObdStatusCard() {
    final (label, color, icon) = switch (_obdState) {
      ObdConnected(deviceName: final name) => (
          'Connecté — $name',
          MabColors.diagnosticVert,
          Icons.bluetooth_connected
        ),
      ObdConnecting() => (
          'Connexion en cours…',
          MabColors.diagnosticOrange,
          Icons.bluetooth_searching
        ),
      ObdBluetoothDisabled() => (
          'Bluetooth désactivé',
          MabColors.grisTexte,
          Icons.bluetooth_disabled
        ),
      ObdDeviceNotFound() => (
          'Boîtier introuvable',
          MabColors.diagnosticOrange,
          Icons.bluetooth_searching
        ),
      ObdError(message: _) => (
          'Erreur de connexion',
          MabColors.diagnosticOrange,
          Icons.warning_amber_outlined
        ),
      _ => (
          'Connecte ton OBD',
          MabColors.grisTexte,
          Icons.bluetooth_outlined
        ),
    };

    /// Bandeau OBD par défaut (déconnecté) : même titre que les autres cartes, sans icône Bluetooth étroite.
    final isDefaultObdBand = switch (_obdState) {
      ObdConnected() => false,
      ObdConnecting() => false,
      ObdBluetoothDisabled() => false,
      ObdDeviceNotFound() => false,
      ObdError() => false,
      _ => true,
    };

    return Semantics(
      label: '$label. Ouvrir le diagnostic.',
      button: true,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/obd-scan'),
        child: Container(
          height: _kHomeBandHeight,
          padding: const EdgeInsets.only(
            top: MabDimensions.espacementM,
            bottom: MabDimensions.espacementM,
            right: MabDimensions.espacementM,
          ),
          decoration: BoxDecoration(
            color: MabColors.noirMoyen,
            borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
            border: Border.all(color: MabColors.grisContour),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              SizedBox(
                width: _kHomeBandLeading,
                height: _kHomeBandLeading,
                child: Image.asset(
                  'assets/images/obd.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    mabLog('Image non chargée: obd.png — $error');
                    return Container(
                      color: MabColors.noirClair,
                      child: Icon(
                        Icons.bluetooth_rounded,
                        size: MabDimensions.iconeXL,
                        color: MabColors.grisDore,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              // Pastille de statut : masquée quand « OBD non connecté » pour gagner de la place au texte.
              if (!isDefaultObdBand) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: isDefaultObdBand
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          style: MabTextStyles.titreCard,
                          maxLines: 1,
                        ),
                      )
                    : Text(
                        label,
                        style: MabTextStyles.titreCard.copyWith(color: color),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const Icon(Icons.chevron_right, color: MabColors.grisTexte),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceCard() {
    final count = _maintenanceAlerts.length;
    final label = count == 1
        ? '1 entretien bientôt prévu : ${_maintenanceAlerts.first.entryType.toLowerCase()}'
        : '$count entretiens bientôt prévus';

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/glovebox', arguments: 'MAINTENANCE'),
      child: Container(
        padding: MabDimensions.paddingCard,
        decoration: BoxDecoration(
          color: MabColors.diagnosticOrangeClair.withOpacity(0.3),
          borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
          border: Border.all(color: MabColors.diagnosticOrange),
        ),
        child: Row(
          children: [
            const Icon(Icons.build_outlined,
                color: MabColors.diagnosticOrange, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: MabTextStyles.corpsMedium
                    .copyWith(color: MabColors.diagnosticOrange),
              ),
            ),
            const Icon(Icons.chevron_right, color: MabColors.diagnosticOrange),
          ],
        ),
      ),
    );
  }

  Widget _buildGloveboxCard() {
    final summary = _expiringDocs.isNotEmpty
        ? '${_expiringDocs.length} document(s) expire(nt) bientôt'
        : 'Tous vos documents sont à jour ✓';

    return _buildHomeBand(
      onTap: () => Navigator.pushNamed(context, '/glovebox'),
      semanticsLabel: 'Boîte à Gants. $summary',
      leading: Image.asset(
        'assets/images/boite_a_gant.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          mabLog('Image non chargée: boite_a_gant.png — $error');
          return Container(
            color: MabColors.rouge.withOpacity(0.2),
            child: const Icon(
              Icons.folder_outlined,
              color: MabColors.rouge,
              size: MabDimensions.iconeXL,
            ),
          );
        },
      ),
      centerColumn: _buildTitleSubtitleColumn(
        'Boîte à Gants',
        null,
      ),
    );
  }

  Widget _buildSystemeIoCard() {
    return _buildHomeBand(
      onTap: _launchSystemeIo,
      semanticsLabel: 'Accéder à la méthode sans stress auto',
      leading: Image.asset(
        'assets/images/systeme_io.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          mabLog('Image non chargée: systeme_io.png — $error');
          return Container(
            color: MabColors.noirClair,
            child: Icon(
              Icons.settings_input_antenna_rounded,
              size: MabDimensions.iconeXL,
              color: MabColors.grisDore,
            ),
          );
        },
      ),
      centerColumn: _buildTitleSubtitleColumn(
        'La méthode sans stress auto',
        null,
      ),
    );
  }

  Widget _buildDiagnosticBand() {
    return _buildHomeBand(
      onTap: _launchDiagnostic,
      semanticsLabel: 'Lancer un diagnostic. Scan de votre moteur.',
      leading: Center(
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(_kPoserQuestionAvatarDp / 2),
          child: SizedBox(
            width: _kPoserQuestionAvatarDp,
            height: _kPoserQuestionAvatarDp,
            child: Image.asset(
              _kSuvImagesAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                mabLog('Image non chargée: suv_images.png — $error');
                return Container(
                  color: MabColors.noirClair,
                  child: const Icon(
                    Icons.directions_car_outlined,
                    size: 28,
                    color: MabColors.grisDore,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      centerColumn: _buildTitleSubtitleColumn(
        'Lancer un diagnostic',
        'Scan de votre moteur',
      ),
    );
  }

  Widget _buildModeConduiteBand() {
    return _buildHomeBand(
      onTap: _launchDrivingModeToSettings,
      semanticsLabel: 'Mode conduite. Surveillance en arrière-plan. Ouvrir les réglages.',
      leading: Center(
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(_kPoserQuestionAvatarDp / 2),
          child: SizedBox(
            width: _kPoserQuestionAvatarDp,
            height: _kPoserQuestionAvatarDp,
            child: Image.asset(
              _kModeConduiteAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                mabLog('Image non chargée: modeconduite.png — $error');
                return Container(
                  color: MabColors.noirClair,
                  child: const Icon(
                    Icons.directions_car_outlined,
                    size: 28,
                    color: MabColors.grisDore,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      centerColumn: _buildTitleSubtitleColumn(
        'Mode Conduite',
        null,
      ),
    );
  }

  Widget _buildModeDemoBand() {
    return _buildHomeBand(
      onTap: _launchDemo,
      semanticsLabel: 'Activer le mode démo',
      leading: const Center(
        child: MabLogo(
          size: 56,
          withText: false,
        ),
      ),
      centerColumn: _buildTitleSubtitleColumn(
        'Mode Démo',
        null,
      ),
    );
  }

  Widget _buildPoserQuestionBand() {
    return _buildHomeBand(
      onTap: _launchAi,
      semanticsLabel: 'Poser une question à l\'assistant',
      leading: Center(
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(_kPoserQuestionAvatarDp / 2),
          child: SizedBox(
            width: _kPoserQuestionAvatarDp,
            height: _kPoserQuestionAvatarDp,
            child: Image.asset(
              _kIaMecanoAbordAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                mabLog('Image non chargée: iamecanoabord.png — $error');
                return Container(
                  color: MabColors.noirClair,
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 28,
                    color: MabColors.grisDore,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      centerColumn: _buildTitleSubtitleColumn(
        'Poser une question',
        'Assistant Mécano à Bord',
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: _onNavTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: MabColors.noirMoyen,
      selectedItemColor: MabColors.rouge,
      unselectedItemColor: MabColors.grisTexte,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search_rounded),
          label: 'OBD',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_outlined),
          activeIcon: Icon(Icons.folder_rounded),
          label: 'Boîte à gants',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble_rounded),
          label: 'IA',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings_rounded),
          label: 'Réglages',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _obdConnSub?.cancel();
    _obdService.dispose();
    super.dispose();
  }
}
