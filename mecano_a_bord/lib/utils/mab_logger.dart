import 'package:flutter/foundation.dart';

/// Logger conditionnel MAB — MODULE 5
/// Remplace tous les debugPrint() du projet.
/// Actif uniquement en mode debug — silencieux en release.
void mabLog(String message) {
  if (kDebugMode) {
    debugPrint('[MAB] $message');
  }
}
