// settings_screen.dart — Mécano à Bord (Flutter iOS + Android)
//
// Écran de réglages — organisé en 4 sections :
//
//  1. COACH VOCAL    — Voix féminine/masculine, alertes vocales on/off
//  2. ASSISTANT IA   — Mode gratuit/personnel, clé API ChatGPT ou Gemini
//  3. SURVEILLANCE   — Mode AUTO/MANUEL, délai d'arrêt automatique
//  4. APPLICATION    — Mentions légales, confidentialité, aide, version, réinitialisation

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/services/ai_conversation_service.dart';
import 'package:mecano_a_bord/screens/home_screen.dart';
import 'package:mecano_a_bord/screens/onboarding_screen.dart';
import 'package:mecano_a_bord/widgets/mab_watermark_background.dart';
import 'package:mecano_a_bord/widgets/mab_demo_banner.dart';
import 'package:mecano_a_bord/widgets/surveillance_settings_body.dart';
import 'package:mecano_a_bord/services/tts_service.dart';
import 'package:mecano_a_bord/services/app_reset_service.dart';

class SettingsScreen extends StatefulWidget {
  /// Si `'surveillance'`, défile jusqu’à la section Surveillance après l’ouverture.
  /// (Les mentions légales s’ouvrent via la route `/legal-mentions`.)
  final String? initialSection;

  const SettingsScreen({super.key, this.initialSection});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

String _aiProviderLabel(AiProvider p) {
  return switch (p) {
    AiProvider.claude => 'Claude',
    AiProvider.chatgpt => 'ChatGPT',
    AiProvider.gemini => 'Gemini',
    AiProvider.mistral => 'Mistral',
    AiProvider.qwen => 'Qwen',
    AiProvider.perplexity => 'Perplexity',
    AiProvider.grok => 'Grok',
    AiProvider.copilot => 'Copilot',
    AiProvider.meta_ai => 'Meta AI',
    AiProvider.deepseek => 'DeepSeek',
  };
}

/// Libellé affiché à côté du logo (section « Connecter votre compte IA »).
String _aiProviderDisplayLabel(AiProvider p) {
  return switch (p) {
    AiProvider.claude => 'Claude (Anthropic)',
    AiProvider.chatgpt => 'ChatGPT (OpenAI)',
    AiProvider.gemini => 'Gemini (Google)',
    AiProvider.mistral => 'Mistral',
    AiProvider.qwen => 'Qwen',
    AiProvider.perplexity => 'Perplexity',
    AiProvider.grok => 'Grok (xAI)',
    AiProvider.copilot => 'Copilot (Microsoft)',
    AiProvider.meta_ai => 'Meta AI',
    AiProvider.deepseek => 'DeepSeek',
  };
}

/// Couleur du cercle de secours (initiale) si le PNG est absent.
Color _aiProviderFallbackColor(AiProvider p) {
  return switch (p) {
    AiProvider.claude => const Color(0xFFCC785C),
    AiProvider.chatgpt => const Color(0xFF10A37F),
    AiProvider.gemini => const Color(0xFF4285F4),
    AiProvider.mistral => const Color(0xFFFF7000),
    AiProvider.qwen => const Color(0xFF6B4DE6),
    AiProvider.perplexity => const Color(0xFF20808D),
    AiProvider.grok => const Color(0xFF1DA1F2),
    AiProvider.copilot => const Color(0xFF0078D4),
    AiProvider.meta_ai => const Color(0xFF0668E1),
    AiProvider.deepseek => const Color(0xFF4D6BFE),
  };
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AiConversationService _aiService = AiConversationService.instance;
  final MabRepository _repository = MabRepository.instance;
  final GlobalKey _monitoringSectionKey = GlobalKey();

  bool _isDemoMode = false;

  // ─── Voix (mab_voice_gender : female / male) ───
  String _mabVoiceGender = TtsService.genderFemale;
  bool _voiceAlertsEnabled = true;

  // ─── IA ───
  AiMode _aiMode = AiMode.free;
  int _freeQuestionsLeft = 5;
  AiProvider _aiProvider = AiProvider.chatgpt;
  /// Un champ clé API par fournisseur (secure storage : api_key_*).
  late final Map<AiProvider, TextEditingController> _apiKeyControllers;
  final Map<AiProvider, bool> _apiKeyVisible = {};
  final Map<AiProvider, bool> _providerHasKey = {};

  /// Panneau clé API ouvert (accordéon : un seul à la fois, `null` = tout replié).
  AiProvider? _expandedAiProvider;

  List<VehicleProfile> _vehicles = [];
  int? _activeVehicleId;

  /// Libellé Réglages : lu depuis `pubspec.yaml` (version + numéro de build Android/iOS).
  String _appVersionLabel = 'Version …';

  @override
  void initState() {
    super.initState();
    _apiKeyControllers = {
      for (final p in AiProvider.values) p: TextEditingController(),
    };
    for (final p in AiProvider.values) {
      _apiKeyVisible[p] = false;
      _providerHasKey[p] = false;
    }
    _loadSettings();
    _loadAiStatus();
    _bootstrap();
    if (widget.initialSection == 'surveillance') {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToSectionKey(_monitoringSectionKey));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAppVersionLabel());
  }

  Future<void> _loadAppVersionLabel() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersionLabel =
            'Version ${info.version} (build ${info.buildNumber})';
      });
    } catch (_) {
      if (mounted) setState(() => _appVersionLabel = 'Version —');
    }
  }

  void _scrollToSectionKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null && mounted) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.15,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _bootstrap() async {
    final demo = await _repository.isDemoMode();
    if (!mounted) return;
    setState(() => _isDemoMode = demo);
    if (!demo) await _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final list = await _repository.getAllVehicleProfiles();
    final aid = await _repository.getActiveVehicleId();
    if (mounted) {
      setState(() {
        _vehicles = list;
        _activeVehicleId = aid;
      });
    }
  }

  bool _isVehicleRowActive(VehicleProfile p) {
    final pid = int.tryParse(p.id);
    if (pid == null) return false;
    if (_activeVehicleId != null) return _activeVehicleId == pid;
    if (_vehicles.length == 1) return true;
    return _vehicles.isNotEmpty &&
        int.tryParse(_vehicles.first.id) == pid;
  }

  Future<void> _confirmDeleteVehicle(VehicleProfile p) async {
    final pid = int.tryParse(p.id);
    if (pid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MabDimensions.rayonGrand),
        ),
        title: const Text('Supprimer ce véhicule ?'),
        content: Text(
          'Le profil « ${p.brand} ${p.model} », ses documents, '
          'son carnet d\'entretien et ses données OBD associées seront supprimés. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MabColors.diagnosticRouge,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _repository.deleteVehicleProfile(pid);
      if (mounted) await _loadVehicles();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mabVoiceGender = prefs.getString(TtsService.keyMabVoiceGender) ??
          (prefs.getString('voice_gender') == 'MASCULINE'
              ? TtsService.genderMale
              : TtsService.genderFemale);
      _voiceAlertsEnabled = prefs.getBool('voice_alerts_enabled') ?? true;
    });
  }

  Future<void> _loadAiStatus() async {
    final mode = await _aiService.getCurrentMode();
    final remaining = await _aiService.getRemainingFreeQuota();
    final savedProvider = await _aiService.getSavedSelectedProvider();
    final keyStates = <AiProvider, bool>{};
    for (final p in AiProvider.values) {
      keyStates[p] = await _aiService.hasApiKeyForProvider(p);
    }
    if (!mounted) return;
    setState(() {
      _aiMode = mode;
      _freeQuestionsLeft = remaining;
      _aiProvider = savedProvider;
      _providerHasKey
        ..clear()
        ..addAll(keyStates);
    });
  }

  Future<void> _savePref(
      Future<void> Function(SharedPreferences) action) async {
    final prefs = await SharedPreferences.getInstance();
    await action(prefs);
  }

  // ─────────────────────────────────────────────
  // INTERFACE
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      appBar: AppBar(
        backgroundColor: MabColors.noir,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: MabColors.blanc),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Réglages', style: MabTextStyles.titreSection),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDemoMode) const MabDemoBanner(),
          Expanded(
            child: MabWatermarkBackground(
              child: ListView(
                padding: MabDimensions.paddingEcran,
                children: [
          if (!_isDemoMode) ...[
            _buildMesVehiculesSection(),
            const SizedBox(height: 20),
          ],
          _buildDemoSection(),
          const SizedBox(height: 20),
          _buildVoiceSection(),
          const SizedBox(height: 20),
          _buildAiSection(),
          const SizedBox(height: 20),
          KeyedSubtree(
            key: _monitoringSectionKey,
            child: const SurveillanceSettingsBody(),
          ),
          const SizedBox(height: 20),
          _buildAppSection(),
          const SizedBox(height: 32),
        ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMesVehiculesSection() {
    return _SettingsSection(
      title: '🚘 Mes véhicules',
      children: [
        if (_vehicles.isEmpty)
          Text(
            'Aucun véhicule enregistré. Créez un profil depuis la Boîte à gants.',
            style: MabTextStyles.corpsSecondaire,
          )
        else
          ..._vehicles.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: MabDimensions.espacementM),
                child: _buildVehicleSettingsRow(p),
              )),
        if (_vehicles.length == 1) ...[
          const SizedBox(height: MabDimensions.espacementS),
          SizedBox(
            width: double.infinity,
            height: MabDimensions.zoneTactileMin,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: MabColors.rouge, size: MabDimensions.iconeM),
              label: const Text('+ Ajouter un véhicule'),
              onPressed: () async {
                await Navigator.pushNamed(
                  context,
                  '/glovebox',
                  arguments: 'NEW_PROFILE',
                );
                if (mounted) await _loadVehicles();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: MabColors.rouge,
                side: const BorderSide(color: MabColors.rouge),
                minimumSize:
                    const Size(double.infinity, MabDimensions.zoneTactileMin),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVehicleSettingsRow(VehicleProfile p) {
    final active = _isVehicleRowActive(p);
    final pid = int.tryParse(p.id);
    return Container(
      padding: MabDimensions.paddingCard,
      decoration: BoxDecoration(
        color: MabColors.noirClair,
        borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
        border: Border.all(
          color: active ? MabColors.rouge : MabColors.grisContour,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${p.brand} ${p.model}',
                  style: MabTextStyles.corpsMedium,
                ),
              ),
              if (active)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MabColors.rouge.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(MabDimensions.rayonPetit),
                  ),
                  child: Text(
                    'Actif',
                    style: MabTextStyles.label.copyWith(color: MabColors.rouge),
                  ),
                ),
            ],
          ),
          const SizedBox(height: MabDimensions.espacementM),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: MabDimensions.zoneTactileMin,
                  child: OutlinedButton(
                    onPressed: pid == null
                        ? null
                        : () async {
                            await Navigator.pushNamed(
                              context,
                              '/glovebox-profile',
                              arguments: pid,
                            );
                            if (mounted) await _loadVehicles();
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MabColors.blanc,
                      side: const BorderSide(color: MabColors.grisContour),
                      minimumSize: const Size(0, MabDimensions.zoneTactileMin),
                    ),
                    child: const Text('Modifier'),
                  ),
                ),
              ),
              if (!active && pid != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: MabDimensions.zoneTactileMin,
                    child: OutlinedButton(
                      onPressed: () => _confirmDeleteVehicle(p),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MabColors.diagnosticRouge,
                        side: const BorderSide(color: MabColors.diagnosticRouge),
                        minimumSize:
                            const Size(0, MabDimensions.zoneTactileMin),
                      ),
                      child: const Text('Supprimer'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoSection() {
    return Container(
      padding: MabDimensions.paddingCard,
      decoration: BoxDecoration(
        color: MabColors.noirMoyen,
        borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
        border: Border.all(color: MabColors.grisContour),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, color: MabColors.rouge, size: MabDimensions.iconeM),
              const SizedBox(width: MabDimensions.espacementS),
              Text('Mode démo', style: MabTextStyles.titreCard),
            ],
          ),
          const SizedBox(height: MabDimensions.espacementS),
          Text(
            'Tester l\'application sans voiture, sans dongle OBD et sans clé API.',
            style: MabTextStyles.corpsSecondaire,
          ),
          const SizedBox(height: MabDimensions.espacementM),
          if (_isDemoMode) ...[
            Container(
              padding: const EdgeInsets.all(MabDimensions.espacementS),
              decoration: BoxDecoration(
                color: MabColors.diagnosticRouge.withOpacity(0.2),
                borderRadius: BorderRadius.circular(MabDimensions.rayonPetit),
              ),
              child: Text(
                'Mode démo actif — données simulées (Renault Clio 4, scénarios OBD).',
                style: MabTextStyles.label.copyWith(color: MabColors.blanc),
              ),
            ),
            const SizedBox(height: MabDimensions.espacementS),
            OutlinedButton.icon(
              onPressed: () async {
                await _repository.setDemoMode(false);
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.close),
              label: const Text('Quitter le mode démo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: MabColors.rouge,
                side: const BorderSide(color: MabColors.rouge),
              ),
            ),
          ] else
            FilledButton.icon(
              onPressed: () async {
                await _repository.setDemoMode(true);
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Activer le mode démo'),
              style: FilledButton.styleFrom(
                backgroundColor: MabColors.rouge,
                foregroundColor: MabColors.blanc,
              ),
            ),
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
        _SettingsLabel('Voix'),
        RadioListTile<String>(
          value: TtsService.genderFemale,
          groupValue: _mabVoiceGender,
          onChanged: (v) async {
            if (v == null) return;
            setState(() => _mabVoiceGender = v);
            await _savePref(
                (p) async => p.setString(TtsService.keyMabVoiceGender, v));
            await TtsService.instance.switchVoice(v);
          },
          title: Text(
            'Voix féminine 👩',
            style: MabTextStyles.corpsNormal,
          ),
          activeColor: MabColors.rouge,
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          value: TtsService.genderMale,
          groupValue: _mabVoiceGender,
          onChanged: (v) async {
            if (v == null) return;
            setState(() => _mabVoiceGender = v);
            await _savePref(
                (p) async => p.setString(TtsService.keyMabVoiceGender, v));
            try {
              await TtsService.instance.switchVoice(v);
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Voix masculine indisponible : $e')),
              );
            }
          },
          title: Text(
            'Voix masculine 👨',
            style: MabTextStyles.corpsNormal,
          ),
          activeColor: MabColors.rouge,
          contentPadding: EdgeInsets.zero,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Text(
            '⚠️ La voix masculine nécessite une connexion internet',
            style: MabTextStyles.label.copyWith(
              color: MabColors.diagnosticOrange,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SettingsSwitchRow(
          label: 'Alertes vocales',
          subtitle: 'Annonces pendant la surveillance',
          value: _voiceAlertsEnabled,
          onChanged: (v) async {
            setState(() => _voiceAlertsEnabled = v);
            await _savePref((p) async => p.setBool('voice_alerts_enabled', v));
          },
        ),
        const SizedBox(height: MabDimensions.espacementM),
        SizedBox(
          width: double.infinity,
          height: MabDimensions.boutonHauteur,
          child: OutlinedButton.icon(
            onPressed: () async {
              await TtsService.instance.speakChosenVoiceTest();
            },
            icon: const Icon(Icons.volume_up_outlined, size: MabDimensions.iconeM),
            label: const Text('Tester la voix choisie'),
            style: OutlinedButton.styleFrom(
              foregroundColor: MabColors.rouge,
              side: const BorderSide(color: MabColors.rouge),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SECTION 2 — ASSISTANT IA
  // ─────────────────────────────────────────────

  Widget _buildAiSection() {
    final aiModeBannerRow = Row(
      children: [
        Icon(
          _aiMode == AiMode.personal
              ? Icons.verified_outlined
              : Icons.info_outline,
          color: _aiMode == AiMode.personal
              ? MabColors.diagnosticVert
              : MabColors.grisDore,
          size: MabDimensions.iconeM,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _aiMode == AiMode.personal
                ? 'Mode personnel actif ✓'
                : 'Mode gratuit — $_freeQuestionsLeft question(s) restante(s) aujourd\'hui',
            style: MabTextStyles.label.copyWith(
              color: _aiMode == AiMode.personal
                  ? MabColors.diagnosticVert
                  : MabColors.grisTexte,
            ),
          ),
        ),
      ],
    );

    return _SettingsSection(
      title: '🤖 Assistant IA',
      children: [
        Container(
          padding: MabDimensions.paddingCard,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _aiMode == AiMode.personal
                ? MabColors.diagnosticVertClair.withOpacity(0.3)
                : MabColors.noirClair,
            borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
            border: Border.all(
              color: _aiMode == AiMode.personal
                  ? MabColors.diagnosticVert
                  : MabColors.grisContour,
            ),
          ),
          child: _aiMode == AiMode.free
              ? Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/iamecanoabord.png',
                        fit: BoxFit.cover,
                        opacity: const AlwaysStoppedAnimation(0.55),
                      ),
                    ),
                    aiModeBannerRow,
                  ],
                )
              : aiModeBannerRow,
        ),
        const SizedBox(height: 16),
        _SettingsLabel('Connecter votre compte IA'),
        _buildAiProviderLogoGrid(),
      ],
    );
  }

  Widget _buildAiProviderLogoGrid() {
    const logoSize = 32.0;
    const logoRadius = 8.0;
    const accordionDuration = Duration(milliseconds: 280);
    const accordionCurve = Curves.easeInOut;
    final providers = AiProvider.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: providers.map((provider) {
        final expanded = _expandedAiProvider == provider;
        final isActiveForApi = _aiProvider == provider;
        final shortLabel = _aiProviderLabel(provider);
        final displayLabel = _aiProviderDisplayLabel(provider);
        final logoPath = 'assets/images/ia/${provider.name}.png';
        final letter = shortLabel.isNotEmpty
            ? shortLabel[0].toUpperCase()
            : '?';
        final fallbackColor = _aiProviderFallbackColor(provider);
        final hasKey = _providerHasKey[provider] ?? false;
        final keyVisible = _apiKeyVisible[provider] ?? false;
        final ctrl = _apiKeyControllers[provider]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: MabDimensions.espacementM),
          child: Semantics(
            label: displayLabel,
            selected: expanded,
            expanded: expanded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (_expandedAiProvider == provider) {
                        setState(() => _expandedAiProvider = null);
                      } else {
                        setState(() {
                          _expandedAiProvider = provider;
                          _aiProvider = provider;
                        });
                        await _aiService.saveSelectedProvider(provider);
                        if (mounted) await _loadAiStatus();
                      }
                    },
                    borderRadius:
                        BorderRadius.circular(MabDimensions.rayonMoyen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: expanded
                            ? MabColors.rouge.withValues(alpha: 0.12)
                            : MabColors.noirClair,
                        borderRadius:
                            BorderRadius.circular(MabDimensions.rayonMoyen),
                        border: Border.all(
                          color: expanded
                              ? MabColors.rouge
                              : (isActiveForApi
                                  ? MabColors.rouge.withValues(alpha: 0.55)
                                  : MabColors.grisContour),
                          width: expanded ? 2 : (isActiveForApi ? 1.5 : 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: logoSize,
                            height: logoSize,
                            child: Image.asset(
                              logoPath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return CircleAvatar(
                                  radius: logoSize / 2,
                                  backgroundColor: fallbackColor,
                                  child: Text(
                                    letter,
                                    style: MabTextStyles.titreCard.copyWith(
                                      color: MabColors.blanc,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              },
                              frameBuilder: (context, child, frame,
                                  wasSynchronouslyLoaded) {
                                if (frame == null && !wasSynchronouslyLoaded) {
                                  return const SizedBox(
                                    width: logoSize,
                                    height: logoSize,
                                  );
                                }
                                return ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(logoRadius),
                                  child: SizedBox(
                                    width: logoSize,
                                    height: logoSize,
                                    child: child,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              displayLabel,
                              style: MabTextStyles.corpsNormal.copyWith(
                                color: expanded
                                    ? MabColors.rougeClair
                                    : (isActiveForApi
                                        ? MabColors.grisDore
                                        : MabColors.blanc),
                                fontWeight: (expanded || isActiveForApi)
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (expanded)
                            Icon(
                              Icons.expand_less_rounded,
                              color: MabColors.grisTexte,
                              size: MabDimensions.iconeM,
                            )
                          else
                            Icon(
                              Icons.expand_more_rounded,
                              color: MabColors.grisTexte,
                              size: MabDimensions.iconeM,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: accordionDuration,
                  curve: accordionCurve,
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.hardEdge,
                  child: expanded
                      ? Column(
                          key: ValueKey<AiProvider>(provider),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: MabDimensions.espacementS),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: hasKey
                                        ? Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                color:
                                                    MabColors.diagnosticVert,
                                                size: 22,
                                                semanticLabel: 'Clé enregistrée',
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  'Clé enregistrée pour ce service',
                                                  style: MabTextStyles.label
                                                      .copyWith(
                                                    color: MabColors
                                                        .diagnosticVert,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  Icon(
                                    Icons.radio_button_checked,
                                    color: MabColors.rouge,
                                    size: MabDimensions.iconeM,
                                    semanticLabel: 'Fournisseur sélectionné',
                                  ),
                                ],
                              ),
                            ),
                            TextField(
                              controller: ctrl,
                              obscureText: !keyVisible,
                              style: MabTextStyles.corpsNormal,
                              decoration: InputDecoration(
                                hintText: hasKey
                                    ? 'Nouvelle clé pour remplacer l’existante'
                                    : 'Collez votre clé API',
                                hintStyle: MabTextStyles.corpsSecondaire,
                                filled: true,
                                fillColor: MabColors.noirClair,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      MabDimensions.rayonMoyen),
                                  borderSide: const BorderSide(
                                      color: MabColors.grisContour),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    keyVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: MabColors.grisTexte,
                                    size: MabDimensions.iconeM,
                                  ),
                                  onPressed: () => setState(() {
                                    _apiKeyVisible[provider] = !keyVisible;
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(height: MabDimensions.espacementS),
                            SizedBox(
                              width: double.infinity,
                              height: MabDimensions.zoneTactileMin,
                              child: ElevatedButton(
                                onPressed: () => _saveApiKeyFor(provider),
                                child: const Text('Enregistrer'),
                              ),
                            ),
                            if (hasKey) ...[
                              const SizedBox(height: MabDimensions.espacementS),
                              SizedBox(
                                width: double.infinity,
                                height: MabDimensions.zoneTactileMin,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _confirmRemoveApiKeyFor(provider),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: MabColors.diagnosticRouge,
                                    side: const BorderSide(
                                        color: MabColors.diagnosticRouge),
                                  ),
                                  child: const Text('Retirer la clé'),
                                ),
                              ),
                            ],
                          ],
                        )
                      : const SizedBox(
                          width: double.infinity,
                        ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _saveApiKeyFor(AiProvider provider) async {
    final key = _apiKeyControllers[provider]!.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez votre clé API')),
      );
      return;
    }
    await _aiService.savePersonalApiKey(provider, key);
    if (!mounted) return;
    _apiKeyControllers[provider]!.clear();
    FocusScope.of(context).unfocus();
    final personalForSelection = _aiProvider == provider;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            personalForSelection
                ? 'Clé ${_aiProviderLabel(provider)} enregistrée. Mode personnel activé ✓'
                : 'Clé ${_aiProviderLabel(provider)} enregistrée. '
                    'Sélectionnez ce fournisseur ci-dessus pour l’utiliser.',
          ),
          backgroundColor: MabColors.diagnosticVert,
        ),
    );
    await _loadAiStatus();
  }

  Future<void> _confirmRemoveApiKeyFor(AiProvider provider) async {
    final label = _aiProviderDisplayLabel(provider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MabDimensions.rayonGrand)),
        title: const Text('Retirer la clé API ?'),
        content: Text(
          'La clé pour $label sera supprimée de cet appareil. '
          'Si c’était le fournisseur sélectionné et votre dernière clé, '
          'vous repasserez en mode gratuit (5 questions par jour).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: MabColors.diagnosticRouge),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _aiService.removeApiKeyForProvider(provider);
      _apiKeyControllers[provider]!.clear();
      if (mounted) await _loadAiStatus();
    }
  }

  // ─────────────────────────────────────────────
  // SECTION 4 — APPLICATION
  // ─────────────────────────────────────────────

  Widget _buildAppSection() {
    return _SettingsSection(
      title: '📱 Application',
      children: [
        _SettingsLinkRow(
          icon: Icons.gavel_rounded,
          label: 'Mentions légales & CGU',
          onTap: () => Navigator.pushNamed(context, '/legal-mentions'),
        ),
        _SettingsLinkRow(
          icon: Icons.shield_outlined,
          label: 'Politique de confidentialité',
          onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
        ),
        _SettingsLinkRow(
          icon: Icons.help_outline_rounded,
          label: 'Aide & contact',
          onTap: () => Navigator.pushNamed(context, '/help-contact'),
        ),
        const Divider(height: 24),
        Row(
          children: [
            Icon(Icons.info_outline, color: MabColors.grisTexte,
                size: MabDimensions.iconeS),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_appVersionLabel, style: MabTextStyles.label),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: MabDimensions.boutonHauteur,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline_rounded,
                color: MabColors.diagnosticRouge),
            label: Text(
              'Réinitialiser l\'application',
              style: MabTextStyles.boutonSecondaire.copyWith(
                color: MabColors.diagnosticRouge,
              ),
            ),
            onPressed: _showResetDialog,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, MabDimensions.boutonHauteur),
              side: const BorderSide(color: MabColors.diagnosticRouge),
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
            borderRadius: BorderRadius.circular(MabDimensions.rayonGrand)),
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
                backgroundColor: MabColors.diagnosticRouge),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: MabColors.noirMoyen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MabDimensions.rayonGrand),
          ),
          content: Row(
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(MabColors.rouge),
                ),
              ),
              const SizedBox(width: MabDimensions.espacementM),
              Expanded(
                child: Text(
                  'Réinitialisation en cours…',
                  style: MabTextStyles.corpsNormal.copyWith(color: MabColors.blanc),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await AppResetService.performFullReset();
    } catch (_) {
      if (mounted) {
        navigator.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: MabColors.noirMoyen,
            content: Text(
              'La réinitialisation a échoué. Réessayez.',
              style: MabTextStyles.corpsNormal.copyWith(color: MabColors.blanc),
            ),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    navigator.pop();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
      (_) => false,
    );
  }

  @override
  void dispose() {
    for (final c in _apiKeyControllers.values) {
      c.dispose();
    }
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
      padding: MabDimensions.paddingCard,
      decoration: BoxDecoration(
        color: MabColors.noirMoyen,
        borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
        border: Border.all(color: MabColors.grisContour),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: MabTextStyles.titreCard),
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
      child: Text(text, style: MabTextStyles.label),
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
              Text(label, style: MabTextStyles.corpsMedium),
              if (subtitle != null)
                Text(subtitle!, style: MabTextStyles.corpsSecondaire),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
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
            Icon(icon, color: MabColors.rouge, size: MabDimensions.iconeM),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: MabTextStyles.corpsMedium),
            ),
            const Icon(Icons.chevron_right, color: MabColors.grisTexte),
          ],
        ),
      ),
    );
  }
}
