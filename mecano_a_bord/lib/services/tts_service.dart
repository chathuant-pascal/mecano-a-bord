// tts_service.dart — Mécano à Bord
// Synthèse vocale : alertes OBD et test de voix (coach vocal).
// Messages sans les mots interdits : panne, danger, défaillance.
// Préférence : [mab_voice_gender] = 'female' | 'male' (défaut 'female').

import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de synthèse vocale pour le coach vocal.
/// Utilise [mab_voice_gender], [voice_alerts_enabled] et migre l’ancienne clé [voice_gender].
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _languageAndVolumeSet = false;

  /// Clé préférence voix (female / male).
  static const String keyMabVoiceGender = 'mab_voice_gender';
  static const String genderFemale = 'female';
  static const String genderMale = 'male';

  static const String _locale = 'fr-FR';

  /// Voix masculine réseau (Google TTS, [getVoices] : tirets, `network_required`).
  static const String maleVoiceName = 'fr-fr-x-frb-network';

  /// Féminine : pitch 1.2 + débit 0.5 — ne pas modifier.
  static const double pitchFeminine = 1.2;
  static const double speechRateFeminine = 0.5;

  /// Masculine : pitch 0.1 + débit 0.35 + voix réseau.
  static const double pitchMasculine = 0.1;
  static const double speechRateMasculine = 0.35;

  /// Dernière voix appliquée sur le moteur TTS (évite de réappliquer inutilement).
  String? _cachedGender;

  /// Messages d'alerte (sans panne, danger, défaillance).
  static const String alertOrange =
      'J\'ai détecté quelque chose sur ta voiture. Jette un œil à l\'application, je t\'explique tout.';
  static const String alertRed =
      'Le témoin moteur vient de s\'allumer. Lève le pied et regarde l\'application.';

  /// Phrase de test (réglages — coach vocal).
  static const String testPhraseChosenVoice =
      'Bonjour ! Je suis ton coach Mécano à Bord. Je suis là pour surveiller ta voiture avec toi.';

  /// Phrase longue (usage interne / historique).
  static const String testPhrase =
      'Salut ! Mécano à Bord à l\'écoute. Je garde un œil sur ta voiture et je te préviens si quelque chose mérite ton attention.';

  /// À appeler au démarrage de l’app ([main]) après [WidgetsFlutterBinding.ensureInitialized].
  Future<void> init() async {
    await _ensureLanguageAndVolume();
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyVoiceGenderIfNeeded(prefs);
    final g = _normalizeGender(prefs.getString(keyMabVoiceGender));
    try {
      await switchVoice(g);
    } catch (_) {
      // Ex. voix réseau indisponible hors ligne — repli voix féminine locale.
      await setFemaleVoice();
      await prefs.setString(keyMabVoiceGender, genderFemale);
    }
  }

  /// Voix féminine : pitch / débit figés, sans [setVoice] (voix locale par défaut fr-FR).
  Future<void> setFemaleVoice() async {
    await _ensureLanguageAndVolume();
    await _tts.setLanguage(_locale);
    await _tts.setPitch(pitchFeminine);
    await _tts.setSpeechRate(speechRateFeminine);
    _cachedGender = genderFemale;
  }

  /// Voix masculine : voix réseau + pitch / débit figés.
  Future<void> setMaleVoice() async {
    await _ensureLanguageAndVolume();
    await _tts.setLanguage(_locale);
    await _tts.setVoice({
      'name': maleVoiceName,
      'locale': _locale,
    });
    await _tts.setPitch(pitchMasculine);
    await _tts.setSpeechRate(speechRateMasculine);
    _cachedGender = genderMale;
  }

  /// [gender] : `'male'` ou `'female'` (insensible à la casse ; autre → female).
  Future<void> switchVoice(String gender) async {
    final g = _normalizeGender(gender);
    if (g == genderMale) {
      await setMaleVoice();
    } else {
      await setFemaleVoice();
    }
  }

  static String _normalizeGender(String? raw) {
    if (raw == null) return genderFemale;
    final s = raw.toLowerCase();
    if (s == genderMale || s == 'masculine') return genderMale;
    return genderFemale;
  }

  /// Migre `voice_gender` (FEMININE / MASCULINE) vers [keyMabVoiceGender] une seule fois.
  Future<void> _migrateLegacyVoiceGenderIfNeeded(SharedPreferences prefs) async {
    if (prefs.containsKey(keyMabVoiceGender)) return;
    final legacy = prefs.getString('voice_gender');
    if (legacy == 'MASCULINE') {
      await prefs.setString(keyMabVoiceGender, genderMale);
    } else {
      await prefs.setString(keyMabVoiceGender, genderFemale);
    }
  }

  Future<void> _ensureLanguageAndVolume() async {
    if (!_languageAndVolumeSet) {
      await _tts.setLanguage(_locale);
      await _tts.setVolume(1.0);
      _languageAndVolumeSet = true;
    }
  }

  /// Aligne le moteur TTS sur les préférences (ex. après retour des réglages).
  Future<void> _syncVoiceFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyVoiceGenderIfNeeded(prefs);
    final g = _normalizeGender(prefs.getString(keyMabVoiceGender));
    if (_cachedGender == g) return;
    await switchVoice(g);
  }

  Future<void> _ensureConfigured() async {
    await _ensureLanguageAndVolume();
    await _syncVoiceFromPreferences();
  }

  /// Prononce l'alerte correspondant au niveau OBD (orange ou red), uniquement si les alertes vocales sont activées.
  Future<void> speakAlertForLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('voice_alerts_enabled') ?? true;
    if (!enabled) return;
    await _ensureConfigured();
    final message = level == 'red' ? alertRed : alertOrange;
    await _tts.speak(message);
  }

  /// Lit la phrase de test pour la voix actuellement choisie (Réglages).
  Future<void> speakChosenVoiceTest() async {
    await _ensureConfigured();
    await _tts.speak(testPhraseChosenVoice);
  }

  /// Lit l’ancienne phrase longue (compat).
  Future<void> speakTest() async {
    await _ensureConfigured();
    await _tts.speak(testPhrase);
  }

  /// Arrête la synthèse en cours.
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Alerte surveillance temps réel (priorité : coupe la lecture en cours).
  Future<void> speakLiveMonitoringAlert(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('voice_alerts_enabled') ?? true;
    if (!enabled) return;
    await _ensureConfigured();
    await _tts.stop();
    await _tts.speak(message);
  }

  /// Après effacement réussi des codes OBD (même préférence que les autres annonces vocales).
  static const String messageAfterDtcClear =
      'C\'est effacé. Si le voyant revient au prochain démarrage, '
      'c\'est que le problème est toujours là. Dans ce cas, '
      'il faudra le faire réparer.';

  Future<void> speakAfterDtcClear() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('voice_alerts_enabled') ?? true;
    if (!enabled) return;
    await _ensureConfigured();
    await _tts.stop();
    await _tts.speak(messageAfterDtcClear);
  }
}
