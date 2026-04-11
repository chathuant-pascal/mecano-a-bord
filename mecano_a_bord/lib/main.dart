// ============================================================
// MÉCANO À BORD — Point d'entrée
// Onboarding (une fois) → Profil véhicule → Accueil
// ============================================================
//
// URL formation : modifier uniquement kFormationUrl dans lib/formation_url.dart
// (une ligne pour basculer test local / production).
//

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/screens/onboarding_screen.dart';
import 'package:mecano_a_bord/screens/home_screen.dart';
import 'package:mecano_a_bord/screens/glovebox_profile_screen.dart';
import 'package:mecano_a_bord/screens/glovebox_screen.dart';
import 'package:mecano_a_bord/screens/add_maintenance_screen.dart';
import 'package:mecano_a_bord/screens/obd_scan_screen.dart';
import 'package:mecano_a_bord/screens/ai_chat_screen.dart';
import 'package:mecano_a_bord/screens/settings_screen.dart';
import 'package:mecano_a_bord/screens/surveillance_only_screen.dart';
import 'package:mecano_a_bord/screens/privacy_policy_screen.dart';
import 'package:mecano_a_bord/screens/legal_mentions_screen.dart';
import 'package:mecano_a_bord/screens/help_contact_screen.dart';
import 'package:mecano_a_bord/screens/diagnostic_guide_screen.dart';
import 'package:mecano_a_bord/screens/formation_web_launch_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mecano_a_bord/widgets/mab_logo.dart';
import 'package:mecano_a_bord/services/tts_service.dart';
import 'package:mecano_a_bord/services/surveillance_auto_coordinator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TtsService.instance.init();
  SurveillanceAutoCoordinator.instance.attach();
  runApp(const MabApp());
}

class MabApp extends StatelessWidget {
  const MabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mécano à Bord',
      theme: MabTheme.theme,
      home: const SplashRouting(),
      routes: {
        '/glovebox-profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return GloveboxProfileScreen(routeArguments: args);
        },
        '/obd-scan': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final auto = args is Map && args['autoStartDiagnostic'] == true;
          return ObdScanScreen(autoStartDiagnostic: auto);
        },
        '/surveillance-only': (_) => const SurveillanceOnlyScreen(),
        '/glovebox': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final tab = args is String ? args : null;
          return GloveboxScreen(initialTab: tab);
        },
        '/add-maintenance': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          int? editEntryId;
          if (args is Map) {
            final raw = args['editEntryId'];
            if (raw is int) {
              editEntryId = raw;
            } else if (raw is String) {
              editEntryId = int.tryParse(raw);
            }
          }
          return AddMaintenanceScreen(editEntryId: editEntryId);
        },
        '/ai-chat': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final String? initialQuestion = args is Map
              ? args['initialQuestion'] as String?
              : null;
          return AiChatScreen(initialQuestion: initialQuestion);
        },
        '/settings': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return SettingsScreen(
            initialSection:
                args is String ? args : null,
          );
        },
        '/privacy-policy': (_) => const PrivacyPolicyScreen(),
        '/legal-mentions': (_) => const LegalMentionsScreen(),
        '/help-contact': (_) => const HelpContactScreen(),
        '/diagnostic-guide': (_) => const DiagnosticGuideScreen(),
        '/systeme-io': (_) => const FormationWebLaunchScreen(),
      },
    );
  }
}

/// Splash puis redirection : Onboarding (première fois) ou Accueil.
class SplashRouting extends StatefulWidget {
  const SplashRouting({super.key});

  @override
  State<SplashRouting> createState() => _SplashRoutingState();
}

class _SplashRoutingState extends State<SplashRouting> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => onboardingDone
            ? const HomeScreen()
            : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MabLogo(size: 160),
            const SizedBox(height: MabDimensions.espacementL),
            const CircularProgressIndicator(color: MabColors.grisDore),
          ],
        ),
      ),
    );
  }
}
