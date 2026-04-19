// ============================================================
// ONBOARDING — Premier écran à l'installation (une seule fois)
// 1) Page d'acceptation des conditions (hors carrousel)
// 2) Carrousel : 5 pages (logo bienvenue, OBD, Boîte à gants, SUV, Système IO)
// À la fin → formation WebView interne (kFormationUrl) puis accueil
// Charte graphique MAB (thème sombre).
// ============================================================

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/screens/formation_webview_screen.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/widgets/mab_logo.dart';
import 'package:mecano_a_bord/widgets/mab_watermark_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// MODÈLE D'UNE PAGE
// ─────────────────────────────────────────────

class OnboardingPage {
  final String imagePath; // Optionnel : assets/images/...
  final IconData icon; // Utilisé si image absente
  final String title;
  final String description;
  final bool showTitle; // false = masquer le titre (pages 1, 2, 4, 5)
  final double illustrationHeight; // hauteur de l'image (page 5 plus grande)

  const OnboardingPage({
    this.imagePath = '',
    required this.icon,
    required this.title,
    required this.description,
    this.showTitle = true,
    this.illustrationHeight = 260,
  });
}

// ─────────────────────────────────────────────
// ÉCRAN ONBOARDING
// ─────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// Tant que `false`, seule la page d'acceptation des conditions est affichée (pas de carrousel).
  bool _acceptanceCompleted = false;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      imagePath: 'assets/images/logo.png',
      icon: Icons.directions_car_rounded,
      title: 'Bienvenue dans Mécano à Bord',
      description:
          'Votre copilote automobile. Il lit les informations de votre voiture '
          'et vous les explique en langage simple, sans jargon.',
      showTitle: false,
    ),
    OnboardingPage(
      imagePath: 'assets/images/obd.png',
      icon: Icons.bluetooth_rounded,
      title: 'Le boîtier connecté',
      description:
          'Branchez le petit boîtier OBD sous votre tableau de bord. '
          'Il se connecte à votre téléphone en Bluetooth et lit les données de votre moteur.',
      showTitle: false,
    ),
    OnboardingPage(
      imagePath: 'assets/images/boite_a_gant.png',
      icon: Icons.folder_rounded,
      title: 'Votre Boîte à gants numérique',
      description:
          'Carte grise, assurance, contrôle technique, carnet d\'entretien… '
          'Tous vos documents au même endroit, toujours avec vous.',
    ),
    OnboardingPage(
      imagePath: 'assets/images/suv_images.png',
      icon: Icons.directions_car_rounded,
      title: 'Créer mon profil véhicule',
      description:
          'Pour commencer, dites-nous quel véhicule vous conduisez. '
          'Cela prend moins de 2 minutes.',
      showTitle: false,
    ),
    OnboardingPage(
      imagePath: 'assets/images/systeme_io.png',
      icon: Icons.settings_input_antenna_rounded,
      title: 'Accès à la méthode sans stress auto',
      description:
          'Accédez au système depuis l\'écran d\'accueil.',
      showTitle: false,
      illustrationHeight: 320,
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _goToNextPage() {
    if (_isLastPage) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() => _finishOnboarding();

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const FormationWebViewScreen(),
      ),
    );
  }

  void _onAcceptAndContinue() {
    setState(() => _acceptanceCompleted = true);
  }

  /// Étape 1 : acceptation des conditions — hors carrousel, sans indicateurs de page.
  Widget _buildAcceptanceStep() {
    return Semantics(
      label:
          'Bienvenue. En utilisant Mécano à Bord, vous acceptez les conditions '
          'd\'utilisation. Bouton : J\'accepte et je commence.',
      child: Container(
        color: MabColors.noir,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: MabDimensions.paddingEcran,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/onboarding_page1.png',
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: MabDimensions.espacementXL),
                    const Text(
                      'Bienvenue',
                      textAlign: TextAlign.center,
                      style: MabTextStyles.titrePrincipal,
                    ),
                    const SizedBox(height: MabDimensions.espacementL),
                    const Text(
                      'En utilisant Mécano à Bord, vous acceptez les '
                      'conditions d\'utilisation applicables.',
                      textAlign: TextAlign.center,
                      style: MabTextStyles.titreSection,
                    ),
                    const SizedBox(height: MabDimensions.espacementL),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/legal-mentions');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: MabColors.blanc,
                        minimumSize: const Size(
                          MabDimensions.zoneTactileMin,
                          MabDimensions.zoneTactileMin,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: MabDimensions.espacementM,
                          vertical: MabDimensions.espacementS,
                        ),
                      ),
                      child: Text(
                        'Voir les mentions légales complètes →',
                        textAlign: TextAlign.center,
                        style: MabTextStyles.corpsNormal.copyWith(
                          color: MabColors.blanc,
                          decoration: TextDecoration.underline,
                          decorationColor: MabColors.blanc,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: MabDimensions.paddingEcran,
              child: SizedBox(
                width: double.infinity,
                height: MabDimensions.boutonHauteur,
                child: ElevatedButton(
                  onPressed: _onAcceptAndContinue,
                  child: const Text('J\'accepte et je commence'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Étape 2 : carrousel inchangé (sans bloc légal répété en bas).
  Widget _buildOnboardingCarousel() {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: MabDimensions.paddingEcran,
            child: _isLastPage
                ? const SizedBox(height: 48)
                : TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text('Passer'),
                  ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return _OnboardingPageWidget(page: _pages[index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: MabDimensions.espacementL,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(
                  horizontal: MabDimensions.espacementXS,
                ),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? MabColors.rouge
                      : MabColors.noirClair,
                  borderRadius:
                      BorderRadius.circular(MabDimensions.rayonPetit),
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: MabDimensions.paddingEcran,
          child: SizedBox(
            width: double.infinity,
            height: MabDimensions.boutonHauteur,
            child: ElevatedButton(
              onPressed: _goToNextPage,
              child: const Text('Suivant'),
            ),
          ),
        ),
        const SizedBox(height: MabDimensions.espacementS),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      body: MabWatermarkBackground(
        watermarkOpacity: 0.15,
        child: SafeArea(
          child: _acceptanceCompleted
              ? _buildOnboardingCarousel()
              : _buildAcceptanceStep(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
// WIDGET D'UNE PAGE (illustration ou icône + texte)
// ─────────────────────────────────────────────

class _OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MabDimensions.espacementXL,
          vertical: MabDimensions.espacementM,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIllustration(),
            const SizedBox(height: MabDimensions.espacementXL),
            if (page.showTitle) ...[
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: MabTextStyles.titrePrincipal,
              ),
              const SizedBox(height: MabDimensions.espacementM),
            ],
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: MabTextStyles.corpsNormal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    final height = page.illustrationHeight;
    if (page.imagePath.isNotEmpty) {
      return Image.asset(
        page.imagePath,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildIconPlaceholder(),
      );
    }
    return _buildIconPlaceholder();
  }

  Widget _buildIconPlaceholder() {
    final size = page.illustrationHeight;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: MabColors.noirMoyen,
        borderRadius:
            BorderRadius.circular(MabDimensions.rayonGrand),
        border: Border.all(color: MabColors.grisContour, width: 1),
      ),
      child: Icon(
        page.icon,
        size: 100,
        color: MabColors.grisDore,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// UTILITAIRE : l'onboarding a déjà été vu ?
// (pour main.dart ou splash)
// ─────────────────────────────────────────────

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_done') ?? false;
}
