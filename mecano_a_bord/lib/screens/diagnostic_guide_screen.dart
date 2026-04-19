// diagnostic_guide_screen.dart — Mécano à Bord
// Arbre décisionnel pour trouver une fiche sans vocabulaire technique.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mecano_a_bord/data/moteur_symptomes_knowledge.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';

class DiagnosticGuideScreen extends StatefulWidget {
  const DiagnosticGuideScreen({super.key});

  @override
  State<DiagnosticGuideScreen> createState() => _DiagnosticGuideScreenState();
}

enum _Phase { main, voyants, fumee, demarre, frein, bruit }

class _NavFrame {
  const _NavFrame.main()
      : phase = _Phase.main,
        resultId = null;

  const _NavFrame.sub(this.phase) : resultId = null, assert(phase != _Phase.main);

  const _NavFrame.result(String id)
      : phase = _Phase.main,
        resultId = id;

  final _Phase phase;
  final String? resultId;

  bool get isResult => resultId != null;
}

class _DiagnosticGuideScreenState extends State<DiagnosticGuideScreen> {
  final List<_NavFrame> _stack = [_NavFrame.main()];
  bool _dataReady = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await MoteurSymptomesKnowledge.ensureLoaded();
    if (!mounted) return;
    setState(() => _dataReady = true);
  }

  void _pushSub(_Phase p) {
    setState(() => _stack.add(_NavFrame.sub(p)));
  }

  void _pushResult(String id) {
    setState(() => _stack.add(_NavFrame.result(id)));
  }

  void _pop() {
    if (_stack.length <= 1) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _stack.removeLast());
  }

  void _restart() {
    setState(() {
      _stack
        ..clear()
        ..add(_NavFrame.main());
    });
  }

  Widget _bodyWithWatermark(Widget child) => child;

  @override
  Widget build(BuildContext context) {
    if (!_dataReady) {
      return Scaffold(
        backgroundColor: MabColors.noir,
        body: _bodyWithWatermark(
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: MabColors.blanc),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(MabDimensions.zoneTactileMin, MabDimensions.zoneTactileMin),
                  ),
                ),
                const SizedBox(height: MabDimensions.espacementL),
                const CircularProgressIndicator(color: MabColors.grisDore),
              ],
            ),
          ),
        ),
      );
    }

    final top = _stack.last;
    if (top.isResult && top.resultId != null) {
      final entry = MoteurSymptomesKnowledge.entryById(top.resultId!);
      return Scaffold(
        backgroundColor: MabColors.noir,
        body: _bodyWithWatermark(
          SafeArea(
            child: entry == null
                ? _buildUnknownId(top.resultId!)
                : _buildResultBody(entry),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MabColors.noir,
      body: _bodyWithWatermark(
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: MabDimensions.paddingEcran,
                  child: _buildQuestionContent(top.phase),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(
        left: MabDimensions.espacementS,
        right: MabDimensions.espacementM,
        top: MabDimensions.espacementS,
        bottom: MabDimensions.espacementS,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Retour',
            child: IconButton(
              onPressed: _pop,
              icon: const Icon(Icons.arrow_back_rounded, color: MabColors.blanc),
              style: IconButton.styleFrom(
                minimumSize: const Size(MabDimensions.zoneTactileMin, MabDimensions.zoneTactileMin),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Guide pas à pas',
              style: MabTextStyles.titreSection,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: MabDimensions.zoneTactileMin),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(_Phase phase) {
    switch (phase) {
      case _Phase.main:
        return _buildMainQuestion();
      case _Phase.voyants:
        return _buildVoyantsQuestion();
      case _Phase.fumee:
        return _buildFumeeQuestion();
      case _Phase.demarre:
        return _buildDemarreQuestion();
      case _Phase.frein:
        return _buildFreinQuestion();
      case _Phase.bruit:
        return _buildBruitQuestion();
    }
  }

  Widget _buildMainQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Que se passe-t-il avec votre voiture ?',
          style: MabTextStyles.titreCard,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: MabDimensions.espacementL),
        _choiceButton(
          label: 'Un voyant s\'est allumé',
          emoji: '🔴',
          onTap: () => _pushSub(_Phase.voyants),
        ),
        _choiceButton(
          label: 'J\'entends un bruit bizarre',
          emoji: '🔊',
          onTap: () => _pushSub(_Phase.bruit),
        ),
        _choiceButton(
          label: 'Je vois de la fumée',
          emoji: '💨',
          onTap: () => _pushSub(_Phase.fumee),
        ),
        _choiceButton(
          label: 'La voiture ne démarre pas',
          emoji: '🚗',
          onTap: () => _pushSub(_Phase.demarre),
        ),
        _choiceButton(
          label: 'Le freinage me semble anormal',
          emoji: '🛑',
          onTap: () => _pushSub(_Phase.frein),
        ),
        _choiceButton(
          label: 'La voiture manque de puissance',
          emoji: '⚡',
          onTap: () => _pushResult('panne_perte_puissance'),
        ),
      ],
    );
  }

  Widget _buildVoyantsQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quel voyant voyez-vous ?',
          style: MabTextStyles.titreCard,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: MabDimensions.espacementL),
        _choiceButton(label: 'Voyant moteur (orange fixe)', emoji: '🔶', onTap: () => _pushResult('voyant_moteur_orange')),
        _choiceButton(label: 'Voyant moteur (clignotant)', emoji: '⚠️', onTap: () => _pushResult('voyant_moteur_clignotant')),
        _choiceButton(label: 'Voyant huile (rouge)', emoji: '🛢️', onTap: () => _pushResult('voyant_huile_rouge')),
        _choiceButton(label: 'Voyant batterie', emoji: '🔋', onTap: () => _pushResult('voyant_batterie_rouge')),
        _choiceButton(label: 'Voyant température', emoji: '🌡️', onTap: () => _pushResult('voyant_temperature_rouge')),
        _choiceButton(label: 'Voyant frein', emoji: '🛑', onTap: () => _pushResult('voyant_frein_rouge')),
        _choiceButton(label: 'Voyant ABS', emoji: '⏹️', onTap: () => _pushResult('voyant_abs_orange')),
        _choiceButton(label: 'Voyant ESP', emoji: '↔️', onTap: () => _pushResult('voyant_esp_antipatinage')),
        _choiceButton(label: 'Voyant airbag', emoji: '☁️', onTap: () => _pushResult('voyant_airbag')),
        _choiceButton(label: 'Voyant direction assistée', emoji: '🔄', onTap: () => _pushResult('voyant_direction_assistee')),
        _choiceButton(label: 'Voyant pneu', emoji: '⭕', onTap: () => _pushResult('voyant_pression_pneus')),
        _choiceButton(label: 'Voyant préchauffage diesel', emoji: '〰️', onTap: () => _pushResult('voyant_prechauffage_diesel')),
        _choiceButton(label: 'Voyant FAP / antipollution', emoji: '🌫️', onTap: () => _pushResult('voyant_fap_antipollution')),
        _choiceButton(label: 'Voyant AdBlue', emoji: '💧', onTap: () => _pushResult('voyant_adblue')),
      ],
    );
  }

  Widget _buildFumeeQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quelle fumée voyez-vous ?',
          style: MabTextStyles.titreCard,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: MabDimensions.espacementL),
        _choiceButton(label: 'Fumée blanche', emoji: '⬜', onTap: () => _pushResult('panne_fumee_blanche')),
        _choiceButton(label: 'Fumée bleue', emoji: '🔵', onTap: () => _pushResult('panne_fumee_bleue')),
        _choiceButton(label: 'Fumée noire', emoji: '⬛', onTap: () => _pushResult('panne_fumee_noire')),
        _choiceButton(label: 'Fumée sous le capot', emoji: '💨', onTap: () => _pushResult('urgence_fumee_sous_capot')),
      ],
    );
  }

  Widget _buildDemarreQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Que se passe-t-il au démarrage ?',
          style: MabTextStyles.titreCard,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: MabDimensions.espacementL),
        _choiceButton(label: 'J\'entends un cliquetis', emoji: '🔇', onTap: () => _pushResult('panne_cliquetis_demarrage')),
        _choiceButton(label: 'Le moteur tourne mais ne démarre pas', emoji: '🔁', onTap: () => _pushResult('panne_moteur_tourne_sans_demarrer')),
        _choiceButton(label: 'Rien ne se passe', emoji: '⏸️', onTap: () => _pushResult('panne_ne_demarre_pas')),
        _choiceButton(label: 'La batterie se vide souvent', emoji: '🔋', onTap: () => _pushResult('panne_batterie_se_decharge')),
      ],
    );
  }

  Widget _buildFreinQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Qu\'est-ce qui vous inquiète ?',
          style: MabTextStyles.titreCard,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: MabDimensions.espacementL),
        _choiceButton(label: 'La pédale est molle', emoji: '🧽', onTap: () => _pushResult('panne_pedale_frein_molle')),
        _choiceButton(label: 'La voiture vibre au freinage', emoji: '📳', onTap: () => _pushResult('panne_vibrations_freinage')),
        _choiceButton(label: 'Le freinage est très faible', emoji: '⚠️', onTap: () => _pushResult('urgence_freinage_faible')),
        _choiceButton(label: 'La voiture tire d\'un côté', emoji: '↔️', onTap: () => _pushResult('panne_tire_un_cote')),
      ],
    );
  }

  Widget _buildBruitQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quel type de bruit ?',
          style: MabTextStyles.titreCard,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: MabDimensions.espacementL),
        _choiceButton(label: 'Claquement ou bruit métallique moteur', emoji: '🔩', onTap: () => _pushResult('panne_bruit_metallique_moteur')),
        _choiceButton(label: 'Sifflement', emoji: '〰️', onTap: () => _pushResult('panne_sifflement_turbo')),
        _choiceButton(label: 'À-coups ou secousses', emoji: '↕️', onTap: () => _pushResult('panne_a_coups_roulant')),
      ],
    );
  }

  Widget _choiceButton({
    required String label,
    required String emoji,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MabDimensions.espacementM),
      child: Material(
        color: MabColors.noirMoyen,
        borderRadius: BorderRadius.circular(MabDimensions.rayonBouton),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MabDimensions.rayonBouton),
          child: Container(
            constraints: const BoxConstraints(minHeight: MabDimensions.boutonHauteurGrand),
            padding: const EdgeInsets.symmetric(
              horizontal: MabDimensions.espacementM,
              vertical: MabDimensions.espacementM,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MabDimensions.rayonBouton),
              border: Border.all(color: MabColors.grisContour),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: MabDimensions.espacementM),
                Expanded(
                  child: Text(
                    label,
                    style: MabTextStyles.corpsMedium,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: MabColors.grisTexte),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnknownId(String id) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopBar(),
        Expanded(
          child: Padding(
            padding: MabDimensions.paddingEcran,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Cette fiche n\'est pas disponible pour le moment.',
                  style: MabTextStyles.corpsNormal,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: MabDimensions.espacementL),
                FilledButton(
                  onPressed: _restart,
                  child: const Text('Recommencer'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultBody(MoteurSymptomeEntry e) {
    final severityColor = _severityBannerColor(e.severity);
    final canDriveStyle = _canDriveStyle(e.canDrive);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResultTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: MabDimensions.paddingEcran,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(MabDimensions.espacementM),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
                  ),
                  child: Text(
                    MoteurSymptomesKnowledge.sanitizeForDisplay(e.title),
                    style: MabTextStyles.titreCard.copyWith(color: MabColors.blanc),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: MabDimensions.espacementL),
                Text(
                  'Puis-je rouler ?',
                  style: MabTextStyles.label.copyWith(color: MabColors.grisTexte),
                ),
                const SizedBox(height: MabDimensions.espacementS),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(MabDimensions.espacementM),
                  decoration: BoxDecoration(
                    color: MabColors.noirMoyen,
                    borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
                    border: Border.all(color: canDriveStyle.color.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    canDriveStyle.text,
                    style: MabTextStyles.corpsMedium.copyWith(color: canDriveStyle.color),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: MabDimensions.espacementL),
                Text(
                  'En bref',
                  style: MabTextStyles.label.copyWith(color: MabColors.grisTexte),
                ),
                const SizedBox(height: MabDimensions.espacementS),
                Text(
                  MoteurSymptomesKnowledge.sanitizeForDisplay(e.simpleExplanation),
                  style: MabTextStyles.corpsNormal,
                ),
                const SizedBox(height: MabDimensions.espacementL),
                Text(
                  'À faire maintenant',
                  style: MabTextStyles.label.copyWith(color: MabColors.grisTexte),
                ),
                const SizedBox(height: MabDimensions.espacementS),
                ...e.driverActions.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: MabDimensions.espacementS),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: MabTextStyles.corpsNormal),
                        Expanded(
                          child: Text(
                            MoteurSymptomesKnowledge.sanitizeForDisplay(a),
                            style: MabTextStyles.corpsNormal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (e.urgentIf.isNotEmpty) ...[
                  const SizedBox(height: MabDimensions.espacementM),
                  Text(
                    'Signes qui aggravent la situation',
                    style: MabTextStyles.label.copyWith(color: MabColors.grisTexte),
                  ),
                  const SizedBox(height: MabDimensions.espacementS),
                  ...e.urgentIf.map(
                    (u) => Padding(
                      padding: const EdgeInsets.only(bottom: MabDimensions.espacementS),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.warning_amber_rounded, size: 18, color: MabColors.diagnosticOrange),
                          ),
                          const SizedBox(width: MabDimensions.espacementS),
                          Expanded(
                            child: Text(
                              MoteurSymptomesKnowledge.sanitizeForDisplay(u),
                              style: MabTextStyles.corpsNormal.copyWith(color: MabColors.grisTexte),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: MabDimensions.espacementL),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(MabDimensions.espacementM),
                  decoration: BoxDecoration(
                    color: MabColors.diagnosticRougeClair.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
                    border: Border.all(color: MabColors.diagnosticRouge),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Phrase à dire au garagiste',
                        style: MabTextStyles.label.copyWith(color: MabColors.diagnosticRouge),
                      ),
                      const SizedBox(height: MabDimensions.espacementS),
                      Text(
                        MoteurSymptomesKnowledge.sanitizeForDisplay(e.garagePhrase),
                        style: MabTextStyles.corpsNormal.copyWith(
                          color: MabColors.blanc,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: MabDimensions.espacementM),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: MoteurSymptomesKnowledge.sanitizeForDisplay(e.garagePhrase)),
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Phrase copiée',
                                style: MabTextStyles.corpsNormal.copyWith(color: MabColors.blanc),
                              ),
                              backgroundColor: MabColors.noirMoyen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, color: MabColors.rouge),
                        label: Text(
                          'Copier la phrase',
                          style: MabTextStyles.boutonSecondaire,
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: MabColors.rouge, width: 2),
                          minimumSize: const Size(double.infinity, MabDimensions.boutonHauteur),
                        ),
                      ),
                    ],
                  ),
                ),
                if (e.obdRecommended) ...[
                  const SizedBox(height: MabDimensions.espacementL),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(MabDimensions.espacementM),
                    decoration: BoxDecoration(
                      color: MabColors.noirMoyen,
                      borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
                      border: Border.all(color: MabColors.grisContour),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bluetooth_searching, color: MabColors.grisDore),
                        const SizedBox(width: MabDimensions.espacementM),
                        Expanded(
                          child: Text(
                            'Un diagnostic OBD est recommandé pour préciser la cause.',
                            style: MabTextStyles.corpsNormal.copyWith(color: MabColors.grisTexte),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: MabDimensions.espacementXL),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _restart,
                        child: const Text('Recommencer'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MabDimensions.espacementL),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultTopBar() {
    return Padding(
      padding: const EdgeInsets.only(
        left: MabDimensions.espacementS,
        right: MabDimensions.espacementM,
        top: MabDimensions.espacementS,
        bottom: MabDimensions.espacementS,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Retour',
            child: IconButton(
              onPressed: _pop,
              icon: const Icon(Icons.arrow_back_rounded, color: MabColors.blanc),
              style: IconButton.styleFrom(
                minimumSize: const Size(MabDimensions.zoneTactileMin, MabDimensions.zoneTactileMin),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Votre fiche',
              style: MabTextStyles.titreSection,
              textAlign: TextAlign.center,
            ),
          ),
          Semantics(
            button: true,
            label: 'Recommencer',
            child: TextButton(
              onPressed: _restart,
              child: Text(
                'Recommencer',
                style: MabTextStyles.label.copyWith(color: MabColors.grisDore),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _severityBannerColor(String severity) {
    switch (severity) {
      case 'critique':
        return MabColors.diagnosticRouge;
      case 'elevee':
        return MabColors.diagnosticOrange;
      case 'moyenne':
        return MabColors.diagnosticOrange.withValues(alpha: 0.85);
      case 'faible':
        return MabColors.diagnosticVert;
      default:
        return MabColors.noirMoyen;
    }
  }

  ({Color color, String text}) _canDriveStyle(String canDrive) {
    switch (canDrive) {
      case 'non':
        return (
          color: MabColors.diagnosticRouge,
          text: 'Ne roulez pas',
        );
      case 'court_trajet_uniquement':
        return (
          color: MabColors.diagnosticOrange,
          text: 'Court trajet uniquement',
        );
      case 'oui_prudence':
        return (
          color: MabColors.diagnosticOrange.withValues(alpha: 0.95),
          text: 'Oui, avec prudence',
        );
      case 'oui':
        return (
          color: MabColors.diagnosticVert,
          text: 'Oui',
        );
      default:
        return (
          color: MabColors.grisTexte,
          text: MoteurSymptomesKnowledge.sanitizeForDisplay(canDrive),
        );
    }
  }
}
