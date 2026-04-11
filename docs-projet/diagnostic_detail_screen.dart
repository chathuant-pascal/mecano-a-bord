import 'package:flutter/material.dart';
import '../../data/mab_repository.dart';
import '../../data/model/diagnostic_session.dart';
import '../../data/model/dtc_info.dart';
import '../../data/model/risk_level.dart';
import '../ai/ai_chat_screen.dart';

/// MÉCANO À BORD — diagnostic_detail_screen.dart
/// ─────────────────────────────────────────────────────────────
/// Écran d'affichage détaillé d'une session de diagnostic OBD
/// (iOS + Android).
///
/// Même logique que la version Android :
///   - En-tête coloré vert / orange / rouge
///   - Résumé en langage humain
///   - Codes DTC expliqués en français
///   - Suggestion d'action adaptée
///   - Bouton vers le chat IA pour approfondir
/// ─────────────────────────────────────────────────────────────

class DiagnosticDetailScreen extends StatefulWidget {
  final int sessionId;

  const DiagnosticDetailScreen({super.key, required this.sessionId});

  @override
  State<DiagnosticDetailScreen> createState() => _DiagnosticDetailScreenState();
}

class _DiagnosticDetailScreenState extends State<DiagnosticDetailScreen> {

  final _repository = MabRepository.instance;
  DiagnosticSession? _session;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await _repository.getDiagnosticSessionById(widget.sessionId);
    if (mounted) {
      setState(() {
        _session   = session;
        _isLoading = false;
      });
    }
  }

  // ── Couleurs et textes selon le niveau de risque ──────────
  Color _headerColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.green:  return const Color(0xFF2E7D32);
      case RiskLevel.orange: return const Color(0xFFE65100);
      case RiskLevel.red:    return const Color(0xFFC62828);
    }
  }

  String _riskEmoji(RiskLevel level) {
    switch (level) {
      case RiskLevel.green:  return '✅';
      case RiskLevel.orange: return '⚠️';
      case RiskLevel.red:    return '🔴';
    }
  }

  String _riskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.green:  return 'Tout va bien';
      case RiskLevel.orange: return 'À surveiller';
      case RiskLevel.red:    return 'Attention requise';
    }
  }

  // Suggestion d'action selon le niveau
  Map<String, String> _actionInfo(RiskLevel level) {
    switch (level) {
      case RiskLevel.green:
        return {
          'title': 'Vous pouvez continuer à rouler normalement',
          'body':  'Votre véhicule ne présente aucun problème détecté. '
                   'Continuez à rouler sereinement et pensez à vos entretiens réguliers.',
        };
      case RiskLevel.orange:
        return {
          'title': 'À surveiller dans les prochains jours',
          'body':  'Votre véhicule présente un ou plusieurs points d\'attention. '
                   'Vous pouvez continuer à rouler, mais prenez rendez-vous chez un '
                   'professionnel dans les prochains jours pour un contrôle.',
        };
      case RiskLevel.red:
        return {
          'title': 'Consultez un professionnel dès que possible',
          'body':  'Votre véhicule présente un problème qui mérite attention. '
                   'Évitez les longs trajets et faites vérifier votre véhicule '
                   'par un professionnel rapidement.',
        };
    }
  }

  String _aiButtonLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.green:  return 'Poser une question sur mon véhicule';
      case RiskLevel.orange: return 'En savoir plus sur ce problème';
      case RiskLevel.red:    return 'Comprendre ce problème en détail';
    }
  }

  // ── Formatage date ────────────────────────────────────────
  String _formatDate(DateTime date) {
    const months = ['janvier','février','mars','avril','mai','juin',
                    'juillet','août','septembre','octobre','novembre','décembre'];
    return '${date.day} ${months[date.month - 1]} ${date.year} '
           'à ${date.hour.toString().padLeft(2,'0')}h${date.minute.toString().padLeft(2,'0')}';
  }

  String _formatMileage(int? km) {
    if (km == null) return 'Kilométrage non renseigné';
    // Ajoute un espace tous les 3 chiffres : 87500 → 87 500
    final s = km.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '${buffer.toString()} km';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}min ${seconds % 60}s';
  }

  // ── Interface ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat du diagnostic'),
        backgroundColor: _session != null
            ? _headerColor(_session!.riskLevel)
            : const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _session == null
              ? _buildNotFound()
              : _buildContent(_session!),
    );
  }

  Widget _buildNotFound() {
    return const Center(
      child: Text('Diagnostic introuvable.',
          style: TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildContent(DiagnosticSession session) {
    final color  = _headerColor(session.riskLevel);
    final action = _actionInfo(session.riskLevel);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── En-tête coloré ─────────────────────────────
          _buildHeader(session, color),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Informations de la session ────────────
                _buildInfoCard(session),
                const SizedBox(height: 20),

                // ── Résumé humain ─────────────────────────
                _buildSectionTitle('Ce que ça veut dire pour vous'),
                const SizedBox(height: 10),
                Text(
                  session.humanSummary,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Codes DTC ─────────────────────────────
                if (session.dtcCodes.isNotEmpty) ...[
                  _buildSectionTitle(
                    'Codes détectés (${session.dtcCodes.length})',
                  ),
                  const SizedBox(height: 10),
                  ...session.dtcCodes.map((dtc) => _buildDtcCard(dtc)),
                  const SizedBox(height: 24),
                ],

                // ── Suggestion d'action ───────────────────
                _buildActionCard(action, color),
                const SizedBox(height: 20),

                // ── Badge protégé si rouge ────────────────
                if (session.riskLevel == RiskLevel.red)
                  _buildProtectedBadge(),

                const SizedBox(height: 20),

                // ── Bouton chat IA ────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_outlined),
                    label: Text(_aiButtonLabel(session.riskLevel)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AiChatScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── En-tête coloré ────────────────────────────────────────
  Widget _buildHeader(DiagnosticSession session, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      color: color,
      child: Column(
        children: [
          Text(
            _riskEmoji(session.riskLevel),
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            _riskLabel(session.riskLevel),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Carte d'informations ──────────────────────────────────
  Widget _buildInfoCard(DiagnosticSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today,  'Date',        _formatDate(session.date)),
          const Divider(height: 16),
          _buildInfoRow(Icons.speed,           'Kilométrage', _formatMileage(session.mileageAtScan)),
          const Divider(height: 16),
          _buildInfoRow(Icons.timer,           'Durée',       _formatDuration(session.durationSeconds)),
          if (session.vehicleName != null) ...[
            const Divider(height: 16),
            _buildInfoRow(Icons.directions_car, 'Véhicule',   session.vehicleName!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text('$label : ',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14)),
        ),
      ],
    );
  }

  // ── Carte d'un code DTC ───────────────────────────────────
  Widget _buildDtcCard(DtcInfo dtc) {
    final urgencyColor = switch (dtc.urgencyLevel) {
      1 => Colors.blue,
      2 => Colors.orange,
      3 => Colors.red,
      _ => Colors.grey,
    };

    final urgencyLabel = switch (dtc.urgencyLevel) {
      1 => 'ℹ️ Information',
      2 => '⚠️ À surveiller',
      3 => '🔴 Urgent',
      _ => '',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: urgencyColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code + badge urgence
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dtc.code,
                  style: TextStyle(
                    color: urgencyColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(urgencyLabel,
                  style: TextStyle(fontSize: 12, color: urgencyColor)),
            ],
          ),
          const SizedBox(height: 10),

          // Description technique
          Text(
            dtc.descriptionFr,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),

          // Explication en langage humain
          Text(
            dtc.humanExplanation ?? dtc.descriptionFr,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Carte de suggestion d'action ──────────────────────────
  Widget _buildActionCard(Map<String, String> action, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_outlined, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action['title']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  action['body']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Badge "diagnostic protégé" ────────────────────────────
  Widget _buildProtectedBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ce diagnostic est protégé et ne peut pas être supprimé.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A73E8),
        ),
      );
}
