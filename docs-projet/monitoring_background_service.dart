// monitoring_background_service.dart — Mécano à Bord (Flutter iOS + Android)
//
// Rôle : surveille le véhicule EN ARRIÈRE-PLAN pendant la conduite.
// Tourne même si l'écran est éteint ou si l'utilisateur utilise une autre app.
//
// Ce que ce service fait :
//  - Maintient une connexion OBD active
//  - Analyse les données reçues toutes les 5 secondes
//  - Envoie des alertes vocales calmes si une anomalie est détectée
//  - S'arrête automatiquement après 60 secondes sans connexion OBD
//  - Affiche une notification persistante pendant la surveillance
//
// Dépendances Flutter à ajouter dans pubspec.yaml :
//   flutter_background_service: ^5.0.5
//   flutter_local_notifications: ^17.0.0
//   flutter_tts: ^4.0.2

import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'mab_repository.dart';
import 'mab_database.dart';

// ─────────────────────────────────────────────
// MODÈLE DE DONNÉES OBD
// ─────────────────────────────────────────────

class ObdData {
  final int engineTempCelsius;
  final double oilPressureBar;
  final int rpmValue;
  final int speedKmh;
  final List<String> activeDtcCodes;
  final int timestamp;

  ObdData({
    this.engineTempCelsius = 0,
    this.oilPressureBar = 3.0,
    this.rpmValue = 0,
    this.speedKmh = 0,
    this.activeDtcCodes = const [],
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;
}

// ─────────────────────────────────────────────
// ÉVALUATION DU NIVEAU DE RISQUE
// ─────────────────────────────────────────────

RiskLevel evaluateRisk(ObdData data) {
  if (data.engineTempCelsius >= 120) return RiskLevel.red;
  if (data.engineTempCelsius >= 110) return RiskLevel.orange;
  if (data.oilPressureBar <= 0.5) return RiskLevel.red;
  if (data.oilPressureBar <= 1.0) return RiskLevel.orange;
  if (data.activeDtcCodes.isNotEmpty) return RiskLevel.orange;
  return RiskLevel.green;
}

// ─────────────────────────────────────────────
// MESSAGES VOCAUX (langage humain, non anxiogène)
// ─────────────────────────────────────────────

/// Messages ORANGE : prudence, pas d'urgence.
/// Mots interdits : panne, danger, défaillance, risque grave, erreur fatale
String buildOrangeMessage(ObdData data) {
  if (data.engineTempCelsius >= 110) {
    return "Votre moteur commence à chauffer. Évitez les longs trajets pour l'instant.";
  }
  if (data.oilPressureBar <= 1.0) {
    return "La pression d'huile mérite votre attention. Pensez à vérifier le niveau dès que possible.";
  }
  if (data.activeDtcCodes.isNotEmpty) {
    return "Votre véhicule a détecté quelque chose d'inhabituel. Un diagnostic complet est conseillé.";
  }
  return "Un point mérite votre attention. Consultez l'application pour plus de détails.";
}

/// Messages ROUGE : arrêt conseillé, toujours calme et rassurant.
String buildRedMessage(ObdData data) {
  if (data.engineTempCelsius >= 120) {
    return "Votre moteur est très chaud. Arrêtez-vous dès que vous pouvez en toute sécurité et coupez le moteur.";
  }
  if (data.oilPressureBar <= 0.5) {
    return "La pression d'huile est très basse. Arrêtez-vous dès que possible et coupez le moteur.";
  }
  return "Votre véhicule nécessite votre attention immédiate. Arrêtez-vous dès que vous pouvez en sécurité.";
}

// ─────────────────────────────────────────────
// POINT D'ENTRÉE DU SERVICE EN ARRIÈRE-PLAN
// S'exécute dans un isolat séparé (processus Flutter indépendant)
// ─────────────────────────────────────────────

@pragma('vm:entry-point')
void monitoringBackgroundMain() {
  WidgetsFlutterBinding.ensureInitialized();
  final service = FlutterBackgroundService();

  service.on('startMonitoring').listen((event) async {
    final voiceGender = event?['voiceGender'] as String? ?? 'FEMININE';
    await _runMonitoringLoop(service, voiceGender);
  });

  service.on('stopMonitoring').listen((_) {
    service.invoke('stop');
    service.stopSelf();
  });
}

Future<void> _runMonitoringLoop(
  FlutterBackgroundService service,
  String voiceGender,
) async {
  // Initialisation des outils
  final tts = FlutterTts();
  await tts.setLanguage('fr-FR');

  final notifications = FlutterLocalNotificationsPlugin();
  await _initNotifications(notifications);

  final db = MabDatabase();
  final repo = MabRepository(db);

  // Vérification de sécurité : profil véhicule complet requis
  final profileComplete = await repo.isVehicleProfileComplete();
  if (!profileComplete) {
    await tts.speak(
      "Veuillez d'abord compléter votre profil véhicule dans la Boîte à gants.",
    );
    service.stopSelf();
    return;
  }

  await _updateNotification(notifications, "Surveillance en cours...");

  int noConnectionCounter = 0;
  const maxNoConnectionTicks = 12; // 12 × 5s = 60 secondes
  int lastVoiceAlertTimestamp = 0;
  const voiceCooldownMs = 30000; // 30 secondes entre deux alertes

  // Boucle principale : s'exécute toutes les 5 secondes
  while (true) {
    // Vérifier si l'arrêt a été demandé
    final shouldStop = await _checkShouldStop(service);
    if (shouldStop) break;

    // Lire les données OBD (à brancher sur BluetoothObdService)
    final obdData = await _readObdData();

    if (obdData == null) {
      noConnectionCounter++;
      if (noConnectionCounter >= maxNoConnectionTicks) {
        await tts.speak(
          "La connexion avec votre véhicule a été perdue. La surveillance s'arrête.",
        );
        await Future.delayed(const Duration(seconds: 3));
        break;
      }
    } else {
      noConnectionCounter = 0;
      final riskLevel = evaluateRisk(obdData);
      String notifText;
      String? voiceMessage;

      switch (riskLevel) {
        case RiskLevel.green:
          notifText = "Tout va bien — Surveillance active";
          voiceMessage = null;
          break;
        case RiskLevel.orange:
          notifText = "⚠️ Attention recommandée";
          voiceMessage = buildOrangeMessage(obdData);
          await repo.saveDiagnosticSession(DiagnosticSession(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            vehicleProfileId: 'active',
            timestamp: obdData.timestamp,
            riskLevel: RiskLevel.orange,
            dtcCodes: obdData.activeDtcCodes,
            humanSummary: "Surveillance conduite — point d'attention détecté",
          ));
          break;
        case RiskLevel.red:
          notifText = "🔴 Point d'attention important";
          voiceMessage = buildRedMessage(obdData);
          await repo.saveDiagnosticSession(DiagnosticSession(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            vehicleProfileId: 'active',
            timestamp: obdData.timestamp,
            riskLevel: RiskLevel.red,
            dtcCodes: obdData.activeDtcCodes,
            humanSummary: "Surveillance conduite — point d'attention important détecté",
          ));
          break;
      }

      await _updateNotification(notifications, notifText);

      // Alerte vocale avec cooldown (pas de répétition avant 30 secondes)
      if (voiceMessage != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastVoiceAlertTimestamp >= voiceCooldownMs) {
          await tts.speak(voiceMessage);
          lastVoiceAlertTimestamp = now;
        }
      }
    }

    await Future.delayed(const Duration(seconds: 5));
  }

  // Nettoyage à l'arrêt
  await _dismissNotification(notifications);
  service.stopSelf();
}

// ─────────────────────────────────────────────
// GESTIONNAIRE DU SERVICE (interface publique)
// À utiliser depuis l'application pour démarrer / arrêter la surveillance
// ─────────────────────────────────────────────

class MonitoringServiceManager {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Configure le service au démarrage de l'application.
  /// À appeler une seule fois dans main().
  static Future<void> initialize() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: monitoringBackgroundMain,
        autoStart: false,
        isForegroundMode: true,         // Foreground Service Android
        notificationChannelId: 'mab_monitoring_channel',
        initialNotificationTitle: 'Mécano à Bord',
        initialNotificationContent: 'Initialisation de la surveillance...',
        foregroundServiceNotificationId: 1001,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: monitoringBackgroundMain,  // Actif quand l'app est au premier plan
        onBackground: _onIosBackground,          // Tâche courte quand l'app est en fond
      ),
    );
  }

  /// Démarre la surveillance en arrière-plan.
  /// [voiceGender] : "FEMININE" ou "MASCULINE"
  static Future<void> startMonitoring({String voiceGender = 'FEMININE'}) async {
    await _service.startService();
    _service.invoke('startMonitoring', {'voiceGender': voiceGender});
  }

  /// Arrête la surveillance en arrière-plan.
  static Future<void> stopMonitoring() async {
    _service.invoke('stopMonitoring');
  }

  /// Vérifie si la surveillance est en cours.
  static Future<bool> isRunning() async {
    return await _service.isRunning();
  }
}

// ─────────────────────────────────────────────
// FONCTIONS UTILITAIRES PRIVÉES
// ─────────────────────────────────────────────

/// Callback iOS requis pour le mode arrière-plan.
/// Sur iOS, les tâches en fond sont limitées et courtes.
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

/// Initialise le gestionnaire de notifications locales.
Future<void> _initNotifications(FlutterLocalNotificationsPlugin plugin) async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  await plugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );
}

/// Met à jour le texte de la notification permanente.
Future<void> _updateNotification(
  FlutterLocalNotificationsPlugin plugin,
  String text,
) async {
  const androidDetails = AndroidNotificationDetails(
    'mab_monitoring_channel',
    'Surveillance Mécano à Bord',
    channelDescription: 'Surveillance active de votre véhicule',
    importance: Importance.low,
    priority: Priority.low,
    ongoing: true,           // Non supprimable
    playSound: false,
    enableVibration: false,
  );
  const iosDetails = DarwinNotificationDetails(
    presentSound: false,
  );
  await plugin.show(
    1001,
    'Mécano à Bord — Surveillance active',
    text,
    const NotificationDetails(android: androidDetails, iOS: iosDetails),
  );
}

/// Supprime la notification à l'arrêt du service.
Future<void> _dismissNotification(FlutterLocalNotificationsPlugin plugin) async {
  await plugin.cancel(1001);
}

/// Lit les données OBD depuis le boîtier ELM327.
/// À brancher sur BluetoothObdService lors de l'intégration.
Future<ObdData?> _readObdData() async {
  // TODO : appeler BluetoothObdService.readCurrentData() ici
  // Retourner null si aucune connexion active
  return null;
}

/// Vérifie si l'arrêt du service a été demandé.
Future<bool> _checkShouldStop(FlutterBackgroundService service) async {
  // Dans flutter_background_service, l'arrêt est géré via stopSelf()
  return !(await service.isRunning());
}
