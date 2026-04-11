// app_reset_service.dart — Réinitialisation usine : SQLite, secure storage, prefs OBD natives, fichiers, SharedPreferences.

import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mecano_a_bord/data/mab_database.dart';
import 'package:mecano_a_bord/services/bluetooth_obd_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Efface toutes les données locales (sauf le binaire de l’app).
///
/// Ordre : chemins issus de la base → dossiers applicatifs connus → fichier SQLite →
/// [FlutterSecureStorage.deleteAll] → prefs OBD Android → [SharedPreferences.clear].
class AppResetService {
  AppResetService._();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void> _deleteFileSilent(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  static Future<void> _deleteDirSilent(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  /// Réinitialisation complète (à appeler après confirmation utilisateur).
  static Future<void> performFullReset() async {
    final paths = await MabDatabase.instance.getAllReferencedUserFilePaths();
    for (final path in paths) {
      await _deleteFileSilent(path);
    }

    final docDir = await getApplicationDocumentsDirectory();
    await _deleteDirSilent(
      Directory(p.join(docDir.path, 'glovebox_documents')),
    );
    await _deleteDirSilent(
      Directory(p.join(docDir.path, 'vehicle_profile_photos')),
    );

    await MabDatabase.instance.closeAndDeleteDatabaseFile();

    await _secureStorage.deleteAll();

    await BluetoothObdService.resetObdNativePrefs();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
