# FICHE MODULE 01 — DIAGNOSTIC OBD

**Statut** : ✅ **Validé le 19/04/2026**  
**Statut final** : ✅ **Validé le 19/04/2026** — MODULE 1 diagnostic OBD + chaîne surveillance associée **stables** (terrain).  
**Corrections appliquées** : bouton « Lancer le diagnostic » + verrou surveillance (pas de conflit diagnostic / mode conduite) + abonnements Bluetooth (`StreamSubscription` annulés à la fermeture des écrans) + verrou anti-chevauchement des sondages surveillance (`live_monitoring_service.dart`).  
**Surveillance mode conduite — hystérésis** (`vehicle_health_service.dart`) : appliquée sur les **4 canaux** — **température** (réarmement vocal ≤ 95 °C et logique bande), **tension batterie** (12,5 V / 12,8 V / retour bande), **régime moteur RPM** (retour dans la plage idle `[minB, maxB]`), **pression huile** (&lt; 100 kPa → réarmement &gt; 150 kPa) ; **reset complet** des drapeaux vocaux dans `resetLiveMonitoringWarmupState()` à l’arrêt / redémarrage surveillance.  
**Test confirmé** : connexion immédiate sans blocage, **diagnostic aboutit** sur **Samsung SM-A137F** avec dongle OBD (iCar Pro Vgate).  
**Date diagnostic initial** : 19/04/2026  
**Développeur** : Pascal Chathuant + Claude Code / Cursor

---

## 1. NOM DE LA FONCTIONNALITÉ

**Écran Diagnostic OBD** — Connexion Bluetooth au dongle iCar Pro Vgate + lecture des codes défaut du véhicule

---

## 2. RÔLE EN LANGAGE SIMPLE

Cet écran permet à l'utilisateur de connecter son téléphone à un petit boîtier électronique (le dongle OBD) branché sur sa voiture. Une fois connecté, l'application interroge la voiture pour récupérer ses codes défaut — comme un mécanicien qui branche sa valise de diagnostic. L'application affiche ensuite un résultat en vert (tout va bien), orange (problème mineur) ou rouge (problème critique), et peut annoncer le résultat à voix haute. Si c'est la toute première connexion pour ce véhicule, l'application doit d'abord tester 10 protocoles différents pour trouver celui que comprend la voiture — c'est normal et ne se fait qu'une seule fois.

---

## 3. FICHIERS CONCERNÉS

| Fichier | Rôle |
|---|---|
| `lib/screens/obd_scan_screen.dart` | Écran principal — interface utilisateur + machine à états |
| `lib/services/bluetooth_obd_service.dart` | Service Bluetooth — connexion SPP + envoi des commandes OBD |
| `lib/services/obd_session_coordinator.dart` | Coordinateur — évite les conflits avec le Mode Conduite |
| `lib/services/live_monitoring_service.dart` | Surveillance temps réel — bloque le diagnostic si actif |
| `lib/services/vehicle_health_service.dart` | Alertes graduées mode conduite + **hystérésis vocale** sur les 4 canaux (température, batterie, RPM, huile) |
| `lib/widgets/mab_obd_session_dialogs.dart` | Dialogues — "diagnostic bloqué par surveillance", "effacer codes" |
| `lib/widgets/mab_obd_not_responding_dialog.dart` | Dialogue — "OBD ne répond pas, relancer ?" |
| `lib/data/mab_repository.dart` | Accès données — profil véhicule, historique diagnostics |

---

## 4. RÈGLES INTOUCHABLES

Ces règles ne doivent **jamais** être modifiées sans accord explicite de Pascal.

```
RÈGLE 1 — La voix TTS (annonce "OBD connecté") doit rester :
           pitch : 1.2 / speechRate : 0.5
           Fichier : lib/services/tts_service.dart

RÈGLE 2 — Les mots suivants sont INTERDITS dans tous les messages :
           ❌ "panne"  ❌ "danger"  ❌ "défaillance"
           ✅ Remplacer par : "problème détecté", "vérification nécessaire"

RÈGLE 3 — Le design doit utiliser UNIQUEMENT :
           MabColors / MabTextStyles / MabDimensions
           (lib/theme/mab_theme.dart)

RÈGLE 4 — Zones tactiles : minimum 48dp sur chaque bouton

RÈGLE 5 — Le dongle supporté est le iCar Pro Vgate (Bluetooth CLASSIQUE, protocole SPP)
           Ce n'est PAS du Bluetooth BLE — ne pas mélanger les deux

RÈGLE 6 — Le canal natif Android s'appelle : 'com.example.mecano_a_bord/obd'
           (bluetooth_obd_service.dart ligne 109)
           Toute modification du nom de canal doit être faite SIMULTANÉMENT
           côté Flutter ET côté Android natif (MainActivity.kt)
```

---

## 5. ARCHITECTURE — MACHINE À ÉTATS OBD

L'écran fonctionne selon une séquence d'états précise :

```
ObdDisconnected
      ↓  (tap sur un appareil ou auto-connect)
ObdConnecting          ← overlay "Connexion en cours" + compte à rebours 15s
      ↓  (connexion SPP + ATZ réussie)
      ↓─── VIN connu du natif ──────────→ ObdConnected
      ↓─── VIN inconnu (1ère fois) ─────→ ObdConnectedNeedsProtocolDetection
                                                    ↓  (_startProtocolDetection)
                                                    ↓  (10 protocoles testés)
                                               ObdConnected
                                                    ↓  (_readVehicleData)
                                               Résultat : vert / orange / rouge / incomplet
```

---

## 6. BUGS DIAGNOSTIQUÉS (corrections à venir)

### BUG-1 🔴 CAUSE PROBABLE DU CRASH — Future non protégée

**Fichier** : `obd_scan_screen.dart` ligne 135  
**Gravité** : Bloquant — crash intermittent  

```dart
// PROBLÈME : _startProtocolDetection est async mais appelée sans await ni unawaited
if (state is ObdConnectedNeedsProtocolDetection && !_protocolDetectionInProgress) {
  _startProtocolDetection(state.deviceName);   // ← Future non protégée
}
```

Si `_startProtocolDetection()` lève une exception qui n'est pas `ObdScanException` (ex. `MissingPluginException` du canal Bluetooth natif), cette exception n'est pas attrapée → **crash brutal**. L'aspect **intermittent** s'explique : le crash ne se produit que lors de la première connexion d'un VIN (seul moment où `ObdConnectedNeedsProtocolDetection` est émis).

**Correction à faire** : Envelopper l'appel dans `unawaited()` + ajouter un `catch` général dans `_startProtocolDetection()`.

---

### BUG-2 🔴 VIN vide → écran bloqué sans message d'erreur

**Fichier** : `obd_scan_screen.dart` lignes 248-250  
**Gravité** : Bloquant (si VIN absent)  

```dart
final vin = profile?.vin ?? '';
if (vin.isEmpty || !mounted) return;  // ← Retour silencieux sans message
```

Si le VIN n'est pas renseigné, la détection de protocole ne se lance jamais. L'écran reste bloqué sur "Adaptation au véhicule" indéfiniment. Aucun message d'erreur affiché.

**Correction à faire** : Afficher un message clair + passer l'état à `ObdError`.  
**Note** : Ce bug ne s'applique pas au cas de Pascal (VIN renseigné).

---

### BUG-3 🔴 `ObdConnected` forcé même si aucun protocole trouvé

**Fichier** : `obd_scan_screen.dart` lignes 285-296  
**Gravité** : UX incorrecte  

```dart
// L'état passe à ObdConnected même si found=false
setState(() {
  _state = ObdConnected(deviceName);
});
```

Après 10 protocoles échoués, l'état devrait indiquer une erreur — pas "Connecté". L'interface affiche un message d'erreur dans la liste mais l'état en haut indique "Connecté", ce qui est contradictoire.

**Correction à faire** : Si `found=false`, émettre `ObdError` au lieu de `ObdConnected`.

---

### BUG-4 🟠 Abonnement stream jamais annulé — ✅ **Corrigé (19/04/2026)**

**Fichier** : `obd_scan_screen.dart` / `home_screen.dart` — `StreamSubscription` stockée et `cancel()` dans `dispose()`.  
**Gravité** (historique) : Fuite mémoire + risque setState sur widget détruit  

```dart
// Dans initState() — l'abonnement n'est jamais stocké
_obdService.connectionState.listen((state) { ... });

// Dans dispose() — rien n'est annulé
@override
void dispose() {
  _connectingTimer?.cancel();
  _pulseController.dispose();
  _obdService.dispose();   // ← BluetoothObdService.dispose() ne fait RIEN
  super.dispose();
}
```

L'abonnement au stream reste actif même après que l'écran est fermé. Le check `if (!mounted) return` protège partiellement, mais ne couvre pas les chemins `unawaited()` internes.

**Correction à faire** : Stocker la `StreamSubscription` et l'annuler dans `dispose()`.

---

### BUG-5 🟠 `_autoConnectFromLoadStarted` jamais réinitialisé

**Fichier** : `obd_scan_screen.dart` ligne 64  
**Gravité** : Code fragile  

Ce flag est mis à `true` au premier chargement et n'est jamais remis à `false`. La séquence de retry (`_retryAutoDiagnostic`) contourne ce problème en appelant `_runAutoConnectSequence()` directement. Mais si `_loadDevices()` est rappelé depuis le bouton "Rafraîchir", la connexion auto ne se relance pas.

**Correction à faire** : Remettre le flag à `false` au début de chaque tentative de retry.

---

### BUG-6 🟡 3 labels pour 4 étapes de lecture

**Fichier** : `bluetooth_obd_service.dart` lignes 325-329  
**Gravité** : Cosmétique  

3 labels de phase mais la lecture compte 4 étapes. La 4ème étape (codes permanents) affiche le même texte que la 3ème. Pas de crash — juste un texte de progression inexact.

**Correction à faire** : Ajouter un 4ème label `'Lecture des codes permanents...'`.

---

### BUG-7 🔴 debugPrint données OBD brutes (sécurité)

**Fichier** : `bluetooth_obd_service.dart` ligne 313  
**Gravité** : Sécurité — visible en production  

```dart
debugPrint('OBD protocole $i: réponse brute = $rawResponse');
```

Les réponses ELM327 brutes sont visibles dans logcat même en release. À corriger dans MODULE 5 avec `mabLog()`.

---

## 7. TESTS À FAIRE sur Samsung SM-A137F

Après correction, valider ces 6 scénarios :

```
TEST 1 — Connexion normale (protocole déjà connu)
  • Brancher le dongle, allumer le contact
  • Ouvrir l'écran OBD depuis l'accueil
  → Attendu : "OBD connecté" annoncé à voix haute + résultat en vert/orange/rouge

TEST 2 — Première connexion (nouveau VIN)
  • Effacer le protocole sauvegardé (resetObdNativePrefs)
  • Brancher le dongle
  → Attendu : message "Premier branchement" + progression 1/10 à 10/10 + résultat final

TEST 3 — Dongle absent
  • Ouvrir l'écran sans dongle branché
  → Attendu : dialogue "OBD ne répond pas" + bouton "Relancer"

TEST 4 — Bluetooth désactivé
  • Désactiver le Bluetooth du téléphone
  • Ouvrir l'écran OBD
  → Attendu : message "Bluetooth désactivé" (pas de mot "panne")

TEST 5 — Retour après crash (robustesse)
  • Déclencher plusieurs connexions/déconnexions rapides
  → Attendu : pas de crash, état correct à chaque fois

TEST 6 — Mode démo
  • Activer le mode démo dans les réglages
  • Ouvrir l'écran OBD
  → Attendu : 3 scénarios disponibles (vert / orange / rouge)
```

---

## 8. STATUT

| Étape | Statut |
|---|---|
| Diagnostic complet du code | ✅ Fait |
| Logcat sur Samsung SM-A137F | ✅ Fait (filtrage MecanoOBD / flutter) |
| Corrections MODULE 1 (bouton, surveillance, abonnements BT, sondages) | ✅ Fait |
| Tests sur Samsung SM-A137F | ✅ Fait — diagnostic aboutit |
| Validation Pascal | ✅ **19/04/2026** |
| Sauvegarde / commit GitHub | ✅ Fait |
| Warning `_protocolDetectionDeviceName` inutilisé (`obd_scan_screen.dart:61`) | ⏳ À corriger avec Cursor |

---

---

## 9. CONDITIONS DE TEST RÉALISÉES PAR PASCAL

### 1. MATÉRIEL UTILISÉ

| Élément | Détail |
|---|---|
| Téléphone | Samsung SM-A137F — Android 14 |
| Dongle OBD | iCar Pro Vgate (Bluetooth classique SPP) |
| Connexion | USB PC pour logcat + Bluetooth téléphone/dongle |
| Voiture | À compléter (marque/modèle/année) |

### 2. ENVIRONNEMENT DE TEST

- Téléphone branché en USB sur le PC
- Logcat actif pendant le test (`adb logcat flutter:V AndroidRuntime:E *:S`)
- Dongle OBD branché sur la prise OBD de la voiture
- Contact mis sur la voiture
- WiFi PC actif pendant le test

### 3. PROCÉDURE SUIVIE

1. Ouverture de l'app Mécano à Bord sur le Samsung
2. Vérification que le profil véhicule est actif (VIN de 17 caractères renseigné ✅)
3. Appui sur le bouton "Diagnostic OBD" depuis l'accueil (`autoStartDiagnostic=true`)
4. Attente de la connexion Bluetooth au dongle iCar Pro Vgate
5. Observation du crash — fermeture brutale de l'app

### 4. RÉSULTAT OBSERVÉ (session matin — investigation crash)

**Comportement constaté initialement :**
- Crash intermittent possible lors de la première adaptation protocole ; analyse code (BUG-1 à 7) documentée en section 6.

### 4 bis. RÉSULTAT FINAL — VALIDATION 19/04/2026

**Comportement constaté après corrections MODULE 1 :**
- **Connexion** au dongle : **immédiate, sans blocage**
- **Diagnostic** : **fonctionne**, résultat obtenu (Samsung **SM-A137F**, dongle OBD branché, contact mis)
- **Logcat** : commande `adb` avec filtre `MecanoOBD` / `flutter` utilisée pour le suivi

### 5. DATE DU TEST

| Élément | Détail |
|---|---|
| Date validation MODULE 1 | **19/04/2026** |
| Version app | 1.0.0+14 (référence terrain) |
| Statut | ✅ **MODULE 1 validé** — diagnostic OBD opérationnel sur SM-A137F |

---

*Fiche mise à jour le 19/04/2026 — MODULE 1 validé*
