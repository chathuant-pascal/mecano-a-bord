// onboarding_screen.dart — Mécano à Bord (Flutter iOS + Android)
//
// Premier écran affiché à l'installation de l'application.
// S'affiche UNE SEULE FOIS — jamais revu après.
//
// Contenu : 4 pages qui expliquent simplement l'application
//   Page 1 — Bienvenue (qui est Mécano à Bord)
//   Page 2 — Le boîtier OBD (comment ça fonctionne)
//   Page 3 — La Boîte à gants (tous vos documents)
//   Page 4 — Prêt ! (bouton pour créer le profil véhicule)
//
// À la fin de l'onboarding → GloveboxProfileScreen (création du profil véhicule)
//
// Dépendances Flutter à ajouter dans pubspec.yaml :
//   shared_preferences: ^2.2.3   (mémoriser que l'onboarding a été vu)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// MODÈLE DE DONNÉES D'UNE PAGE
// ─────────────────────────────────────────────

class OnboardingPage {
  final String imagePath;   // Chemin vers l'illustration (assets/)
  final String title;
  final String description;

  const OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

// ─────────────────────────────────────────────
// ÉCRAN PRINCIPAL D'ONBOARDING
// ─────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Contenu des 4 pages
  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      imagePath   : 'assets/images/onboarding_welcome.png',
      title       : 'Bienvenue dans Mécano à Bord',
      description : 'Votre copilote automobile. Il lit les informations de votre voiture '
                    'et vous les explique en langage simple, sans jargon.',
    ),
    OnboardingPage(
      imagePath   : 'assets/images/onboarding_obd.png',
      title       : 'Le boîtier connecté',
      description : 'Branchez le petit boîtier OBD sous votre tableau de bord. '
                    'Il se connecte à votre téléphone en Bluetooth et lit les données de votre moteur.',
    ),
    OnboardingPage(
      imagePath   : 'assets/images/onboarding_glovebox.png',
      title       : 'Votre Boîte à gants numérique',
      description : 'Carte grise, assurance, contrôle technique, carnet d\'entretien… '
                    'Tous vos documents au même endroit, toujours avec vous.',
    ),
    OnboardingPage(
      imagePath   : 'assets/images/onboarding_ready.png',
      title       : 'C\'est parti !',
      description : 'Pour commencer, dites-nous quel véhicule vous conduisez. '
                    'Cela prend moins de 2 minutes.',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  // ─────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────

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
    // Marquer l'onboarding comme vu (ne plus jamais l'afficher)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    if (!mounted) return;

    // Aller à la création du profil véhicule
    Navigator.of(context).pushReplacementNamed('/glovebox-profile');
  }

  // ─────────────────────────────────────────────
  // INTERFACE
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Bouton "Passer" en haut à droite (caché sur la dernière page)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _isLastPage
                    ? const SizedBox(height: 36)
                    : TextButton(
                        onPressed: _skipOnboarding,
                        child: const Text(
                          'Passer',
                          style: TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
            ),

            // Pages défilantes
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _OnboardingPageWidget(page: _pages[index]);
                },
              ),
            ),

            // Indicateurs de page (•••)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF2196F3)  // Bleu actif
                          : const Color(0xFFBDBDBD), // Gris inactif
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Bouton principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _goToNextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    _isLastPage ? 'Créer mon profil véhicule' : 'Suivant',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
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
// WIDGET D'UNE PAGE (illustration + texte)
// ─────────────────────────────────────────────

class _OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Image.asset(
            page.imagePath,
            height: 260,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 260,
              width: 260,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                size: 100,
                color: Color(0xFF2196F3),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Titre
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF5A5A72),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// UTILITAIRE : vérifier si l'onboarding a été vu
// À appeler au démarrage de l'application (dans main.dart)
// ─────────────────────────────────────────────

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_done') ?? false;
}
