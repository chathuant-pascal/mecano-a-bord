/// État léger pour le mode AUTO : évite de relancer la surveillance après un arrêt manuel
/// tant que le dongle reste connecté (sans déconnexion physique).
class SurveillanceAutoGate {
  SurveillanceAutoGate._();

  static bool blockAutoResumeUntilReconnect = false;

  static void userStoppedManually() {
    blockAutoResumeUntilReconnect = true;
  }

  static void clearedOnPhysicalDisconnect() {
    blockAutoResumeUntilReconnect = false;
  }

  static void onUserOrAutoStartedMonitoring() {
    blockAutoResumeUntilReconnect = false;
  }
}
