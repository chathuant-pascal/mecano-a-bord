// firebase_licence_manager.dart
// Mécano à Bord — Version Flutter/Dart (Android + iOS)
//
// Gère l'authentification Firebase et la protection de la licence.
//
// RÈGLES NON NÉGOCIABLES :
//   - La vérification de licence se fait TOUJOURS côté serveur (Firebase)
//   - Les fonctions premium ne sont JAMAIS débloquées uniquement en local
//   - Maximum 2 appareils par licence
//   - Un identifiant unique par appareil (anti-copie)

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// MODÈLES DE DONNÉES
// ─────────────────────────────────────────────

/// État de la licence de l'utilisateur.
enum LicenceStatus {
  active,           // Licence valide, toutes les fonctions disponibles
  inactive,         // Pas de licence (mode gratuit limité)
  appareilLimite,   // Déjà 2 appareils enregistrés sur ce compte
  expiree,          // Licence expirée
  erreurReseau,     // Impossible de vérifier — mode dégradé
}

/// Résultat complet de la vérification de licence.
class LicenceInfo {
  final LicenceStatus status;
  final String userId;
  final String deviceId;
  final int nbAppareils;
  final int maxAppareils;
  final int? dateActivation;
  final String messageUtilisateur;

  const LicenceInfo({
    required this.status,
    this.userId = '',
    this.deviceId = '',
    this.nbAppareils = 0,
    this.maxAppareils = 2,
    this.dateActivation,
    this.messageUtilisateur = '',
  });
}

/// Résultat d'une tentative de connexion.
sealed class AuthResult {
  const AuthResult();
}

class AuthSucces extends AuthResult {
  final User user;
  const AuthSucces(this.user);
}

class AuthEchec extends AuthResult {
  final String messageErreur;
  const AuthEchec(this.messageErreur);
}

// ─────────────────────────────────────────────
// GESTIONNAIRE D'AUTHENTIFICATION
// ─────────────────────────────────────────────

class FirebaseAuthManager {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Connexion avec email et mot de passe.
  Future<AuthResult> connecter(String email, String motDePasse) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
      final user = result.user;
      if (user != null) return AuthSucces(user);
      return const AuthEchec('Connexion impossible. Vérifie tes identifiants.');
    } on FirebaseAuthException catch (e) {
      return AuthEchec(_traduitErreurAuth(e.code));
    } catch (e) {
      return const AuthEchec('Une erreur est survenue. Réessaie dans quelques instants.');
    }
  }

  /// Création d'un nouveau compte.
  Future<AuthResult> creerCompte(String email, String motDePasse) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
      final user = result.user;
      if (user != null) return AuthSucces(user);
      return const AuthEchec('Création du compte impossible. Réessaie plus tard.');
    } on FirebaseAuthException catch (e) {
      return AuthEchec(_traduitErreurAuth(e.code));
    } catch (e) {
      return const AuthEchec('Une erreur est survenue. Réessaie dans quelques instants.');
    }
  }

  /// Déconnexion.
  Future<void> deconnecter() async {
    await _auth.signOut();
  }

  /// Utilisateur actuellement connecté.
  User? get utilisateurActuel => _auth.currentUser;

  /// Vérifie si un utilisateur est connecté.
  bool get estConnecte => _auth.currentUser != null;

  /// Envoi d'un email de réinitialisation du mot de passe.
  Future<bool> reinitialiserMotDePasse(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stream de l'état de connexion (pour écouter les changements en temps réel).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Traduit les codes d'erreur Firebase en français simple.
  String _traduitErreurAuth(String code) {
    return switch (code) {
      'wrong-password' => 'Mot de passe incorrect.',
      'user-not-found' => 'Aucun compte trouvé avec cet email.',
      'email-already-in-use' => 'Un compte existe déjà avec cet email.',
      'weak-password' => 'Le mot de passe doit contenir au moins 6 caractères.',
      'invalid-email' => "L'adresse email n'est pas valide.",
      'network-request-failed' =>
        'Pas de connexion internet. Vérifie ta connexion.',
      _ => 'Une erreur est survenue. Réessaie dans quelques instants.',
    };
  }
}

// ─────────────────────────────────────────────
// GESTIONNAIRE DE LICENCE
// ─────────────────────────────────────────────

class LicenceManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeviceIdManager _deviceIdManager;

  LicenceManager({required DeviceIdManager deviceIdManager})
      : _deviceIdManager = deviceIdManager;

  /// Vérifie la licence de l'utilisateur connecté.
  ///
  /// IMPORTANT : vérification TOUJOURS côté serveur Firebase.
  /// En cas d'erreur réseau → mode dégradé (premium bloqué).
  Future<LicenceInfo> verifierLicence() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const LicenceInfo(
        status: LicenceStatus.inactive,
        messageUtilisateur:
            'Connecte-toi pour accéder à toutes les fonctions.',
      );
    }

    final deviceId = await _deviceIdManager.getDeviceId();

    try {
      final licenceDoc = await _firestore
          .collection('licences')
          .doc(user.uid)
          .get();

      if (!licenceDoc.exists) {
        return LicenceInfo(
          status: LicenceStatus.inactive,
          userId: user.uid,
          deviceId: deviceId,
          messageUtilisateur:
              'Aucune licence trouvée. Achète ta licence sur notre site.',
        );
      }

      final data = licenceDoc.data();
      if (data == null) {
        return LicenceInfo(
          status: LicenceStatus.erreurReseau,
          userId: user.uid,
          messageUtilisateur:
              'Impossible de lire ta licence. Réessaie dans quelques instants.',
        );
      }

      final estActive = data['active'] as bool? ?? false;
      if (!estActive) {
        return LicenceInfo(
          status: LicenceStatus.inactive,
          userId: user.uid,
          messageUtilisateur: "Ta licence n'est pas encore activée.",
        );
      }

      // Vérification du nombre d'appareils
      final appareils = List<String>.from(data['appareils'] ?? []);

      if (!appareils.contains(deviceId) && appareils.length >= 2) {
        return LicenceInfo(
          status: LicenceStatus.appareilLimite,
          userId: user.uid,
          deviceId: deviceId,
          nbAppareils: appareils.length,
          maxAppareils: 2,
          messageUtilisateur:
              'Ta licence est déjà utilisée sur 2 appareils. '
              'Contacte le support pour changer d\'appareil.',
        );
      }

      // Enregistrement de cet appareil s'il est nouveau
      if (!appareils.contains(deviceId)) {
        appareils.add(deviceId);
        await _firestore
            .collection('licences')
            .doc(user.uid)
            .update({'appareils': appareils});
      }

      return LicenceInfo(
        status: LicenceStatus.active,
        userId: user.uid,
        deviceId: deviceId,
        nbAppareils: appareils.length,
        maxAppareils: 2,
        dateActivation: data['dateActivation'] as int?,
      );
    } catch (e) {
      // Erreur réseau → mode dégradé, premium bloqué
      return LicenceInfo(
        status: LicenceStatus.erreurReseau,
        userId: user.uid,
        deviceId: deviceId,
        messageUtilisateur:
            'Connexion au serveur impossible. '
            'Les fonctions premium sont temporairement indisponibles.',
      );
    }
  }

  /// Vérification rapide — retourne true uniquement si la licence est active.
  /// En cas de doute : false. Jamais de déblocage local.
  Future<bool> estLicenceActive() async {
    try {
      final info = await verifierLicence();
      return info.status == LicenceStatus.active;
    } catch (_) {
      return false;
    }
  }

  /// Message à afficher selon l'état de la licence.
  String messageSelonStatut(LicenceStatus status) {
    return switch (status) {
      LicenceStatus.active =>
        'Licence active — Toutes les fonctions sont disponibles.',
      LicenceStatus.inactive =>
        'Mode gratuit — Certaines fonctions sont limitées.',
      LicenceStatus.appareilLimite =>
        'Limite d\'appareils atteinte (2/2). Contacte le support.',
      LicenceStatus.expiree =>
        'Ta licence a expiré. Renouvelle-la sur notre site.',
      LicenceStatus.erreurReseau =>
        'Vérification impossible hors connexion. Reconnecte-toi à internet.',
    };
  }
}

// ─────────────────────────────────────────────
// GESTIONNAIRE D'IDENTIFIANT APPAREIL
// ─────────────────────────────────────────────

/// Génère et conserve un identifiant unique pour chaque appareil.
///
/// Fonctionne sur Android ET iOS grâce à device_info_plus.
class DeviceIdManager {
  static const String _prefKey = 'mab_device_id';

  /// Retourne l'identifiant unique de cet appareil.
  /// Généré une seule fois, stocké localement, stable dans le temps.
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored != null) return stored;

    final rawId = await _getRawDeviceIdentifier();
    final deviceId = _hashSha256(rawId).substring(0, 32);

    await prefs.setString(_prefKey, deviceId);
    return deviceId;
  }

  /// Récupère l'identifiant brut de l'appareil selon la plateforme.
  Future<String> _getRawDeviceIdentifier() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return info.id; // Android ID
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return info.identifierForVendor ?? 'ios_unknown_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (_) {}
    return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Hash SHA-256 — transforme l'ID brut en identifiant anonyme.
  String _hashSha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

// ─────────────────────────────────────────────
// GARDE D'ACCÈS AUX FONCTIONS PREMIUM
// ─────────────────────────────────────────────

/// PremiumGuard — vérifie l'accès avant d'exécuter une action premium.
///
/// Utilisation dans les widgets Flutter :
///
///   final guard = PremiumGuard(licenceManager);
///
///   await guard.executer(
///     action: () async => lancerScanObd(),
///     siBloquer: (status) async => afficherEcranLicence(status),
///   );
class PremiumGuard {
  final LicenceManager _licenceManager;

  PremiumGuard(this._licenceManager);

  /// Exécute l'action uniquement si la licence est active.
  /// Sinon, exécute le bloc de refus avec le statut actuel.
  Future<void> executer({
    required Future<void> Function() action,
    Future<void> Function(LicenceStatus)? siBloquer,
  }) async {
    final info = await _licenceManager.verifierLicence();
    if (info.status == LicenceStatus.active) {
      await action();
    } else {
      await siBloquer?.call(info.status);
    }
  }
}
