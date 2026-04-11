// Écran de conversation avec l'assistant IA — Mécano à Bord
// Charte MAB, zones tactiles ≥ 48 dp (EAA 2025), interface simple et rassurante.

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/widgets/mab_watermark_background.dart';
import 'package:mecano_a_bord/widgets/mab_demo_banner.dart';
import 'package:mecano_a_bord/services/ai_conversation_service.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/data/chat_message.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// Filigrane écran IA (même opacité que [MabWatermarkBackground] par défaut).
const String _kIaChatWatermarkAsset = 'assets/images/iamecanoabord.png';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.initialQuestion});

  /// Si renseigné (ex. depuis l’écran OBD), envoyé automatiquement après le message d’accueil.
  final String? initialQuestion;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _aiService = AiConversationService.instance;
  final _repository = MabRepository.instance;
  final _scrollCtrl = ScrollController();
  final _inputCtrl = TextEditingController();
  final _messages = <ChatMessage>[];

  bool _isLoading = false;
  bool _hasPersonalAi = false;
  int _remainingQuota = 5;
  bool _isInitialized = false;
  bool _profileIncomplete = false;
  bool _isDemoMode = false;
  bool _isListening = false;
  final SpeechToText _speech = SpeechToText();

  /// Ouverture depuis l’écran OBD avec une question prête à l’emploi : afficher le chat même si le profil n’est pas complet.
  late final bool _openedWithObdQuestion;

  @override
  void initState() {
    super.initState();
    _openedWithObdQuestion = widget.initialQuestion?.trim().isNotEmpty ?? false;
    _initialize();
  }

  Future<void> _initialize() async {
    _isDemoMode = await _repository.isDemoMode();
    _hasPersonalAi = await _aiService.hasPersonalAiConnected();
    _remainingQuota = await _aiService.getRemainingFreeQuota();
    final profileComplete = await _repository.isVehicleProfileComplete();
    _profileIncomplete = !_isDemoMode && !profileComplete;

    final vehicleContext = await _repository.getVehicleContextSummary();
    final welcome = _buildWelcomeMessage(vehicleContext, _hasPersonalAi);

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        text: welcome,
        sender: MessageSender.ai,
        date: DateTime.now(),
      ));
      _isInitialized = true;
    });

    final preset = widget.initialQuestion?.trim();
    if (preset != null && preset.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _inputCtrl.text = preset;
        await _sendQuestion(obdLocationShortcut: true);
      });
    }
  }

  String _buildWelcomeMessage(String? vehicleContext, bool hasPersonalAi) {
    final vehiclePart = vehicleContext != null
        ? 'Je vois que vous avez un $vehicleContext. '
        : '';
    final modePart = hasPersonalAi
        ? 'Votre assistant personnel est connecté : vous pouvez poser autant de questions que vous le souhaitez.'
        : 'Vous pouvez me poser vos questions sur votre véhicule.';
    return 'Bonjour ! Je suis votre assistant Mécano à Bord. '
        '$vehiclePart$modePart\n\n'
        'Comment puis-je vous aider aujourd\'hui ?';
  }

  Future<VehicleContext?> _buildVehicleContext() async {
    final profile = await _repository.getActiveVehicleProfile();
    if (profile == null) return null;
    final lastObd = await _repository.getLastObdDiagnostic();
    return VehicleContext(
      brand: profile.brand,
      model: profile.model,
      year: profile.year,
      mileage: profile.mileage,
      gearboxType: profile.gearboxType,
      milOn: lastObd.milOn,
      dtcCodes: lastObd.dtcs,
    );
  }

  Future<void> _toggleListening() async {
    if ((_profileIncomplete && !_openedWithObdQuestion) || _isLoading) return;
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    final status = await Permission.microphone.request();
    if (!status.isGranted && !status.isLimited) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Autorisez l\'accès au micro pour dicter votre question.',
          ),
          backgroundColor: MabColors.diagnosticRouge,
        ),
      );
      return;
    }
    final available = await _speech.initialize(
      onStatus: (s) {
        if (mounted) setState(() => _isListening = s == 'listening');
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (!available || !mounted) return;
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final text = result.recognizedWords;
        if (text.isNotEmpty) {
          _inputCtrl.text = text;
          _inputCtrl.selection = TextSelection.collapsed(offset: text.length);
          setState(() {});
        }
      },
      localeId: 'fr_FR',
      listenMode: ListenMode.confirmation,
    );
  }

  /// [obdLocationShortcut] : envoi depuis l’écran OBD (question déjà construite) même si le profil n’est pas complet.
  Future<void> _sendQuestion({bool obdLocationShortcut = false}) async {
    final question = _inputCtrl.text.trim();
    if (question.isEmpty || _isLoading) return;
    if (!obdLocationShortcut && _profileIncomplete) return;
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }
    setState(() {
      _messages.add(ChatMessage(
        text: question,
        sender: MessageSender.user,
        date: DateTime.now(),
      ));
      _isLoading = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    try {
      final vehicleContext = await _buildVehicleContext();
      final systemContext = await _repository.getAiSystemContextString();
      final demoScenario = _isDemoMode ? await _repository.getDemoObdScenario() : null;
      final response = await _aiService.ask(
        question,
        vehicleContext: vehicleContext,
        systemContext: systemContext,
        isDemoMode: _isDemoMode,
        demoScenario: demoScenario,
      );

      if (!_hasPersonalAi) {
        _remainingQuota = await _aiService.getRemainingFreeQuota();
      }

      final String replyText;
      if (response is AiSuccess) {
        replyText = response.text;
      } else if (response is AiLimitReached) {
        replyText = response.message;
      } else if (response is AiError) {
        replyText = response.message;
      } else {
        replyText = 'Une erreur est survenue. Réessayez dans un instant.';
      }

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: replyText,
          sender: MessageSender.ai,
          date: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: 'Désolé, je n\'ai pas pu répondre. '
              'Vérifiez votre connexion et réessayez.',
          sender: MessageSender.ai,
          date: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _canSend =>
      (!_profileIncomplete || _openedWithObdQuestion) &&
      !_isLoading &&
      _inputCtrl.text.trim().isNotEmpty &&
      (_isDemoMode || _hasPersonalAi || _remainingQuota > 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      appBar: AppBar(
        title: const Text('Mon assistant auto'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDemoMode) const MabDemoBanner(),
          if (!_isDemoMode && _profileIncomplete && !_openedWithObdQuestion) _buildProfileIncompleteBanner(),
          if (!_isDemoMode && (!_profileIncomplete || _openedWithObdQuestion)) _buildStatusBanner(),
          Expanded(
            child: MabWatermarkBackground(
              assetPath: _kIaChatWatermarkAsset,
              watermarkOpacity: 0.55,
              watermarkWidthFraction: 0.85,
              child: Column(
                children: [
                  Expanded(
                    child: !_isInitialized
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: MabColors.grisDore),
                          )
                        : (_profileIncomplete && !_openedWithObdQuestion)
                            ? _buildProfileIncompleteMessage()
                            : ListView.builder(
                                controller: _scrollCtrl,
                                padding: MabDimensions.paddingEcran,
                                itemCount:
                                    _messages.length + (_isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_isLoading &&
                                      index == _messages.length) {
                                    return _buildTypingIndicator();
                                  }
                                  return _buildFloatingMessage(
                                      _messages[index]);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
          if (_isInitialized) _buildDiagnosticGuideLink(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildDiagnosticGuideLink() {
    return Material(
      color: MabColors.noir,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/diagnostic-guide'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MabDimensions.espacementM,
            vertical: MabDimensions.espacementS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Je ne sais pas quoi taper',
                style: MabTextStyles.label.copyWith(
                  color: MabColors.grisDore,
                  decoration: TextDecoration.underline,
                  decorationColor: MabColors.grisDore,
                ),
              ),
              const SizedBox(width: MabDimensions.espacementXS),
              Icon(
                Icons.arrow_forward_rounded,
                size: MabDimensions.iconeS,
                color: MabColors.grisDore,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIncompleteBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: MabDimensions.espacementM,
          horizontal: MabDimensions.espacementM),
      color: MabColors.diagnosticOrange.withOpacity(0.2),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: MabColors.diagnosticOrange, size: 24),
          const SizedBox(width: MabDimensions.espacementS),
          Expanded(
            child: Text(
              'Complétez votre profil véhicule pour utiliser l\'assistant.',
              style: MabTextStyles.corpsMedium.copyWith(color: MabColors.blanc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileIncompleteMessage() {
    return Center(
      child: Padding(
        padding: MabDimensions.paddingEcran,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined,
                size: MabDimensions.iconeXL, color: MabColors.grisTexte),
            const SizedBox(height: MabDimensions.espacementL),
            Text(
              'Profil véhicule incomplet',
              style: MabTextStyles.titreSection.copyWith(color: MabColors.blanc),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MabDimensions.espacementM),
            Text(
              'Pour que l\'assistant puisse vous répondre en tenant compte de votre véhicule '
              '(marque, modèle, année, carburant, kilométrage, numéro VIN), '
              'complétez votre profil dans la Boîte à gants.',
              style: MabTextStyles.corpsNormal.copyWith(color: MabColors.grisTexte),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MabDimensions.espacementXL),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/glovebox'),
              icon: const Icon(Icons.edit),
              label: const Text('Compléter mon profil véhicule'),
              style: FilledButton.styleFrom(
                backgroundColor: MabColors.rouge,
                foregroundColor: MabColors.blanc,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_hasPersonalAi) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: MabDimensions.espacementS,
            horizontal: MabDimensions.espacementM),
        color: MabColors.diagnosticVert.withOpacity(0.2),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: MabColors.diagnosticVert, size: 20),
            const SizedBox(width: MabDimensions.espacementS),
            Expanded(
              child: Text(
                'Assistant connecté — Questions illimitées',
                style: MabTextStyles.label.copyWith(color: MabColors.diagnosticVert),
              ),
            ),
          ],
        ),
      );
    }

    if (_remainingQuota <= 0) {
      return Container(
        width: double.infinity,
        padding: MabDimensions.paddingCard,
        color: MabColors.diagnosticOrange.withOpacity(0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline,
                    color: MabColors.diagnosticOrange, size: 20),
                const SizedBox(width: MabDimensions.espacementS),
                Expanded(
                  child: Text(
                    'Vous avez utilisé toutes vos questions gratuites pour aujourd\'hui. '
                    'Elles se renouvellent à minuit.',
                    style: MabTextStyles.label
                        .copyWith(color: MabColors.diagnosticOrange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MabDimensions.espacementS),
            Semantics(
              button: true,
              label: 'Aller aux réglages pour connecter un assistant',
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/settings'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Connecter mon assistant dans les réglages →',
                    style: MabTextStyles.label.copyWith(
                      color: MabColors.grisDore,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: MabDimensions.espacementS,
          horizontal: MabDimensions.espacementM),
      color: MabColors.noirMoyen,
      child: Text(
        _remainingQuota == 1
            ? 'Il vous reste 1 question gratuite aujourd\'hui'
            : 'Il vous reste $_remainingQuota questions gratuites aujourd\'hui',
        style: MabTextStyles.label.copyWith(color: MabColors.grisDore),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Texte « flottant » sur le filigrane (sans bulle ni avatar).
  static final List<Shadow> _floatingTextShadows = [
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

  Widget _buildFloatingMessage(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;
    final maxW = MediaQuery.of(context).size.width * 0.88;

    return Padding(
      padding: const EdgeInsets.only(bottom: MabDimensions.espacementL),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Text(
            message.text,
            textAlign: isUser ? TextAlign.right : TextAlign.left,
            style: MabTextStyles.corpsNormal.copyWith(
              color: MabColors.blanc,
              height: 1.55,
              fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
              shadows: _floatingTextShadows,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: MabDimensions.espacementL),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(delay: 0),
            const SizedBox(width: 6),
            _buildDot(delay: 200),
            const SizedBox(width: 6),
            _buildDot(delay: 400),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required int delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      builder: (_, value, __) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: MabColors.grisDore,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    final quotaExhausted = !_hasPersonalAi && _remainingQuota <= 0;
    final disabled =
        (_profileIncomplete && !_openedWithObdQuestion) || quotaExhausted;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: MabDimensions.espacementM,
          vertical: MabDimensions.espacementS),
      decoration: BoxDecoration(
        color: MabColors.noirMoyen,
        border: Border(top: BorderSide(color: MabColors.grisContour)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !disabled,
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendQuestion(),
              onChanged: (_) => setState(() {}),
              style: MabTextStyles.corpsNormal,
              decoration: InputDecoration(
                hintText: (_profileIncomplete && !_openedWithObdQuestion)
                    ? 'Complétez votre profil véhicule'
                    : quotaExhausted
                        ? 'Quota atteint pour aujourd\'hui'
                        : 'Posez votre question...',
                hintStyle: MabTextStyles.corpsSecondaire,
                filled: true,
                fillColor: MabColors.noir,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
                  borderSide: const BorderSide(color: MabColors.grisContour),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: MabDimensions.espacementM,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: MabDimensions.espacementS),
          Semantics(
            button: true,
            label: 'Dicter au micro',
            child: SizedBox(
              width: MabDimensions.zoneTactileMin,
              height: MabDimensions.zoneTactileMin,
              child: IconButton(
                onPressed: disabled ? null : _toggleListening,
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_outlined,
                  color: _isListening ? MabColors.diagnosticRouge : MabColors.blanc,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _isListening ? MabColors.diagnosticRouge.withOpacity(0.3) : MabColors.noirClair,
                  minimumSize: const Size(MabDimensions.zoneTactileMin, MabDimensions.zoneTactileMin),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: MabDimensions.espacementS),
          Semantics(
            button: true,
            label: 'Envoyer la question',
            child: SizedBox(
              width: MabDimensions.zoneTactileMin,
              height: MabDimensions.zoneTactileMin,
              child: IconButton(
                onPressed: _canSend ? _sendQuestion : null,
                icon: const Icon(Icons.send_rounded),
                color: MabColors.blanc,
                style: IconButton.styleFrom(
                  backgroundColor: _canSend ? MabColors.rouge : MabColors.noirClair,
                  minimumSize: const Size(MabDimensions.zoneTactileMin, MabDimensions.zoneTactileMin),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isListening) _speech.stop();
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }
}
