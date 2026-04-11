// obd_session_coordinator.dart — Exclusion mutuelle diagnostic OBD complet ↔ surveillance temps réel.

/// Un seul usage « maître » du socket OBD à la fois côté logique métier.
class ObdSessionCoordinator {
  ObdSessionCoordinator._();

  /// Surveillance Mode conduite en cours (lecture PID live).
  static bool liveMonitoringActive = false;

  /// Diagnostic complet (détection protocole + lecture 0101/03/07/0A) en cours.
  static bool diagnosticRunning = false;
}
