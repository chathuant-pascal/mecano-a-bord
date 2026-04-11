// help_contact_screen.dart — Mécano à Bord
// Écran Aide & Contact : onglet Aide (guide, formation, vidéos) et onglet Contact (email, site, formulaire).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mecano_a_bord/formation_url.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/widgets/mab_watermark_background.dart';

// Liens et contact (modifiables)
const String _lienYoutube = 'https://youtube.com/mecanoabord';
const String _emailContact = 'contact@mecanoabord.fr';
const String _lienSite = 'https://mecanoabord.systeme.io';

class HelpContactScreen extends StatefulWidget {
  const HelpContactScreen({super.key});

  @override
  State<HelpContactScreen> createState() => _HelpContactScreenState();
}

class _HelpContactScreenState extends State<HelpContactScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sujetCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _sujetCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    if (url.startsWith('LIEN_') || url.startsWith('EMAIL_')) return;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      debugPrint('help_contact _openUrl: $e\n$st');
    }
  }

  Future<void> _openEmail({String? subject, String? body}) async {
    if (_emailContact.startsWith('EMAIL_')) return;
    final uri = Uri(
      scheme: 'mailto',
      path: _emailContact,
      queryParameters: {
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        if (body != null && body.isNotEmpty) 'body': body,
      },
    );
    try {
      await launchUrl(uri);
    } catch (e, st) {
      debugPrint('help_contact _openEmail: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      appBar: AppBar(
        backgroundColor: MabColors.noir,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: MabColors.blanc),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Aide & contact', style: MabTextStyles.titreSection),
        bottom: TabBar(
          controller: _tabController,
          labelColor: MabColors.rouge,
          unselectedLabelColor: MabColors.grisTexte,
          indicatorColor: MabColors.rouge,
          tabs: const [
            Tab(text: 'Aide'),
            Tab(text: 'Contact'),
          ],
        ),
      ),
      body: MabWatermarkBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _AideTab(openUrl: _openUrl),
            _ContactTab(
              emailContact: _emailContact,
              lienSite: _lienSite,
              openEmail: _openEmail,
              openUrl: _openUrl,
              nomCtrl: _nomCtrl,
              emailCtrl: _emailCtrl,
              sujetCtrl: _sujetCtrl,
              messageCtrl: _messageCtrl,
            ),
          ],
        ),
      ),
    );
  }
}

class _AideTab extends StatelessWidget {
  final Future<void> Function(String url) openUrl;

  const _AideTab({required this.openUrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: MabDimensions.paddingEcran,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Guide d\'utilisation', style: MabTextStyles.titreCard),
          const SizedBox(height: MabDimensions.espacementS),
          _Step(
            '1',
            'Créez votre profil véhicule dans Boîte à gants → Profil véhicule en renseignant marque, modèle, '
            'motorisation (ex: 1.5 dCi 90ch), type de boîte, année, kilométrage et numéro VIN.',
          ),
          _Step('2', 'Branchez votre dongle OBD sur la prise OBD de votre véhicule sous le tableau de bord côté conducteur.'),
          _Step('3', 'Appairez le dongle dans les réglages Bluetooth de votre téléphone.'),
          _Step('4', 'Ouvrez OBD Diagnostic dans l\'app et sélectionnez votre dongle.'),
          _Step('5', 'Au premier branchement l\'app détecte automatiquement le protocole de votre véhicule, cela prend 5 à 10 minutes une seule fois.'),
          _Step(
            '6',
            'Consultez le résultat vert, orange ou rouge. Si des codes défaut sont trouvés, vous pouvez '
            'les effacer après réparation avec le bouton Effacer les codes.',
          ),
          _Step(
            '7',
            'Activez le Mode Conduite pour que Mécano à Bord surveille en temps réel la température moteur, '
            'la tension batterie et la pression d\'huile pendant que vous roulez. Une alerte vocale '
            'vous prévient si quelque chose sort de la normale.',
          ),
          _Step(
            '8',
            'Dans votre profil véhicule, renseignez vos dates de contrôle technique, d\'assurance et de vignette '
            'Crit\'Air. L\'application vous préviendra avant les échéances importantes.',
          ),
          const SizedBox(height: MabDimensions.espacementXL),

          _ApiKeyHelpSection(openUrl: openUrl),

          const SizedBox(height: MabDimensions.espacementXL),

          Text('Formation La Méthode Sans Stress Auto', style: MabTextStyles.titreCard),
          const SizedBox(height: MabDimensions.espacementS),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => openUrl(kFormationUrl),
              icon: const Icon(Icons.school_outlined, color: MabColors.rouge),
              label: const Text('Accéder à la formation'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: MabColors.rouge),
                foregroundColor: MabColors.rouge,
              ),
            ),
          ),
          const SizedBox(height: MabDimensions.espacementXL),

          Text('Vidéos tutoriels', style: MabTextStyles.titreCard),
          const SizedBox(height: MabDimensions.espacementS),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => openUrl(_lienYoutube),
              icon: const Icon(Icons.play_circle_outline, color: MabColors.rouge),
              label: const Text('Voir les tutoriels'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: MabColors.rouge),
                foregroundColor: MabColors.rouge,
              ),
            ),
          ),
          const SizedBox(height: MabDimensions.espacementXXL),
        ],
      ),
    );
  }
}

/// Données pour la section « Comment obtenir votre clé API ? » (Aide).
class _ApiKeyHelpEntry {
  final String displayName;
  final String assetFileName;
  final String url;
  final String step1;
  final String step2;
  final String step3;
  final Color fallbackColor;
  final String fallbackLetter;

  const _ApiKeyHelpEntry({
    required this.displayName,
    required this.assetFileName,
    required this.url,
    required this.step1,
    required this.step2,
    required this.step3,
    required this.fallbackColor,
    required this.fallbackLetter,
  });
}

class _ApiKeyHelpSection extends StatelessWidget {
  final Future<void> Function(String url) openUrl;

  const _ApiKeyHelpSection({required this.openUrl});

  static const List<_ApiKeyHelpEntry> _entries = [
    _ApiKeyHelpEntry(
      displayName: 'ChatGPT (OpenAI)',
      assetFileName: 'chatgpt.png',
      url: 'https://platform.openai.com/api-keys',
      step1: 'Créez un compte sur platform.openai.com',
      step2: 'Allez dans « API Keys » puis « Create new secret key »',
      step3: 'Copiez la clé et collez-la dans Réglages → Assistant IA',
      fallbackColor: Color(0xFF10A37F),
      fallbackLetter: 'C',
    ),
    _ApiKeyHelpEntry(
      displayName: 'Claude (Anthropic)',
      assetFileName: 'claude.png',
      url: 'https://console.anthropic.com/api-keys',
      step1: 'Créez un compte sur console.anthropic.com',
      step2: 'Allez dans « API Keys » puis « Create Key »',
      step3: 'Copiez la clé et collez-la dans Réglages → Assistant IA',
      fallbackColor: Color(0xFFCC785C),
      fallbackLetter: 'C',
    ),
    _ApiKeyHelpEntry(
      displayName: 'Gemini (Google)',
      assetFileName: 'gemini.png',
      url: 'https://aistudio.google.com/app/apikey',
      step1: 'Connectez-vous avec votre compte Google',
      step2: 'Cliquez sur « Create API Key »',
      step3: 'Copiez la clé et collez-la dans Réglages → Assistant IA',
      fallbackColor: Color(0xFF4285F4),
      fallbackLetter: 'G',
    ),
    _ApiKeyHelpEntry(
      displayName: 'Mistral',
      assetFileName: 'mistral.png',
      url: 'https://console.mistral.ai/api-keys',
      step1: 'Créez un compte sur console.mistral.ai',
      step2: 'Allez dans « API Keys » puis « Create new key »',
      step3: 'Copiez la clé et collez-la dans Réglages → Assistant IA',
      fallbackColor: Color(0xFFFF7000),
      fallbackLetter: 'M',
    ),
    _ApiKeyHelpEntry(
      displayName: 'Qwen',
      assetFileName: 'qwen.png',
      url: 'https://dashscope.console.aliyun.com/apiKey',
      step1: 'Créez un compte sur dashscope.aliyun.com',
      step2: 'Allez dans « API Key » et créez une nouvelle clé',
      step3: 'Copiez la clé et collez-la dans Réglages → Assistant IA',
      fallbackColor: Color(0xFF6B4DE6),
      fallbackLetter: 'Q',
    ),
    _ApiKeyHelpEntry(
      displayName: 'Perplexity',
      assetFileName: 'perplexity.png',
      url: 'https://www.perplexity.ai/settings/api',
      step1: 'Créez un compte sur perplexity.ai',
      step2: 'Allez dans Réglages → « API » puis « Generate »',
      step3: 'Copiez la clé et collez-la dans Réglages → Assistant IA',
      fallbackColor: Color(0xFF20808D),
      fallbackLetter: 'P',
    ),
    _ApiKeyHelpEntry(
      displayName: 'Grok (xAI)',
      assetFileName: 'grok.png',
      url: 'https://console.x.ai/api-keys',
      step1: 'Créez un compte sur console.x.ai',
      step2: 'Allez dans « API Keys » puis « Create API Key »',
      step3: 'Copiez la clé et collez-la dans Réglages → Assistant IA',
      fallbackColor: Color(0xFF1DA1F2),
      fallbackLetter: 'G',
    ),
    _ApiKeyHelpEntry(
      displayName: 'Copilot (Microsoft)',
      assetFileName: 'copilot.png',
      url: 'https://azure.microsoft.com/fr-fr/products/ai-services',
      step1: 'Connectez-vous avec votre compte Microsoft',
      step2: 'Créez une ressource Azure OpenAI Service',
      step3: 'Copiez la clé et collez-la dans Réglages → Assistant IA',
      fallbackColor: Color(0xFF0078D4),
      fallbackLetter: 'C',
    ),
    _ApiKeyHelpEntry(
      displayName: 'Meta AI',
      assetFileName: 'meta_ai.png',
      url: 'https://ai.meta.com/llama',
      step1: 'Créez un compte sur ai.meta.com',
      step2: 'Demandez l\'accès à Llama API',
      step3: 'Copiez la clé et collez-la dans Réglages → Assistant IA',
      fallbackColor: Color(0xFF0668E1),
      fallbackLetter: 'M',
    ),
    _ApiKeyHelpEntry(
      displayName: 'DeepSeek',
      assetFileName: 'deepseek.png',
      url: 'https://platform.deepseek.com/api_keys',
      step1: 'Créez un compte sur platform.deepseek.com',
      step2: 'Allez dans « API Keys » puis « Create new API key »',
      step3: 'Copiez la clé et collez-la dans Réglages → Assistant IA',
      fallbackColor: Color(0xFF4D6BFE),
      fallbackLetter: 'D',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔑 Comment obtenir votre clé API ?',
          style: MabTextStyles.titreCard,
        ),
        const SizedBox(height: MabDimensions.espacementS),
        Text(
          'Choisissez votre assistant IA et suivez les 3 étapes simples.',
          style: MabTextStyles.corpsNormal.copyWith(
            color: MabColors.grisTexte,
            height: 1.5,
          ),
        ),
        const SizedBox(height: MabDimensions.espacementL),
        ..._entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: MabDimensions.espacementS),
            child: _ApiKeyProviderCard(entry: e, openUrl: openUrl),
          ),
        ),
      ],
    );
  }
}

class _ApiKeyProviderLogo extends StatelessWidget {
  final String assetFileName;
  final String fallbackLetter;
  final Color fallbackColor;

  const _ApiKeyProviderLogo({
    required this.assetFileName,
    required this.fallbackLetter,
    required this.fallbackColor,
  });

  static const double _kSize = 32;
  static const double _kRadius = 8;

  @override
  Widget build(BuildContext context) {
    final path = 'assets/images/ia/$assetFileName';
    return SizedBox(
      width: _kSize,
      height: _kSize,
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return CircleAvatar(
            radius: _kSize / 2,
            backgroundColor: fallbackColor,
            child: Text(
              fallbackLetter,
              style: MabTextStyles.titreCard.copyWith(
                color: MabColors.blanc,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame == null && !wasSynchronouslyLoaded) {
            return const SizedBox(width: _kSize, height: _kSize);
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(_kRadius),
            child: SizedBox(
              width: _kSize,
              height: _kSize,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _ApiKeyProviderCard extends StatelessWidget {
  final _ApiKeyHelpEntry entry;
  final Future<void> Function(String url) openUrl;

  const _ApiKeyProviderCard({
    required this.entry,
    required this.openUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: MabColors.noirClair,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
        side: const BorderSide(color: MabColors.grisContour),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: const ExpansionTileThemeData(
            iconColor: MabColors.grisDore,
            collapsedIconColor: MabColors.grisDore,
            textColor: MabColors.blanc,
            collapsedTextColor: MabColors.blanc,
          ),
        ),
        child: ExpansionTile(
          leading: _ApiKeyProviderLogo(
            assetFileName: entry.assetFileName,
            fallbackLetter: entry.fallbackLetter,
            fallbackColor: entry.fallbackColor,
          ),
          title: Text(
            entry.displayName,
            style: MabTextStyles.corpsNormal.copyWith(
              fontWeight: FontWeight.w600,
              color: MabColors.blanc,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MabDimensions.espacementM,
          ),
          children: [
            _Step('1', entry.step1),
            _Step('2', entry.step2),
            _Step('3', entry.step3),
            const SizedBox(height: MabDimensions.espacementS),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => openUrl(entry.url),
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  color: MabColors.rouge,
                  size: MabDimensions.iconeM,
                ),
                label: const Text('Aller sur le site →'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: MabColors.rouge),
                  foregroundColor: MabColors.rouge,
                  minimumSize: const Size(
                    double.infinity,
                    MabDimensions.zoneTactileMin,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;

  const _Step(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MabDimensions.espacementM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MabColors.rouge,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(number, style: MabTextStyles.badge.copyWith(color: MabColors.blanc, fontSize: 12)),
          ),
          const SizedBox(width: MabDimensions.espacementS),
          Expanded(child: Text(text, style: MabTextStyles.corpsNormal.copyWith(height: 1.5))),
        ],
      ),
    );
  }
}

class _ContactTab extends StatelessWidget {
  final String emailContact;
  final String lienSite;
  final Future<void> Function({String? subject, String? body}) openEmail;
  final Future<void> Function(String url) openUrl;
  final TextEditingController nomCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController sujetCtrl;
  final TextEditingController messageCtrl;

  const _ContactTab({
    required this.emailContact,
    required this.lienSite,
    required this.openEmail,
    required this.openUrl,
    required this.nomCtrl,
    required this.emailCtrl,
    required this.sujetCtrl,
    required this.messageCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: MabDimensions.paddingEcran,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email', style: MabTextStyles.titreCard),
          const SizedBox(height: MabDimensions.espacementS),
          Text(emailContact, style: MabTextStyles.corpsNormal),
          const SizedBox(height: MabDimensions.espacementS),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => openEmail(),
              icon: const Icon(Icons.email_outlined, color: MabColors.rouge),
              label: const Text('Envoyer un email'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: MabColors.rouge),
                foregroundColor: MabColors.rouge,
              ),
            ),
          ),
          const SizedBox(height: MabDimensions.espacementL),

          Text('Site web', style: MabTextStyles.titreCard),
          const SizedBox(height: MabDimensions.espacementS),
          Text(lienSite, style: MabTextStyles.corpsNormal),
          const SizedBox(height: MabDimensions.espacementS),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => openUrl(lienSite),
              icon: const Icon(Icons.language, color: MabColors.rouge),
              label: const Text('Visiter le site'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: MabColors.rouge),
                foregroundColor: MabColors.rouge,
              ),
            ),
          ),
          const SizedBox(height: MabDimensions.espacementXL),

          Text('Formulaire de contact', style: MabTextStyles.titreCard),
          const SizedBox(height: MabDimensions.espacementM),
          TextField(
            controller: nomCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom',
              hintText: 'Votre nom',
            ),
            style: MabTextStyles.corpsNormal,
          ),
          const SizedBox(height: MabDimensions.espacementS),
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'votre@email.fr',
            ),
            keyboardType: TextInputType.emailAddress,
            style: MabTextStyles.corpsNormal,
          ),
          const SizedBox(height: MabDimensions.espacementS),
          TextField(
            controller: sujetCtrl,
            decoration: const InputDecoration(
              labelText: 'Sujet',
              hintText: 'Objet de votre message',
            ),
            style: MabTextStyles.corpsNormal,
          ),
          const SizedBox(height: MabDimensions.espacementS),
          TextField(
            controller: messageCtrl,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Votre message...',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            style: MabTextStyles.corpsNormal,
          ),
          const SizedBox(height: MabDimensions.espacementL),
          SizedBox(
            width: double.infinity,
            height: MabDimensions.boutonHauteur,
            child: ElevatedButton.icon(
              onPressed: () {
                final subject = sujetCtrl.text.trim().isEmpty ? 'Contact Mécano à Bord' : sujetCtrl.text.trim();
                final body = 'Nom : ${nomCtrl.text.trim()}\nEmail : ${emailCtrl.text.trim()}\n\n${messageCtrl.text.trim()}';
                openEmail(subject: subject, body: body);
              },
              icon: const Icon(Icons.send_outlined),
              label: const Text('Envoyer'),
            ),
          ),
          const SizedBox(height: MabDimensions.espacementXXL),
        ],
      ),
    );
  }
}
