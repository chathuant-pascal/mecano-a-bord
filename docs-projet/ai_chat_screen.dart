import 'package:flutter/material.dart';
import '../../ai/ai_conversation_service.dart';
import '../../data/mab_repository.dart';
import '../../data/model/chat_message.dart';

/// MÉCANO À BORD — ai_chat_screen.dart
/// ─────────────────────────────────────────────────────────────
/// Écran de conversation avec l'assistant IA (iOS + Android).
///
/// Même logique que la version Android :
///   - Mode gratuit  : 5 questions/jour, réponses locales
///   - Mode personnel: clé API connectée, questions illimitées
///   - Contexte véhicule transmis automatiquement à l'IA
///   - Interface de chat avec bulles (utilisateur à droite, IA à gauche)
/// ─────────────────────────────────────────────────────────────

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {

  final _aiService   = AiConversationService.instance;
  final _repository  = MabRepository.instance;
  final _scrollCtrl  = ScrollController();
  final _inputCtrl   = TextEditingController();
  final _messages    = <ChatMessage>[];

  bool _isLoading        = false;   // L'IA est en train de répondre
  bool _hasPersonalAi    = false;   // L'utilisateur a connecté son propre compte IA
  int  _remainingQuota   = 5;       // Questions gratuites restantes
  bool _isInitialized    = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // ── Chargement de l'état initial ─────────────────────────
  Future<void> _initialize() async {
    _hasPersonalAi  = await _aiService.hasPersonalAiConnected();
    _remainingQuota = await _aiService.getRemainingFreeQuota();
    final vehicleContext = await _repository.getVehicleContextSummary();

    // Message de bienvenue
    final welcome = _buildWelcomeMessage(vehicleContext, _hasPersonalAi);

    setState(() {
      _messages.add(ChatMessage(
        text:   welcome,
        sender: MessageSender.ai,
        date:   DateTime.now(),
      ));
      _isInitialized = true;
    });
  }

  // ── Message de bienvenue ──────────────────────────────────
  String _buildWelcomeMessage(String? vehicleContext, bool hasPersonalAi) {
    final vehiclePart = vehicleContext != null
        ? 'Je vois que vous avez un $vehicleContext. '
        : '';

    final modePart = hasPersonalAi
        ? 'Votre IA personnelle est connectée, vous pouvez poser autant de questions que vous voulez.'
        : 'Vous êtes en mode gratuit.';

    return 'Bonjour ! Je suis votre assistant Mécano à Bord. '
           '$vehiclePart$modePart\n\n'
           'Que puis-je faire pour vous aujourd\'hui ?';
  }

  // ── Envoi d'une question ──────────────────────────────────
  Future<void> _sendQuestion() async {
    final question = _inputCtrl.text.trim();
    if (question.isEmpty || _isLoading) return;

    // Ajout du message utilisateur
    setState(() {
      _messages.add(ChatMessage(
        text:   question,
        sender: MessageSender.user,
        date:   DateTime.now(),
      ));
      _isLoading = true;
      _inputCtrl.clear();
    });

    _scrollToBottom();

    try {
      final vehicleContext = await _repository.getVehicleContextSummary();
      final response = await _aiService.ask(
        question:       question,
        vehicleContext: vehicleContext,
        history:        _messages.length > 10
                            ? _messages.sublist(_messages.length - 10)
                            : _messages,
      );

      // Mise à jour du quota si mode gratuit
      if (!_hasPersonalAi) {
        _remainingQuota = await _aiService.getRemainingFreeQuota();
      }

      setState(() {
        _messages.add(ChatMessage(
          text:   response.answer,
          sender: MessageSender.ai,
          date:   DateTime.now(),
        ));
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Désolé, je n\'ai pas pu obtenir de réponse. '
                'Vérifiez votre connexion et réessayez.',
          sender: MessageSender.ai,
          date:   DateTime.now(),
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
      !_isLoading &&
      _inputCtrl.text.trim().isNotEmpty &&
      (_hasPersonalAi || _remainingQuota > 0);

  // ── Interface ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon assistant auto'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [

          // ── Bandeau de statut ──────────────────────────
          _buildStatusBanner(),

          // ── Liste des messages ─────────────────────────
          Expanded(
            child: !_isInitialized
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Dernière position = indicateur "l'IA écrit..."
                      if (_isLoading && index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // ── Zone de saisie ─────────────────────────────
          _buildInputArea(),
        ],
      ),
    );
  }

  // ── Bandeau de statut ─────────────────────────────────────
  Widget _buildStatusBanner() {
    // Mode IA personnelle connectée
    if (_hasPersonalAi) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.green.shade50,
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            SizedBox(width: 8),
            Text(
              'IA personnelle connectée — Questions illimitées',
              style: TextStyle(color: Colors.green, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Quota épuisé
    if (_remainingQuota <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: Colors.orange.shade50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous avez utilisé toutes vos questions gratuites aujourd\'hui.',
                    style: TextStyle(color: Colors.deepOrange, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                // Navigator.pushNamed(context, '/settings');
              },
              child: const Text(
                'Connecter mon IA personnelle dans les réglages →',
                style: TextStyle(
                  color: Color(0xFF1A73E8),
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Quota restant
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: const Color(0xFFE8F0FE),
      child: Text(
        _remainingQuota == 1
            ? 'Il vous reste 1 question gratuite aujourd\'hui'
            : 'Il vous reste $_remainingQuota questions gratuites aujourd\'hui',
        style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── Bulle de message ──────────────────────────────────────
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          // Avatar IA (à gauche)
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1A73E8),
              child: const Icon(Icons.car_repair, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],

          // Bulle de message
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF1A73E8)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // Espace à droite pour les messages utilisateur
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Indicateur "l'IA écrit..." ────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF1A73E8),
            child: const Icon(Icons.car_repair, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(18),
                topRight:    Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft:  Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(delay: 0),
                const SizedBox(width: 4),
                _buildDot(delay: 200),
                const SizedBox(width: 4),
                _buildDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Petit point animé pour l'indicateur de frappe
  Widget _buildDot({required int delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      builder: (_, value, __) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  // ── Zone de saisie ────────────────────────────────────────
  Widget _buildInputArea() {
    final quotaExhausted = !_hasPersonalAi && _remainingQuota <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !quotaExhausted,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendQuestion(),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: quotaExhausted
                    ? 'Quota atteint pour aujourd\'hui'
                    : 'Posez votre question...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _canSend
                  ? const Color(0xFF1A73E8)
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _canSend ? _sendQuestion : null,
              icon: const Icon(Icons.send_rounded),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }
}
