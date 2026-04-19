// obd_scan_screen.dart — Mécano à Bord
// Écran OBD : appareils appairés (Bluetooth classique), connexion SPP pour iCar Pro Vgate (PIN dans réglages).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/data/demo_data.dart';
import 'package:mecano_a_bord/services/bluetooth_obd_service.dart';
import 'package:mecano_a_bord/services/live_monitoring_service.dart';
import 'package:mecano_a_bord/widgets/mab_obd_session_dialogs.dart';
import 'package:mecano_a_bord/widgets/mab_demo_banner.dart';
import 'package:mecano_a_bord/services/tts_service.dart';
import 'package:mecano_a_bord/widgets/mab_obd_not_responding_dialog.dart';

class ObdScanScreen extends StatefulWidget {
  const ObdScanScreen({super.key, this.autoStartDiagnostic = false});

  /// Si true (hors mode démo), connexion + scan sans afficher la liste des appareils.
  final bool autoStartDiagnostic;

  @override
  State<ObdScanScreen> createState() => _ObdScanScreenState();
}

/// Ombres portées pour texte lisible sur filigrane (sans cadre).
final List<Shadow> _kObdFloatingTextShadows = [
  Shadow(
    color: Colors.black.withValues(alpha: 0.75),
    blurRadius: 8,
    offset: const Offset(0, 1),
  ),
  Shadow(
    color: Colors.black.withValues(alpha: 0.45),
    blurRadius: 16,
    offset: Offset.zero,
  ),
];

class _ObdScanScreenState extends State<ObdScanScreen>
    with SingleTickerProviderStateMixin {
  final MabRepository _repository = MabRepository.instance;
  final BluetoothObdService _obdService = BluetoothObdService();
  List<Map<String, String>> _devices = [];
  bool _loading = true;
  ObdConnectionState _state = const ObdDisconnected();
  String? _scanErrorMessage;
  late AnimationController _pulseController;
  int _connectingSecondsRemaining = 0;
  Timer? _connectingTimer;
  bool _vehicleReading = false;
  ObdVehicleResult? _vehicleResult;
  String? _vehicleError;
  double _vehicleReadProgress = 0.0;
  String _vehicleReadPhase = 'Interrogation du moteur...';
  bool _protocolDetectionInProgress = false;
  String _protocolDetectionMessage = '';
  int _protocolDetectionCurrent = 0;
  String? _protocolDetectionDeviceName;
  bool _isDemoMode = false;
  String? _lastConnectDeviceId;
  bool _autoConnectFromLoadStarted = false;
  bool _isShowingObdFailureDialog = false;
  bool _clearingDtc = false;
  /// Évite de répéter l’annonce de connexion tant que la session est ouverte.
  bool _obdReadyAnnounced = false;

  /// Diagnostic lancé depuis l’accueil ([autoStartDiagnostic]) : une seule lecture auto, sans bouton sur cet écran.
  bool _autoDiagnosticLaunched = false;

  StreamSubscription<ObdConnectionState>? _obdConnSub;

  bool get _hideBondedDeviceList =>
      widget.autoStartDiagnostic && !_isDemoMode;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _obdConnSub = _obdService.connectionState.listen((state) {
      if (!mounted) return;

      if ((state is ObdConnected ||
              state is ObdConnectedNeedsProtocolDetection) &&
          _lastConnectDeviceId != null &&
          _lastConnectDeviceId!.isNotEmpty) {
        unawaited(
          _repository.setLastObdDeviceAddress(_lastConnectDeviceId!),
        );
      }

      setState(() {
        _state = state;
        if (state is ObdDisconnected ||
            state is ObdError ||
            state is ObdConnecting) {
          _obdReadyAnnounced = false;
          _autoDiagnosticLaunched = false;
        }
        if (state is! ObdConnected) {
          _vehicleResult = null;
          _vehicleError = null;
        }
      });

      if (widget.autoStartDiagnostic && !_isDemoMode && state is ObdError) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _showObdNotRespondingDialogForAuto());
      }
      if (state is ObdConnecting) {
        _connectingTimer?.cancel();
        _connectingSecondsRemaining = 15;
        _connectingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }
          setState(() {
            if (_connectingSecondsRemaining > 0) _connectingSecondsRemaining--;
          });
          if (_connectingSecondsRemaining <= 0) t.cancel();
        });
      } else {
        _connectingTimer?.cancel();
        _connectingSecondsRemaining = 0;
      }
      if (state is ObdConnected) {
        unawaited(_announceObdReady());
        _maybeAutoStartDiagnosticFromHome();
      }
      if (state is ObdConnectedNeedsProtocolDetection && !_protocolDetectionInProgress) {
        _startProtocolDetection(state.deviceName);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final demo = await _repository.isDemoMode();
      if (!mounted) return;
      setState(() => _isDemoMode = demo);
      await _loadDevices();
    });
  }

  void _showObdNotRespondingDialogForAuto() {
    if (!mounted || _isShowingObdFailureDialog) return;
    _isShowingObdFailureDialog = true;
    showMabObdNotRespondingDialog(
      context,
      onRelancer: () {
        _isShowingObdFailureDialog = false;
        _vehicleError = null;
        _vehicleResult = null;
        unawaited(_retryAutoDiagnostic());
      },
      onAnnuler: () {
        _isShowingObdFailureDialog = false;
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  Future<void> _retryAutoDiagnostic() async {
    await _obdService.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await _runAutoConnectSequence();
  }

  Future<void> _runAutoConnectSequence() async {
    if (!mounted || _isDemoMode) return;
    if (_devices.isEmpty) {
      await _loadDevices();
    }
    if (!mounted || _devices.isEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showObdNotRespondingDialogForAuto());
      return;
    }
    final last = await _repository.getLastObdDeviceAddress();
    Map<String, String>? chosen;
    if (last != null && last.isNotEmpty) {
      for (final d in _devices) {
        if (d['id'] == last) {
          chosen = d;
          break;
        }
      }
    }
    chosen ??= _devices.first;
    final deviceId = chosen['id'] ?? '';
    final name = chosen['name'] ?? deviceId;
    if (deviceId.isEmpty) return;
    _lastConnectDeviceId = deviceId;
    final profile = await _repository.getVehicleProfile();
    await _obdService.connect(deviceId, deviceName: name, vin: profile?.vin);
  }

  /// Simulation de la lecture OBD en mode démo (délais visuels réels).
  Future<void> _runDemoReading(String scenario) async {
    setState(() {
      _vehicleReading = true;
      _vehicleError = null;
      _vehicleResult = null;
      _vehicleReadProgress = 0.0;
      _vehicleReadPhase = BluetoothObdService.vehicleReadPhaseLabels.first;
    });
    const stepDuration = Duration(seconds: 2);
    const labels = BluetoothObdService.vehicleReadPhaseLabels;
    for (var i = 0; i < 4; i++) {
      if (!mounted) return;
      setState(() {
        _vehicleReadPhase = labels[i.clamp(0, labels.length - 1)];
        _vehicleReadProgress = (i + 1) / 4;
      });
      await Future<void>.delayed(stepDuration);
    }
    if (!mounted) return;
    await _repository.setDemoObdScenario(scenario);
    final result = getDemoObdResult(scenario);
    setState(() {
      _vehicleReading = false;
      _vehicleResult = result;
      _vehicleReadProgress = 1.0;
    });
    if (result.level == 'orange' || result.level == 'red') {
      TtsService.instance.speakAlertForLevel(result.level);
    }
  }

  static const String _firstConnectionMessage =
      'Premier branchement détecté — l\'application s\'adapte à votre véhicule, '
      'cela peut prendre 5 à 10 minutes. C\'est normal et ne se fait qu\'une seule fois.';

  Future<void> _startProtocolDetection(String deviceName) async {
    if (!_isDemoMode && LiveMonitoringService.instance.isMonitoringActive) {
      if (mounted) {
        await showMabDiagnosticBlockedBySurveillanceDialog(
          context,
          onGoToModeConduite: () {
            Navigator.of(context).pushNamed('/surveillance-only');
          },
        );
      }
      return;
    }
    final profile = await _repository.getVehicleProfile();
    final vin = profile?.vin ?? '';
    if (vin.isEmpty || !mounted) return;
    setState(() {
      _protocolDetectionInProgress = true;
      _protocolDetectionCurrent = 0;
      _protocolDetectionMessage = 'Test du protocole 1/${BluetoothObdService.protocolCount} en cours...';
      _protocolDetectionDeviceName = deviceName;
    });
    var found = false;
    try {
      found = await _obdService.runProtocolDetection(
        vin: vin,
        onProgress: (current, total, message) {
          if (!mounted) return;
          setState(() {
            _protocolDetectionMessage = message;
            _protocolDetectionCurrent = current;
          });
        },
      );
    } on ObdScanException catch (e) {
      if (!mounted) return;
      if (e.message == kObdSurveillanceBlockedCode) {
        await showMabDiagnosticBlockedBySurveillanceDialog(
          context,
          onGoToModeConduite: () {
            Navigator.of(context).pushNamed('/surveillance-only');
          },
        );
      }
      setState(() {
        _protocolDetectionInProgress = false;
        _protocolDetectionDeviceName = null;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _protocolDetectionInProgress = false;
      _protocolDetectionDeviceName = null;
      _state = ObdConnected(deviceName);
    });
    if (found) {
      unawaited(_announceObdReady());
      _maybeAutoStartDiagnosticFromHome();
    } else {
      setState(() => _vehicleError = 'Aucun protocole OBD trouvé pour ce véhicule. Vérifiez le branchement et le contact.');
    }
  }

  Future<void> _announceObdReady() async {
    if (!mounted || _isDemoMode) return;
    if (_obdReadyAnnounced) return;
    _obdReadyAnnounced = true;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OBD connecté.'),
      ),
    );
    await TtsService.instance.speakLiveMonitoringAlert(
      'OBD connecté.',
    );
  }

  /// Uniquement lorsque l’accueil a ouvert cet écran avec [autoStartDiagnostic] : lance le diagnostic sans bouton ici.
  void _maybeAutoStartDiagnosticFromHome() {
    if (!widget.autoStartDiagnostic || _isDemoMode || _autoDiagnosticLaunched) {
      return;
    }
    if (_state is! ObdConnected) return;
    if (_protocolDetectionInProgress || _vehicleReading) return;
    _autoDiagnosticLaunched = true;
    unawaited(_readVehicleData());
  }

  Future<void> _readVehicleData() async {
    if (!mounted || _state is! ObdConnected) return;
    if (!_isDemoMode && LiveMonitoringService.instance.isMonitoringActive) {
      if (mounted) {
        await showMabDiagnosticBlockedBySurveillanceDialog(
          context,
          onGoToModeConduite: () {
            Navigator.of(context).pushNamed('/surveillance-only');
          },
        );
      }
      return;
    }
    setState(() {
      _vehicleReading = true;
      _vehicleError = null;
      _vehicleResult = null;
      _vehicleReadProgress = 0.0;
      _vehicleReadPhase = BluetoothObdService.vehicleReadPhaseLabels.first;
    });
    try {
      final result = await _obdService.getVehicleData((step, phaseLabel, progress) {
        if (!mounted) return;
        setState(() {
          _vehicleReadPhase = phaseLabel;
          _vehicleReadProgress = progress;
        });
      });
      if (!mounted) return;
      setState(() {
        _vehicleReading = false;
        _vehicleResult = result;
        _vehicleError = null;
        _vehicleReadProgress = 1.0;
      });
      final profile = await _repository.getVehicleProfile();
      final kmAtScan = profile?.mileage ?? 0;
      final scanAt = DateTime.now();
      await _repository.saveLastObdDiagnostic(
        scanAt,
        milOn: result.milOn,
        storedDtcs: result.storedDtcs,
        pendingDtcs: result.pendingDtcs,
        permanentDtcs: result.permanentDtcs,
        kmAtScan: kmAtScan,
      );
      await _repository.appendObdDiagnosticHistory(
        scanDate: scanAt,
        kmAtScan: kmAtScan,
        milOn: result.milOn,
        storedDtcs: result.storedDtcs,
        pendingDtcs: result.pendingDtcs,
        permanentDtcs: result.permanentDtcs,
        urgenceLevel: result.level,
        resumeGlobal: result.message,
      );
      if (result.level == 'orange' || result.level == 'red') {
        TtsService.instance.speakAlertForLevel(result.level);
      }
    } on ObdScanException catch (e) {
      if (!mounted) return;
      if (e.message == kObdSurveillanceBlockedCode) {
        await showMabDiagnosticBlockedBySurveillanceDialog(
          context,
          onGoToModeConduite: () {
            Navigator.of(context).pushNamed('/surveillance-only');
          },
        );
        setState(() {
          _vehicleReading = false;
          _vehicleError = null;
          _vehicleResult = null;
        });
        return;
      }
      setState(() {
        _vehicleReading = false;
        _vehicleError = e.message;
        _vehicleResult = null;
      });
      if (widget.autoStartDiagnostic && !_isDemoMode) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _showObdNotRespondingDialogForAuto());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _vehicleReading = false;
        _vehicleError = e.toString();
        _vehicleResult = null;
      });
      if (widget.autoStartDiagnostic && !_isDemoMode) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _showObdNotRespondingDialogForAuto());
      }
    }
  }

  /// Demande la permission Bluetooth (connexion / liste des appairés).
  Future<bool> _requestBluetoothPermission() async {
    final statusConnect = await Permission.bluetoothConnect.request();
    return statusConnect.isGranted || statusConnect.isLimited;
  }

  Future<void> _loadDevices() async {
    setState(() {
      _loading = true;
      _scanErrorMessage = null;
    });

    final hasPermission = await _requestBluetoothPermission();
    if (!mounted) return;
    if (!hasPermission) {
      setState(() {
        _loading = false;
        _scanErrorMessage =
            'Autorisation Bluetooth requise pour voir les appareils appairés. '
            'Activez-la dans Réglages → Applications → Mécano à Bord → Autorisations.';
      });
      if (widget.autoStartDiagnostic && !_isDemoMode) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _showObdNotRespondingDialogForAuto());
      }
      return;
    }

    try {
      final list = await _obdService.getBondedDevices();
      if (mounted) {
        setState(() {
          _devices = list;
          _loading = false;
          _scanErrorMessage = null;
        });
      }
      if (mounted &&
          widget.autoStartDiagnostic &&
          !_isDemoMode &&
          !_autoConnectFromLoadStarted) {
        _autoConnectFromLoadStarted = true;
        if (_devices.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => _showObdNotRespondingDialogForAuto());
        } else {
          await _runAutoConnectSequence();
        }
      }
    } on ObdScanException catch (e) {
      if (mounted) {
        setState(() {
          _devices = [];
          _loading = false;
          _scanErrorMessage = e.message;
        });
        if (widget.autoStartDiagnostic && !_isDemoMode) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showObdNotRespondingDialogForAuto());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _devices = [];
          _loading = false;
          _scanErrorMessage = e.toString();
        });
        if (widget.autoStartDiagnostic && !_isDemoMode) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showObdNotRespondingDialogForAuto());
        }
      }
    }
  }

  /// Ouvre l’assistant IA avec une question sur l’emplacement de la prise OBD (véhicule actif ou question générique).
  Future<void> _openObdPortLocationInAi() async {
    final profile = await _repository.getVehicleProfile();
    final String question;
    if (profile != null &&
        profile.brand.trim().isNotEmpty &&
        profile.model.trim().isNotEmpty &&
        profile.year > 0) {
      question =
          'Où se trouve la prise OBD sur ma ${profile.brand} ${profile.model} ${profile.year} ? '
          'Indique-moi l\'emplacement précis sous le tableau de bord.';
    } else {
      question =
          'Où se trouve généralement la prise OBD dans une voiture ? '
          'Indique-moi où chercher sous le tableau de bord.';
    }
    if (!mounted) return;
    await Navigator.pushNamed(
      context,
      '/ai-chat',
      arguments: <String, String>{'initialQuestion': question},
    );
  }

  @override
  void dispose() {
    _connectingTimer?.cancel();
    _obdConnSub?.cancel();
    _pulseController.dispose();
    _obdService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      appBar: AppBar(
        title: const Text('Connecte ton OBD'),
        backgroundColor: MabColors.noir,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : () => _loadDevices(),
            tooltip: 'Rafraîchir la liste des appareils appairés',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDemoMode) const MabDemoBanner(),
          Expanded(
            child: Stack(
                children: [
                  Padding(
                    padding: MabDimensions.paddingEcran,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isDemoMode) ...[
                          _buildDemoScenarioSection(),
                        ] else ...[
                  _buildStateCard(),
              if (!_hideBondedDeviceList) ...[
              const SizedBox(height: MabDimensions.espacementL),
              Text(
                'Appareils appairés (iCar Pro Vgate, Bluetooth classique)',
                style: MabTextStyles.titreCard,
              ),
              const SizedBox(height: MabDimensions.espacementS),
              ],
              if (_state is ObdConnected || _state is ObdConnectedNeedsProtocolDetection) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: MabDimensions.espacementM),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _obdService.disconnect();
                    },
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Déconnecter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MabColors.rouge,
                      side: const BorderSide(color: MabColors.rouge),
                    ),
                  ),
                ),
                if (_protocolDetectionInProgress)
                  Padding(
                    padding: const EdgeInsets.only(bottom: MabDimensions.espacementM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _firstConnectionMessage,
                          style: MabTextStyles.corpsNormal.copyWith(
                            color: MabColors.blanc,
                            shadows: _kObdFloatingTextShadows,
                          ),
                        ),
                        const SizedBox(height: MabDimensions.espacementM),
                        Text(
                          _protocolDetectionMessage,
                          style: MabTextStyles.corpsMedium.copyWith(
                            color: MabColors.grisDore,
                            shadows: _kObdFloatingTextShadows,
                          ),
                        ),
                        const SizedBox(height: MabDimensions.espacementS),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(MabDimensions.rayonPetit),
                          child: LinearProgressIndicator(
                            value: _protocolDetectionCurrent /
                                BluetoothObdService.protocolCount,
                            minHeight: 8,
                            backgroundColor: MabColors.noirClair,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                MabColors.rouge),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_vehicleReading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: MabDimensions.espacementM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _vehicleReadPhase,
                          style: MabTextStyles.corpsMedium.copyWith(
                            color: MabColors.blanc,
                            shadows: _kObdFloatingTextShadows,
                          ),
                        ),
                        const SizedBox(height: MabDimensions.espacementS),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(MabDimensions.rayonPetit),
                          child: LinearProgressIndicator(
                            value: _vehicleReadProgress,
                            minHeight: 8,
                            backgroundColor: MabColors.noirClair,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                MabColors.rouge),
                          ),
                        ),
                        const SizedBox(height: MabDimensions.espacementXS),
                        Text(
                          'Lecture complète sous 30 s à 3 min',
                          style: MabTextStyles.label.copyWith(
                            color: MabColors.grisTexte,
                            shadows: _kObdFloatingTextShadows,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_vehicleResult != null)
                  _buildVehicleResultColumn(_vehicleResult!)
                else if (_vehicleError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: MabDimensions.espacementM),
                    child: Text(
                      _vehicleError!,
                      style: MabTextStyles.corpsSecondaire.copyWith(
                        color: MabColors.diagnosticRouge,
                        shadows: _kObdFloatingTextShadows,
                      ),
                    ),
                  )
                else if (_state is ObdConnected)
                  _buildLancerDiagnosticButton(),
              ],
              if (_hideBondedDeviceList)
                Expanded(
                  child: _loading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(MabColors.rouge),
                                ),
                              ),
                              const SizedBox(height: MabDimensions.espacementM),
                              Text(
                                'Connexion au boîtier…',
                                style: MabTextStyles.corpsSecondaire,
                              ),
                            ],
                          ),
                        )
                      : (_vehicleReading ||
                              _protocolDetectionInProgress ||
                              _vehicleResult != null ||
                              _vehicleError != null)
                          ? const SizedBox.shrink()
                          : Center(
                              child: Padding(
                                padding: MabDimensions.paddingEcran,
                                child: _state is ObdDisconnected
                                    ? Text(
                                        'Connexion au boîtier OBD…',
                                        style: MabTextStyles.corpsSecondaire,
                                        textAlign: TextAlign.center,
                                      )
                                    : _state is ObdConnected
                                        ? _buildLancerDiagnosticButton()
                                        : const SizedBox.shrink(),
                              ),
                            ),
                )
              else
              Expanded(
                child: _loading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(MabColors.rouge),
                              ),
                            ),
                            const SizedBox(height: MabDimensions.espacementM),
                            Text(
                              'Chargement des appareils appairés...',
                              style: MabTextStyles.corpsSecondaire,
                            ),
                          ],
                        ),
                      )
                    : _devices.isEmpty
                        ? Center(
                            child: Padding(
                              padding: MabDimensions.paddingEcran,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bluetooth,
                                    size: MabDimensions.iconeXL,
                                    color: MabColors.grisTexte,
                                  ),
                                  const SizedBox(height: MabDimensions.espacementL),
                                  Text(
                                    _scanErrorMessage ??
                                        'Appairez d\'abord le dongle dans les réglages Bluetooth de votre téléphone, puis revenez ici.',
                                    style: MabTextStyles.corpsSecondaire,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: MabDimensions.espacementL),
                                  Text(
                                    'Le iCar Pro Vgate utilise un code PIN pour l\'appairage (Bluetooth classique).',
                                    style: MabTextStyles.label.copyWith(color: MabColors.grisTexte),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: MabDimensions.espacementL),
                                  OutlinedButton.icon(
                                    onPressed: () => _loadDevices(),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Rafraîchir'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: MabColors.rouge,
                                      side: const BorderSide(color: MabColors.rouge),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _devices.length,
                            itemBuilder: (context, index) {
                              final d = _devices[index];
                              final deviceId = d['id'] ?? '';
                              final name = d['name'] ?? deviceId;
                              final isConnected = (_state is ObdConnected && (_state as ObdConnected).deviceName == name) ||
                                  (_state is ObdConnectedNeedsProtocolDetection && (_state as ObdConnectedNeedsProtocolDetection).deviceName == name);
                              return Card(
                                color: MabColors.noirMoyen,
                                margin: const EdgeInsets.only(bottom: MabDimensions.espacementS),
                                child: ListTile(
                                  leading: Icon(
                                    isConnected
                                        ? Icons.bluetooth_connected
                                        : Icons.bluetooth,
                                    color: isConnected
                                        ? MabColors.diagnosticVert
                                        : MabColors.grisDore,
                                  ),
                                  title: Text(name, style: MabTextStyles.corpsMedium),
                                  subtitle: Text(
                                    deviceId.length > 12
                                        ? '${deviceId.substring(0, 12)}…'
                                        : deviceId,
                                    style: MabTextStyles.corpsSecondaire,
                                  ),
                                  onTap: isConnected
                                      ? null
                                      : () async {
                                          _lastConnectDeviceId = deviceId;
                                          final profile = await _repository.getVehicleProfile();
                                          await _obdService.connect(
                                            deviceId,
                                            deviceName: name,
                                            vin: profile?.vin,
                                          );
                                        },
                                ),
                              );
                            },
                          ),
              ),
            ],
            ],
          ),
        ),
        if (_state is ObdConnecting)
          _ConnectingOverlay(
            animation: _pulseController,
            secondsRemaining: _connectingSecondsRemaining,
          ),
      ],
    ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: MabDimensions.boutonHauteur,
                child: ElevatedButton.icon(
                  onPressed: _openObdPortLocationInAi,
                  icon: const Icon(Icons.help_outline, color: MabColors.blanc),
                  label: Text(
                    'Où est ma prise OBD ?',
                    style: MabTextStyles.boutonPrincipal.copyWith(
                      color: MabColors.blanc,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MabColors.rouge,
                    foregroundColor: MabColors.blanc,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MabDimensions.rayonBouton),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoScenarioSection() {
    if (_vehicleReading) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: MabDimensions.espacementM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _vehicleReadPhase,
                    style: MabTextStyles.corpsMedium.copyWith(
                      color: MabColors.blanc,
                      shadows: _kObdFloatingTextShadows,
                    ),
                  ),
                  const SizedBox(height: MabDimensions.espacementS),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(MabDimensions.rayonPetit),
                    child: LinearProgressIndicator(
                      value: _vehicleReadProgress,
                      minHeight: 8,
                      backgroundColor: MabColors.noirClair,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(MabColors.rouge),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (_vehicleResult != null) {
      return Expanded(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVehicleResultColumn(_vehicleResult!),
              const SizedBox(height: MabDimensions.espacementM),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _vehicleResult = null;
                }),
                icon: const Icon(Icons.replay),
                label: const Text('Choisir un autre scénario'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MabColors.rouge,
                  side: const BorderSide(color: MabColors.rouge),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choisissez un scénario OBD (mode démo)',
              style: MabTextStyles.titreCard,
            ),
            const SizedBox(height: MabDimensions.espacementM),
            _buildDemoScenarioCard(
              'green',
              'Scénario VERT',
              'Aucun défaut, tous les systèmes OK',
              MabColors.diagnosticVert,
              Icons.check_circle,
            ),
            const SizedBox(height: MabDimensions.espacementS),
            _buildDemoScenarioCard(
              'orange',
              'Scénario ORANGE',
              '2 codes mineurs : P0171, P0420 — témoin éteint',
              MabColors.diagnosticOrange,
              Icons.warning_amber_rounded,
            ),
            const SizedBox(height: MabDimensions.espacementS),
            _buildDemoScenarioCard(
              'red',
              'Scénario ROUGE',
              '3 codes critiques : P0301, P0562, U0100 — témoin moteur allumé',
              MabColors.diagnosticRouge,
              Icons.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoScenarioCard(
    String scenario,
    String title,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Card(
      color: MabColors.noirMoyen,
      margin: const EdgeInsets.only(bottom: MabDimensions.espacementS),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(title, style: MabTextStyles.titreCard.copyWith(color: color)),
        subtitle: Text(subtitle, style: MabTextStyles.corpsSecondaire),
        onTap: () => _runDemoReading(scenario),
      ),
    );
  }

  /// Overlay pendant la tentative de connexion au dongle : message, animation, compte à rebours.
  Widget _ConnectingOverlay({
    required Animation<double> animation,
    required int secondsRemaining,
  }) {
    final text = secondsRemaining > 0
        ? 'Connexion au dongle en cours... $secondsRemaining seconde${secondsRemaining == 1 ? '' : 's'}'
        : 'Connexion au dongle en cours...';
    return Positioned.fill(
      child: Container(
        color: MabColors.noir.withOpacity(0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _PulsingCirclesPainter(
                        progress: animation.value,
                        color: MabColors.rouge,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: MabDimensions.espacementL),
              Text(
                text,
                style: MabTextStyles.corpsMedium.copyWith(color: MabColors.blanc),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MabDimensions.espacementS),
              Text(
                'Vérifiez que le dongle est branché sur la voiture',
                style: MabTextStyles.corpsSecondaire,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MabDimensions.espacementL),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(MabColors.rouge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isObdConnectedForClear() {
    return _state is ObdConnected ||
        _state is ObdConnectedNeedsProtocolDetection;
  }

  bool _shouldOfferClearDtc(ObdVehicleResult result) {
    if (result.dtcs.isEmpty) return false;
    if (_isDemoMode) return true;
    return _isObdConnectedForClear();
  }

  Widget _buildVehicleResultColumn(ObdVehicleResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildVehicleResultFloating(result),
        if (_shouldOfferClearDtc(result)) ...[
          const SizedBox(height: MabDimensions.espacementM),
          _buildClearDtcButton(),
        ],
      ],
    );
  }

  Widget _buildClearDtcButton() {
    return SizedBox(
      width: double.infinity,
      height: MabDimensions.boutonHauteur,
      child: ElevatedButton(
        onPressed: _clearingDtc ? null : () => unawaited(_onClearDtcPressed()),
        style: ElevatedButton.styleFrom(
          backgroundColor: MabColors.rouge,
          foregroundColor: MabColors.blanc,
          disabledBackgroundColor: MabColors.grisContour,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MabDimensions.rayonBouton),
          ),
        ),
        child: _clearingDtc
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MabColors.blanc,
                ),
              )
            : Text(
                'Effacer les codes',
                style: MabTextStyles.boutonPrincipal.copyWith(
                  color: MabColors.blanc,
                ),
              ),
      ),
    );
  }

  static const String _kClearDtcFailureMessage =
      'L\'effacement n\'a pas pu être effectué. Vérifie que le contact est allumé '
      'et que le dongle est bien connecté.';

  Future<void> _onClearDtcPressed() async {
    final confirmed = await showMabClearDtcConfirmDialog(context);
    if (!confirmed || !mounted) return;

    if (_isDemoMode) {
      setState(() {
        _vehicleResult = const ObdVehicleResult(
          level: 'green',
          message: 'Aucun défaut détecté.',
          dtcs: [],
          milOn: false,
          storedDtcs: [],
          pendingDtcs: [],
          permanentDtcs: [],
        );
      });
      if (!mounted) return;
      unawaited(TtsService.instance.speakAfterDtcClear());
      await showMabDtcClearSuccessInfoDialog(context);
      return;
    }

    if (!_isObdConnectedForClear()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: MabColors.noirMoyen,
          content: Text(
            _kClearDtcFailureMessage,
            style: MabTextStyles.corpsNormal.copyWith(color: MabColors.blanc),
          ),
        ),
      );
      return;
    }

    if (LiveMonitoringService.instance.isMonitoringActive) {
      if (!mounted) return;
      await showMabDiagnosticBlockedBySurveillanceDialog(
        context,
        onGoToModeConduite: () {
          Navigator.of(context).pushNamed('/surveillance-only');
        },
      );
      return;
    }

    setState(() => _clearingDtc = true);
    try {
      final success = await _obdService.clearDtcCodes();
      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: MabColors.noirMoyen,
            content: Text(
              _kClearDtcFailureMessage,
              style: MabTextStyles.corpsNormal.copyWith(color: MabColors.blanc),
            ),
          ),
        );
        return;
      }
      final last = await _repository.getLastObdDiagnostic();
      await _repository.saveLastObdDiagnostic(
        DateTime.now(),
        milOn: false,
        storedDtcs: const [],
        pendingDtcs: const [],
        permanentDtcs: const [],
        kmAtScan: last.kmAtScan,
      );
      if (!mounted) return;
      setState(() {
        _vehicleResult = const ObdVehicleResult(
          level: 'green',
          message: 'Aucun défaut détecté.',
          dtcs: [],
          milOn: false,
          storedDtcs: [],
          pendingDtcs: [],
          permanentDtcs: [],
        );
      });
      if (!mounted) return;
      unawaited(TtsService.instance.speakAfterDtcClear());
      await showMabDtcClearSuccessInfoDialog(context);
    } on ObdScanException catch (e) {
      if (!mounted) return;
      if (e.message == kObdSurveillanceBlockedCode) {
        await showMabDiagnosticBlockedBySurveillanceDialog(
          context,
          onGoToModeConduite: () {
            Navigator.of(context).pushNamed('/surveillance-only');
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _clearingDtc = false);
      }
    }
  }

  /// Résultat diagnostic sans cadre — texte sur filigrane (ombres pour lisibilité).
  Widget _buildVehicleResultFloating(ObdVehicleResult result) {
    final (Color color, IconData icon) = switch (result.level) {
      'green' => (MabColors.diagnosticVert, Icons.check_circle),
      'red' => (MabColors.diagnosticRouge, Icons.error),
      'incomplete' => (MabColors.diagnosticOrange, Icons.info_outline),
      _ => (MabColors.diagnosticOrange, Icons.warning),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: MabDimensions.espacementM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: MabDimensions.iconeL),
              const SizedBox(width: MabDimensions.espacementM),
              Expanded(
                child: Text(
                  result.message,
                  style: MabTextStyles.corpsMedium.copyWith(
                    color: color,
                    shadows: _kObdFloatingTextShadows,
                  ),
                ),
              ),
            ],
          ),
          if (result.dtcs.isNotEmpty) ...[
            const SizedBox(height: MabDimensions.espacementS),
            Text(
              'Codes défaut : ${result.dtcs.join(", ")}',
              style: MabTextStyles.corpsSecondaire.copyWith(
                color: MabColors.blanc,
                shadows: _kObdFloatingTextShadows,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLancerDiagnosticButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: MabDimensions.espacementM),
      child: SizedBox(
        width: double.infinity,
        height: MabDimensions.boutonHauteur,
        child: ElevatedButton.icon(
          onPressed: _vehicleReading ? null : () => unawaited(_readVehicleData()),
          icon: const Icon(Icons.search_rounded, color: MabColors.blanc),
          label: Text(
            'Lancer le diagnostic',
            style: MabTextStyles.boutonPrincipal.copyWith(color: MabColors.blanc),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: MabColors.rouge,
            foregroundColor: MabColors.blanc,
            disabledBackgroundColor: MabColors.grisContour,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MabDimensions.rayonBouton),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateCard() {
    final (String label, Color color) = switch (_state) {
      ObdConnected(deviceName: final n) => ('Connecté : $n', MabColors.diagnosticVert),
      ObdConnectedNeedsProtocolDetection(deviceName: final n) => ('Adaptation au véhicule : $n', MabColors.diagnosticOrange),
      ObdConnecting() => ('Connexion en cours…', MabColors.diagnosticOrange),
      ObdBluetoothDisabled() => ('Bluetooth désactivé', MabColors.diagnosticOrange),
      ObdDeviceNotFound() => ('Appareil non trouvé', MabColors.diagnosticRouge),
      ObdError(message: final m) => (m, MabColors.diagnosticRouge),
      ObdDisconnected() => ('Non connecté', MabColors.grisTexte),
      _ => ('Non connecté', MabColors.grisTexte),
    };
    return Container(
      padding: MabDimensions.paddingCard,
      decoration: BoxDecoration(
        color: MabColors.noirMoyen,
        borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            (_state is ObdConnected || _state is ObdConnectedNeedsProtocolDetection) ? Icons.bluetooth_connected : Icons.bluetooth,
            color: color,
            size: MabDimensions.iconeL,
          ),
          const SizedBox(width: MabDimensions.espacementM),
          Expanded(
            child: Text(
              label,
              style: MabTextStyles.corpsMedium.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dessine des cercles concentriques qui pulsent (effet radar / vague).
class _PulsingCirclesPainter extends CustomPainter {
  final double progress;
  final Color color;

  _PulsingCirclesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const circleCount = 3;
    final maxRadius = size.width / 2;

    for (var i = 0; i < circleCount; i++) {
      final phase = (progress + i / circleCount) % 1.0;
      final scale = 0.2 + 0.8 * phase;
      final opacity = (1.0 - phase).clamp(0.0, 1.0);
      final radius = maxRadius * scale;
      final paint = Paint()
        ..color = color.withOpacity(0.15 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulsingCirclesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
