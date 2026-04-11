import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'data/mab_repository.dart';
import 'licence/firebase_licence_manager.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/activation/activation_screen.dart';

/// MÉCANO À BORD — main.dart
/// ─────────────────────────────────────────────────────────────
/// Point d'entrée de l'application Flutter (iOS + Android).
///
/// Ce fichier fait deux choses :
///   1. Lance l'application Flutter
///   2. Décide vers quel écran envoyer l'utilisateur au démarrage
///
/// La logique de démarrage est identique à la version Android :
///   - Première ouverture → Onboarding
///   - Déjà vu → Vérification licence
///   - Licence ok → Accueil
///   - Problème → Écran approprié
/// ─────────────────────────────────────────────────────────────

void main() async {
  // "WidgetsFlutterBinding" = obligatoire avant tout code async au démarrage
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Firebase (obligatoire avant tout appel Firebase)
  await Firebase.initializeApp();

  // L'app reste en mode portrait uniquement (plus sûr pour la conduite)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MecanoABordApp());
}

/// Racine de l'application.
/// Définit le thème visuel et le nom de l'app.
class MecanoABordApp extends StatelessWidget {
  const MecanoABordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mécano à Bord',
      debugShowCheckedModeBanner: false, // Cache le bandeau rouge "DEBUG"

      // ── Thème visuel ──────────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8), // Bleu principal Mécano à Bord
          brightness: Brightness.light,
        ),
        fontFamily: 'Poppins', // Police douce et lisible
      ),

      // ── Écran de démarrage ────────────────────────────────────
      // SplashRouter décide vers quel écran aller
      home: const SplashRouter(),

      // ── Toutes les routes de navigation ──────────────────────
      // (utilisées avec Navigator.pushNamed(context, '/nom'))
      routes: {
        '/onboarding':   (ctx) => const OnboardingScreen(),
        '/home':         (ctx) => const HomeScreen(),
        '/login':        (ctx) => const LoginScreen(),
        '/activation':   (ctx) => const ActivationScreen(),
        '/max-devices':  (ctx) => const MaxDevicesScreen(),
      },
    );
  }
}

/// SplashRouter : l'écran invisible qui décide de la redirection.
/// Il affiche le logo pendant qu'il vérifie les conditions de démarrage.
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {

  @override
  void initState() {
    super.initState();
    // Dès que l'écran est prêt, on lance la vérification
    _checkStartupConditions();
  }

  /// Vérifie les conditions de démarrage dans l'ordre.
  Future<void> _checkStartupConditions() async {
    final repository = MabRepository.instance;
    final licenceManager = FirebaseLicenceManager.instance;

    // ──────────────────────────────────────────────
    // ÉTAPE 1 : L'utilisateur a-t-il vu l'onboarding ?
    // ──────────────────────────────────────────────
    final onboardingCompleted = await repository.isOnboardingCompleted();

    if (!onboardingCompleted) {
      _navigateTo('/onboarding');
      return;
    }

    // ──────────────────────────────────────────────
    // ÉTAPE 2 : Vérification de la licence
    // ──────────────────────────────────────────────
    final licenceStatus = await licenceManager.checkLicence();

    switch (licenceStatus) {

      case LicenceStatus.valid:
        // Tout est bon → accueil principal
        _navigateTo('/home');
        break;

      case LicenceStatus.notActivated:
        // Compte créé mais pas encore activé
        _navigateTo('/activation');
        break;

      case LicenceStatus.maxDevicesReached:
        // Trop d'appareils enregistrés
        _navigateTo('/max-devices');
        break;

      case LicenceStatus.noInternet:
        // Pas de connexion → accueil avec avertissement
        _navigateToHomeWithWarning();
        break;

      case LicenceStatus.notLoggedIn:
      case LicenceStatus.expired:
        // Pas connecté ou licence expirée → connexion
        _navigateTo('/login');
        break;
    }
  }

  /// Navigation simple vers une route nommée.
  /// "pushReplacementNamed" = redirige sans possibilité de revenir en arrière.
  void _navigateTo(String route) {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  /// Navigation vers l'accueil avec un paramètre "hors-ligne".
  void _navigateToHomeWithWarning() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(showOfflineWarning: true),
      ),
    );
  }

  // ── Interface visuelle du splash ─────────────────────────────
  // Pendant la vérification, on affiche le logo de l'app
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A73E8), // Fond bleu Mécano à Bord
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Logo de l'application
            Image.asset(
              'assets/images/logo_mab.png',
              width: 160,
              height: 160,
            ),

            const SizedBox(height: 24),

            // Nom de l'app
            const Text(
              'Mécano à Bord',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            // Slogan
            const Text(
              'La méthode sans stress auto',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 48),

            // Indicateur de chargement discret
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Écran affiché quand l'utilisateur a atteint la limite de 2 appareils.
/// (Écran simple, Inès peut personnaliser le design)
class MaxDevicesScreen extends StatelessWidget {
  const MaxDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Limite d\'appareils atteinte')),
      body: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices, size: 64, color: Colors.orange),
            SizedBox(height: 24),
            Text(
              'Vous avez atteint la limite de 2 appareils pour cette licence.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Text(
              'Pour utiliser Mécano à Bord sur cet appareil, '
              'veuillez d\'abord désactiver un autre appareil depuis votre espace client.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
