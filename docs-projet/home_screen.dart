// home_screen.dart — Mécano à Bord (Flutter iOS + Android)
//
// Écran d'accueil principal de l'application.
//
// Contenu :
//  - En-tête : nom du véhicule + état connexion OBD
//  - Carte rappels d'entretien à venir
//  - Accès rapide Boîte à gants
//  - 4 boutons d'action : Diagnostic / Mode conduite / Mode démo / IA
//  - Barre de navigation en bas : Accueil / OBD / Boîte à gants / IA / Réglages

import 'package:flutter/material.dart';
import 'mab_repository.dart';
import 'mab_database.dart';
import 'bluetooth_obd_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // Services
  late final MabRepository _repository;
  final BluetoothObdService _obdService = BluetoothObdService();

  // Données affichées
  VehicleProfile? _vehicleProfile;
  List<MaintenanceEntry> _maintenanceAlerts = [];
  List<GloveboxDocument> _expiringDocs = [];
  ObdConnectionState _obdState = const ObdDisconnected();

  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository = MabRepository(MabDatabase());
    _loadData();
    // Écouter les changements d'état OBD
    _obdService.connectionState.listen((state) {
      if (mounted) setState(() => _obdState = state);
    });
  }

  Future<void> _loadData() async {
    final profile   = await _repository.getActiveVehicleProfile();
    final alerts    = await _repository.getUpcomingMaintenanceAlerts(profile?.mileage ?? 0);
    final expiring  = await _repository.getExpiringDocuments();
    if (mounted) {
      setState(() {
        _vehicleProfile    = profile;
        _maintenanceAlerts = alerts;
        _expiringDocs      = expiring;
      });
    }
  }

  // ─────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    switch (index) {
      case 1: Navigator.pushNamed(context, '/obd-scan'); break;
      case 2: Navigator.pushNamed(context, '/glovebox'); break;
      case 3: Navigator.pushNamed(context, '/ai-chat'); break;
      case 4: Navigator.pushNamed(context, '/settings'); break;
    }
  }

  // ─────────────────────────────────────────────
  // ACTIONS BOUTONS
  // ─────────────────────────────────────────────

  Future<void> _launchDiagnostic() async {
    final complete = await _repository.isVehicleProfileComplete();
    if (!mounted) return;
    if (complete) {
      Navigator.pushNamed(context, '/obd-scan', arguments: 'DIAGNOSTIC');
    } else {
      _showProfileIncompleteDialog();
    }
  }

  Future<void> _launchDrivingMode() async {
    final complete = await _repository.isVehicleProfileComplete();
    if (!mounted) return;
    if (complete) {
      Navigator.pushNamed(context, '/obd-scan', arguments: 'DRIVING');
    } else {
      _showProfileIncompleteDialog();
    }
  }

  void _launchDemo() =>
      Navigator.pushNamed(context, '/obd-scan', arguments: 'DEMO');

  void _launchAi() =>
      Navigator.pushNamed(context, '/ai-chat');

  void _showProfileIncompleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  // ─────────────────────────────────────────────
  // INTERFACE
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildObdStatusCard(),
                const SizedBox(height: 16),
                if (_maintenanceAlerts.isNotEmpty) ...[
                  _buildMaintenanceCard(),
                  const SizedBox(height: 16),
                ],
                _buildGloveboxCard(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── En-tête ────────────────────────────────

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
              Text(
                vehicleName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                mileage,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
        // Icône réglages rapide
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Color(0xFF9E9E9E)),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
    );
  }

  // ─── Carte état OBD ─────────────────────────

  Widget _buildObdStatusCard() {
    final (label, color, icon) = switch (_obdState) {
      ObdConnected(deviceName: final name) =>
          ('Connecté — $name', const Color(0xFF4CAF50), Icons.bluetooth_connected),
      ObdConnecting() =>
          ('Connexion en cours…', const Color(0xFFFF9800), Icons.bluetooth_searching),
      ObdBluetoothDisabled() =>
          ('Bluetooth désactivé', const Color(0xFF9E9E9E), Icons.bluetooth_disabled),
      ObdDeviceNotFound() =>
          ('Boîtier introuvable', const Color(0xFFFF9800), Icons.bluetooth_searching),
      ObdError(message: _) =>
          ('Erreur de connexion', const Color(0xFFFF9800), Icons.warning_amber_outlined),
      _ =>
          ('Boîtier non connecté', const Color(0xFF9E9E9E), Icons.bluetooth_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Carte rappels entretien ─────────────────

  Widget _buildMaintenanceCard() {
    final count = _maintenanceAlerts.length;
    final label = count == 1
        ? '1 entretien bientôt prévu : ${_maintenanceAlerts.first.entryType.toLowerCase()}'
        : '$count entretiens bientôt prévus';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/glovebox', arguments: 'MAINTENANCE'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFE082), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.build_outlined, color: Color(0xFFFF9800), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6D4C00),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFFF9800)),
          ],
        ),
      ),
    );
  }

  // ─── Carte Boîte à gants ─────────────────────

  Widget _buildGloveboxCard() {
    final summary = _expiringDocs.isNotEmpty
        ? '⚠️ ${_expiringDocs.length} document(s) expire(nt) bientôt'
        : 'Tous vos documents sont à jour ✓';
    final summaryColor = _expiringDocs.isNotEmpty
        ? const Color(0xFFE65100)
        : const Color(0xFF388E3C);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/glovebox'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_outlined,
                  color: Color(0xFF2196F3), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Boîte à gants',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    summary,
                    style: TextStyle(fontSize: 13, color: summaryColor),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }

  // ─── Boutons d'action ────────────────────────

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Que voulez-vous faire ?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 14),

        // Bouton principal : Lancer un diagnostic
        _ActionButton(
          icon: Icons.search_rounded,
          label: 'Lancer un diagnostic',
          subtitle: 'Scan complet de votre véhicule',
          color: const Color(0xFF2196F3),
          onTap: _launchDiagnostic,
        ),

        const SizedBox(height: 10),

        // Bouton : Mode conduite
        _ActionButton(
          icon: Icons.directions_car_rounded,
          label: 'Mode conduite',
          subtitle: 'Surveillance en arrière-plan',
          color: const Color(0xFF4CAF50),
          onTap: _launchDrivingMode,
        ),

        const SizedBox(height: 10),

        // Boutons secondaires côte à côte : Démo + IA
        Row(
          children: [
            Expanded(
              child: _ActionButtonSmall(
                icon: Icons.play_circle_outline_rounded,
                label: 'Mode démo',
                color: const Color(0xFF9C27B0),
                onTap: _launchDemo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButtonSmall(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Poser une question',
                color: const Color(0xFFFF9800),
                onTap: _launchAi,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Barre de navigation ─────────────────────

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: _onNavTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF2196F3),
      unselectedItemColor: const Color(0xFF9E9E9E),
      selectedFontSize: 12,
      unselectedFontSize: 12,
      elevation: 12,
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
    _obdService.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
// WIDGETS BOUTONS RÉUTILISABLES
// ─────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.8), size: 16),
          ],
        ),
      ),
    );
  }
}

class _ActionButtonSmall extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButtonSmall({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
