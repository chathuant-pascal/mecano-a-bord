// obd_scan_screen.dart — Mécano à Bord (Flutter iOS + Android)
//
// Écran OBD — gère 3 états successifs dans le même écran :
//
//  ÉTAT 1 — CONNEXION
//    Recherche du boîtier ELM327 en Bluetooth
//    Animation de recherche + message rassurant
//    Bouton "Mode démo" si pas de boîtier
//
//  ÉTAT 2 — SCAN EN COURS
//    Animation de progression
//    Messages d'étape rassurants
//
//  ÉTAT 3 — RÉSULTAT
//    Grand cercle coloré VERT / ORANGE / ROUGE
//    Résumé en langage humain
//    Bouton "En savoir plus" ou "Démarrer la surveillance"

import 'dart:math';
import 'package:flutter/material.dart';
import 'mab_repository.dart';
import 'mab_database.dart';
import 'bluetooth_obd_service.dart';
import 'monitoring_background_service.dart';

// ─────────────────────────────────────────────
// ÉTATS DE L'ÉCRAN
// ─────────────────────────────────────────────

enum _ScanState { connecting, scanning, result }

// ─────────────────────────────────────────────
// ÉCRAN PRINCIPAL
// ─────────────────────────────────────────────

class ObdScanScreen extends StatefulWidget {
  /// Mode d'entrée : "DIAGNOSTIC", "DRIVING" ou "DEMO"
  final String mode;

  const ObdScanScreen({super.key, this.mode = 'DIAGNOSTIC'});

  @override
  State<ObdScanScreen> createState() => _ObdScanScreenState();
}

class _ObdScanScreenState extends State<ObdScanScreen>
    with SingleTickerProviderStateMixin {

  late String _mode;
  _ScanState _state = _ScanState.connecting;

  // Données affichées
  String _connectingMessage = 'Recherche du boîtier…\nAssurez-vous qu\'il est bien branché.';
  bool _showDemoButton = false;
  String _scanStep = '';
  double _scanProgress = 0;

  // Résultat
  RiskLevel? _riskLevel;
  String _resultTitle   = '';
  String _resultSummary = '';
  DiagnosticSession? _currentSession;

  // Services
  late final MabRepository _repository;
  final BluetoothObdService _obdService = BluetoothObdService();

  // Animation du cercle résultat
  late AnimationController _circleAnimController;
  late Animation<double> _circleScaleAnim;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _repository = MabRepository(MabDatabase());

    _circleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _circleScaleAnim = CurvedAnimation(
      parent: _circleAnimController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _startFlow());
  }

  // ─────────────────────────────────────────────
  // DÉMARRAGE DU FLUX
  // ─────────────────────────────────────────────

  void _startFlow() {
    switch (_mode) {
      case 'DEMO':    _startDemoFlow();        break;
      case 'DRIVING': _startDrivingMode();     break;
      default:        _startDiagnosticFlow();  break;
    }
  }

  // ─────────────────────────────────────────────
  // ÉTAT 1 — CONNEXION
  // ─────────────────────────────────────────────

  Future<void> _startDiagnosticFlow() async {
    _setConnecting('Recherche du boîtier…\nAssurez-vous qu\'il est bien branché.');

    final connected = await _obdService.connect();
    if (!mounted) return;

    if (connected) {
      _startScanAnimation();
    } else {
      _setConnecting(
        'Boîtier introuvable.\nVérifiez qu\'il est bien branché dans le port OBD '
        'sous votre tableau de bord et que le Bluetooth est activé.',
        showDemo: true,
      );
    }
  }

  // ─────────────────────────────────────────────
  // ÉTAT 2 — SCAN EN COURS
  // ─────────────────────────────────────────────

  Future<void> _startScanAnimation() async {
    setState(() => _state = _ScanState.scanning);

    final steps = [
      'Connexion au calculateur…',
      'Lecture des données moteur…',
      'Vérification des capteurs…',
      'Analyse des codes…',
      'Préparation du résultat…',
    ];

    for (int i = 0; i < steps.length; i++) {
      if (!mounted) return;
      setState(() {
        _scanStep     = steps[i];
        _scanProgress = (i + 1) / steps.length;
      });
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // Lire les données OBD réelles
    final obdData = await _obdService.readCurrentData();
    if (!mounted) return;

    final session = _buildSession(
      dtcCodes:    obdData?.activeDtcCodes ?? [],
      engineTemp:  obdData?.engineTempCelsius ?? 85,
      oilPressure: obdData?.oilPressureBar ?? 3.5,
    );
    await _repository.saveDiagnosticSession(session);
    _showResult(session);
  }

  // ─────────────────────────────────────────────
  // ÉTAT 3 — RÉSULTAT
  // ─────────────────────────────────────────────

  void _showResult(DiagnosticSession session) {
    _currentSession = session;
    setState(() {
      _state       = _ScanState.result;
      _riskLevel   = session.riskLevel;
      _resultSummary = session.humanSummary;
      _resultTitle = switch (session.riskLevel) {
        RiskLevel.green  => 'Tout va bien !',
        RiskLevel.orange => 'Un point à surveiller',
        RiskLevel.red    => 'Votre attention est nécessaire',
      };
    });
    _circleAnimController.forward(from: 0);
  }

  // ─────────────────────────────────────────────
  // MODE DÉMO
  // ─────────────────────────────────────────────

  Future<void> _startDemoFlow() async {
    setState(() {
      _state    = _ScanState.scanning;
      _scanStep = 'Mode démo — simulation en cours…';
    });

    final demoSteps = [
      'Simulation de la connexion OBD…',
      'Lecture des données fictives…',
      'Analyse en cours…',
    ];

    for (int i = 0; i < demoSteps.length; i++) {
      if (!mounted) return;
      setState(() {
        _scanStep     = demoSteps[i];
        _scanProgress = (i + 1) / demoSteps.length;
      });
      await Future.delayed(const Duration(milliseconds: 700));
    }

    // Scénario aléatoire pour la démo
    final scenarios = [RiskLevel.green, RiskLevel.orange, RiskLevel.red];
    final picked = scenarios[Random().nextInt(scenarios.length)];

    final session = switch (picked) {
      RiskLevel.green => _buildSession(
          dtcCodes: [], engineTemp: 87, oilPressure: 3.5,
          summary: 'Votre véhicule fonctionne normalement. Aucune anomalie détectée. Bonne route !'),
      RiskLevel.orange => _buildSession(
          dtcCodes: ['P0171'], engineTemp: 108, oilPressure: 1.2,
          summary: 'Un capteur mérite votre attention. Pas d\'urgence, mais un diagnostic professionnel est conseillé.'),
      _ => _buildSession(
          dtcCodes: ['P0300', 'P0128'], engineTemp: 118, oilPressure: 0.6,
          summary: 'Votre véhicule nécessite une attention particulière. Évitez les longs trajets et consultez un professionnel.'),
    };

    if (!mounted) return;
    _showResult(session);
  }

  // ─────────────────────────────────────────────
  // MODE CONDUITE
  // ─────────────────────────────────────────────

  Future<void> _startDrivingMode() async {
    _setConnecting('Démarrage de la surveillance…\nVous pouvez poser votre téléphone.');
    final connected = await _obdService.connect();
    if (!mounted) return;

    if (connected) {
      await MonitoringServiceManager.startMonitoring();
      _setConnecting(
        'Surveillance active ✓\nVous pouvez ranger votre téléphone. '
        'Je vous alerterai vocalement si nécessaire.',
      );
    } else {
      _setConnecting(
        'Impossible de démarrer la surveillance.\n'
        'Vérifiez que le boîtier est branché et que le Bluetooth est activé.',
        showDemo: true,
      );
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  void _setConnecting(String message, {bool showDemo = false}) {
    if (!mounted) return;
    setState(() {
      _state             = _ScanState.connecting;
      _connectingMessage = message;
      _showDemoButton    = showDemo;
    });
  }

  DiagnosticSession _buildSession({
    required List<String> dtcCodes,
    required int engineTemp,
    required double oilPressure,
    String? summary,
  }) {
    final riskLevel = engineTemp >= 120 || oilPressure <= 0.5
        ? RiskLevel.red
        : (engineTemp >= 108 || oilPressure <= 1.0 || dtcCodes.isNotEmpty)
            ? RiskLevel.orange
            : RiskLevel.green;

    final humanSummary = summary ?? switch (riskLevel) {
      RiskLevel.green  => 'Votre véhicule fonctionne normalement. Aucune anomalie détectée. Bonne route !',
      RiskLevel.orange => 'Un ou plusieurs points méritent votre attention. Un diagnostic professionnel est conseillé prochainement.',
      RiskLevel.red    => 'Votre véhicule nécessite une attention particulière. Évitez les longs trajets et consultez un professionnel dès que possible.',
    };

    return DiagnosticSession(
      id:               DateTime.now().millisecondsSinceEpoch.toString(),
      vehicleProfileId: 'active',
      timestamp:        DateTime.now().millisecondsSinceEpoch,
      riskLevel:        riskLevel,
      dtcCodes:         dtcCodes,
      humanSummary:     humanSummary,
    );
  }

  // ─────────────────────────────────────────────
  // INTERFACE
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          switch (_mode) {
            'DEMO'    => 'Mode démo',
            'DRIVING' => 'Mode conduite',
            _         => 'Diagnostic',
          },
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: switch (_state) {
          _ScanState.connecting => _buildConnectingView(),
          _ScanState.scanning   => _buildScanningView(),
          _ScanState.result     => _buildResultView(),
        },
      ),
    );
  }

  // ─── Vue Connexion ───────────────────────────

  Widget _buildConnectingView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation Bluetooth
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            builder: (_, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bluetooth_searching_rounded,
                size: 56,
                color: Color(0xFF2196F3),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            _connectingMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF5A5A72),
              height: 1.6,
            ),
          ),
          if (_showDemoButton) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Essayer le mode démo'),
                onPressed: () {
                  setState(() {
                    _mode           = 'DEMO';
                    _showDemoButton = false;
                  });
                  _startDemoFlow();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Vue Scan en cours ───────────────────────

  Widget _buildScanningView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône animée
          const Icon(
            Icons.radar_rounded,
            size: 80,
            color: Color(0xFF2196F3),
          ),
          const SizedBox(height: 36),
          Text(
            _scanStep,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF5A5A72),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _scanProgress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE3F2FD),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Vue Résultat ────────────────────────────

  Widget _buildResultView() {
    final color = switch (_riskLevel) {
      RiskLevel.green  => const Color(0xFF4CAF50),
      RiskLevel.orange => const Color(0xFFFF9800),
      RiskLevel.red    => const Color(0xFFF44336),
      _                => const Color(0xFF9E9E9E),
    };
    final emoji = switch (_riskLevel) {
      RiskLevel.green  => '✅',
      RiskLevel.orange => '⚠️',
      _                => '🔴',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Grand cercle coloré animé
          ScaleTransition(
            scale: _circleScaleAnim,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 4),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 64)),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Titre
          Text(
            _resultTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 16),

          // Résumé
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _resultSummary,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF5A5A72),
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Boutons selon le niveau
          if (_riskLevel == RiskLevel.green)
            _buildResultButton(
              label: 'Démarrer la surveillance',
              icon: Icons.directions_car_rounded,
              color: const Color(0xFF4CAF50),
              onTap: () {
                setState(() => _mode = 'DRIVING');
                _startDrivingMode();
              },
            ),

          if (_riskLevel != RiskLevel.green)
            _buildResultButton(
              label: 'En savoir plus',
              icon: Icons.info_outline_rounded,
              color: color,
              onTap: () => Navigator.pushNamed(
                context,
                '/diagnostic-detail',
                arguments: _currentSession?.id,
              ),
            ),

          const SizedBox(height: 12),

          // Nouveau scan
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Nouveau scan'),
              onPressed: () {
                _circleAnimController.reset();
                setState(() {
                  _mode           = 'DIAGNOSTIC';
                  _currentSession = null;
                });
                _startDiagnosticFlow();
              },
              style: OutlinedButton.styleFrom(
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

  Widget _buildResultButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _circleAnimController.dispose();
    if (_mode != 'DRIVING') _obdService.dispose();
    super.dispose();
  }
}
