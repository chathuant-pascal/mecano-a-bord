// settings_screen.dart — Mécano à Bord (Flutter iOS + Android)
//
// Écran de réglages — organisé en 4 sections :
//
//  1. COACH VOCAL    — Voix féminine/masculine, alertes vocales on/off
//  2. ASSISTANT IA   — Mode gratuit/personnel, clé API ChatGPT ou Gemini
//  3. SURVEILLANCE   — Mode AUTO/MANUEL, délai d'arrêt automatique
//  4. APPLICATION    — Version, confidentialité, aide, réinitialisation

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ai_conversation_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final AiConversationService _aiService = AiConversationService();

  // ─── Voix ───
  String _voiceGender      = 'FEMININE';
  bool   _voiceAlertsEnabled = true;

  // ─── IA ───
  AiMode   _aiMode             = AiMode.free;
  int      _freeQuestionsLeft  = 5;
  AiProvider _aiProvider       = AiProvider.chatgpt;
  final _apiKeyController      = TextEditingController();
  bool  _apiKeyVisible         = false;

  // ─── Surveillance ───
  String _monitoringMode = 'AUTO';
  int    _stopDelayIndex = 1; // 0=30s 1=60s 2=2min

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAiStatus();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceGender        = prefs.getString('voice_gender')        ?? 'FEMININE';
      _voiceAlertsEnabled = prefs.getBool('voice_alerts_enabled')  ?? true;
      _monitoringMode     = prefs.getString('monitoring_mode')     ?? 'AUTO';
      _stopDelayIndex     = prefs.getInt('stop_delay_index')       ?? 1;
    });
  }

  Future<void> _loadAiStatus() async {
    final mode      = await _aiService.getCurrentMode();
    final remaining = await _aiService.getRemainingFreeQuestions();
    if (mounted) {
      setState(() {
        _aiMode            = mode;
        _freeQuestionsLeft = remaining;
      });
    }
  }

  Future<void> _savePref(Future<void> Function(SharedPreferences) action) async {
    final prefs = await SharedPreferences.getInstance();
    await action(prefs);
  }

  // ─────────────────────────────────────────────
  // INTERFACE
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Réglages',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildVoiceSection(),
          const SizedBox(height: 20),
          _buildAiSection(),
          const SizedBox(height: 20),
          _buildMonitoringSection(),
          const SizedBox(height: 20),
          _buildAppSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION 1 — COACH VOCAL
  // ─────────────────────────────────────────────

  Widget _buildVoiceSection() {
    return _SettingsSection(
      title: '🎙️ Coach vocal',
      children: [

        // Choix de la voix
        _SettingsLabel('Voix'),
        Row(
          children: [
            Expanded(
              child: _ChoiceChip(
                label: 'Féminine',
                selected: _voiceGender == 'FEMININE',
                onTap: () async {
                  setState(() => _voiceGender = 'FEMININE');
                  await _savePref((p) async =>
                      p.setString('voice_gender', 'FEMININE'));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ChoiceChip(
                label: 'Masculine',
                selected: _voiceGender == 'MASCULINE',
                onTap: () async {
                  setState(() => _voiceGender = 'MASCULINE');
                  await _savePref((p) async =>
                      p.setString('voice_gender', 'MASCULINE'));
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Alertes vocales on/off
        _SettingsSwitchRow(
          label: 'Alertes vocales',
          subtitle: 'Annonces pendant la surveillance',
          value: _voiceAlertsEnabled,
          onChanged: (v) async {
            setState(() => _voiceAlertsEnabled = v);
            await _savePref((p) async =>
                p.setBool('voice_alerts_enabled', v));
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SECTION 2 — ASSISTANT IA
  // ─────────────────────────────────────────────

  Widget _buildAiSection() {
    return _SettingsSection(
      title: '🤖 Assistant IA',
      children: [

        // Statut actuel
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _aiMode == AiMode.personal
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFF3E5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                _aiMode == AiMode.personal
                    ? Icons.verified_outlined
                    : Icons.info_outline,
                color: _aiMode == AiMode.personal
                    ? const Color(0xFF388E3C)
                    : const Color(0xFF7B1FA2),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _aiMode == AiMode.personal
                      ? 'Mode personnel actif ✓'
                      : 'Mode gratuit — $_freeQuestionsLeft question(s) restante(s) aujourd\'hui',
                  style: TextStyle(
                    color: _aiMode == AiMode.personal
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF6A1B9A),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _SettingsLabel('Connecter votre compte IA'),

        // Choix du fournisseur
        Row(
          children: [
            Expanded(
              child: _ChoiceChip(
                label: 'ChatGPT',
                selected: _aiProvider == AiProvider.chatgpt,
                onTap: () =>
                    setState(() => _aiProvider = AiProvider.chatgpt),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ChoiceChip(
                label: 'Gemini',
                selected: _aiProvider == AiProvider.gemini,
                onTap: () =>
                    setState(() => _aiProvider = AiProvider.gemini),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Saisie de la clé API
        TextField(
          controller: _apiKeyController,
          obscureText: !_apiKeyVisible,
          decoration: InputDecoration(
            hintText: 'Collez votre clé API ici',
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _apiKeyVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9E9E9E),
              ),
              onPressed: () =>
                  setState(() => _apiKeyVisible = !_apiKeyVisible),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Bouton sauvegarder
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveApiKey,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Enregistrer la clé API'),
          ),
        ),

        // Bouton retirer (visible seulement en mode personnel)
        if (_aiMode == AiMode.personal) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _removeApiKey,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE53935),
                side: const BorderSide(color: Color(0xFFE53935)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retirer la clé API'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez votre clé API')),
      );
      return;
    }
    await _aiService.savePersonalApiKey(_aiProvider, key);
    _apiKeyController.clear();
    FocusScope.of(context).unfocus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clé API enregistrée. Mode personnel activé ✓'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
    await _loadAiStatus();
  }

  Future<void> _removeApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Retirer la clé API ?'),
        content: const Text(
          'Vous reviendrez au mode gratuit (5 questions par jour). '
          'Votre clé sera supprimée de l\'appareil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935)),
            child: const Text('Retirer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _aiService.removePersonalApiKey();
      await _loadAiStatus();
    }
  }

  // ─────────────────────────────────────────────
  // SECTION 3 — SURVEILLANCE
  // ─────────────────────────────────────────────

  Widget _buildMonitoringSection() {
    return _SettingsSection(
      title: '🚗 Surveillance',
      children: [

        _SettingsLabel('Mode de démarrage'),
        Row(
          children: [
            Expanded(
              child: _ChoiceChip(
                label: 'AUTO',
                sublabel: 'Démarre seul',
                selected: _monitoringMode == 'AUTO',
                onTap: () async {
                  setState(() => _monitoringMode = 'AUTO');
                  await _savePref((p) async =>
                      p.setString('monitoring_mode', 'AUTO'));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ChoiceChip(
                label: 'MANUEL',
                sublabel: 'Vous décidez',
                selected: _monitoringMode == 'MANUEL',
                onTap: () async {
                  setState(() => _monitoringMode = 'MANUEL');
                  await _savePref((p) async =>
                      p.setString('monitoring_mode', 'MANUEL'));
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),
        _SettingsLabel('Arrêt automatique si pas de signal OBD'),

        // Délai d'arrêt
        for (final (index, label) in [
          (0, '30 secondes'),
          (1, '60 secondes'),
          (2, '2 minutes'),
        ])
          RadioListTile<int>(
            value: index,
            groupValue: _stopDelayIndex,
            title: Text(label,
                style: const TextStyle(fontSize: 14)),
            dense: true,
            activeColor: const Color(0xFF2196F3),
            onChanged: (v) async {
              setState(() => _stopDelayIndex = v!);
              await _savePref((p) async =>
                  p.setInt('stop_delay_index', v!));
            },
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SECTION 4 — APPLICATION
  // ─────────────────────────────────────────────

  Widget _buildAppSection() {
    return _SettingsSection(
      title: '📱 Application',
      children: [

        _SettingsLinkRow(
          icon: Icons.shield_outlined,
          label: 'Politique de confidentialité',
          onTap: () => launchUrl(
              Uri.parse('https://mecanoabord.fr/confidentialite')),
        ),

        _SettingsLinkRow(
          icon: Icons.help_outline_rounded,
          label: 'Aide & contact',
          onTap: () => launchUrl(
              Uri.parse('https://mecanoabord.fr/aide')),
        ),

        const Divider(height: 24),

        // Version
        const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF9E9E9E), size: 18),
            SizedBox(width: 10),
            Text('Version 1.0.0',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
          ],
        ),

        const SizedBox(height: 16),

        // Réinitialisation
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFE53935)),
            label: const Text('Réinitialiser l\'application',
                style: TextStyle(color: Color(0xFFE53935))),
            onPressed: _showResetDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE53935)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Réinitialiser l\'application ?'),
        content: const Text(
          'Cela supprimera toutes vos données locales : '
          'profil véhicule, documents, carnet d\'entretien et historique des diagnostics.\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935)),
            child: const Text('Réinitialiser',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) Navigator.pushNamedAndRemoveUntil(
          context, '/onboarding', (_) => false);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
// WIDGETS RÉUTILISABLES
// ─────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsLabel extends StatelessWidget {
  final String text;
  const _SettingsLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500)),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2196F3)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            if (sublabel != null)
              Text(sublabel!,
                  style: TextStyle(
                      color: selected
                          ? Colors.white.withOpacity(0.8)
                          : const Color(0xFF9E9E9E),
                      fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w500)),
              if (subtitle != null)
                Text(subtitle!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9E9E9E))),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2196F3),
        ),
      ],
    );
  }
}

class _SettingsLinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsLinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2196F3), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF1A1A2E))),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }
}
