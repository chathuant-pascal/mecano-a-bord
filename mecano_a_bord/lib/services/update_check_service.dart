// update_check_service.dart — Mécano à Bord
// Vérification silencieuse d’une nouvelle version (APK hors Play Store) via JSON distant.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// URL du fichier JSON (GitHub Pages, Systeme.io, etc.). À aligner avec le fichier réellement hébergé.
const String kMabVersionCheckJsonUrl =
    'https://mecanoabord.systeme.io/version.json';

/// Données lues depuis le JSON distant.
class RemoteVersionInfo {
  const RemoteVersionInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.message,
  });

  final String latestVersion;
  final String downloadUrl;
  final String message;
}

/// Compare deux versions du type "1.2.3" (segments numériques). Retour &gt; 0 si [a] &gt; [b].
int compareSemverStrings(String a, String b) {
  final pa = a.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
  final pb = b.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
  final len = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < len; i++) {
    final va = i < pa.length ? pa[i] : 0;
    final vb = i < pb.length ? pb[i] : 0;
    if (va != vb) return va.compareTo(vb);
  }
  return 0;
}

/// Service : une vérification à la fois (évite double dialogue si l’accueil se reconstruit vite).
class UpdateCheckService {
  UpdateCheckService._();
  static final UpdateCheckService instance = UpdateCheckService._();

  bool _checkInProgress = false;

  /// Au démarrage de l’accueil : requête HTTP silencieuse ; en cas d’échec ou pas de réseau, ne rien faire.
  Future<void> checkForUpdateAndPromptIfNeeded(BuildContext context) async {
    if (_checkInProgress) return;
    _checkInProgress = true;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final remote = await _fetchRemoteVersionInfo();
      if (remote == null) return;

      if (compareSemverStrings(remote.latestVersion, currentVersion) <= 0) {
        return;
      }

      if (!context.mounted) return;
      await _showUpdateDialog(context, remote);
    } catch (_) {
      // Pas de connexion, JSON invalide, etc. : démarrage normal, aucun message.
    } finally {
      _checkInProgress = false;
    }
  }

  Future<RemoteVersionInfo?> _fetchRemoteVersionInfo() async {
    final uri = Uri.parse(kMabVersionCheckJsonUrl);
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    final latest = decoded['latest_version']?.toString().trim();
    final url = decoded['download_url']?.toString().trim();
    if (latest == null ||
        latest.isEmpty ||
        url == null ||
        url.isEmpty) {
      return null;
    }
    final msg = decoded['message']?.toString().trim();
    return RemoteVersionInfo(
      latestVersion: latest,
      downloadUrl: url,
      message: (msg != null && msg.isNotEmpty)
          ? msg
          : 'Une nouvelle version de Mécano à Bord est disponible.',
    );
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    RemoteVersionInfo info,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: MabColors.noirMoyen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MabDimensions.rayonGrand),
            side: const BorderSide(color: MabColors.grisContour),
          ),
          title: Text(
            'Une nouvelle version est disponible 🎉',
            style: MabTextStyles.titreCard.copyWith(color: MabColors.blanc),
          ),
          content: SingleChildScrollView(
            child: Text(
              info.message,
              style: MabTextStyles.corpsNormal.copyWith(
                color: MabColors.grisTexte,
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Plus tard',
                style: MabTextStyles.boutonSecondaire.copyWith(
                  color: MabColors.grisTexte,
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final uri = Uri.tryParse(info.downloadUrl);
                if (uri != null) {
                  try {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {}
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: MabColors.rouge,
                foregroundColor: MabColors.blanc,
                minimumSize: const Size(
                  MabDimensions.zoneTactileMin,
                  MabDimensions.boutonHauteur,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(MabDimensions.rayonBouton),
                ),
              ),
              child: Text(
                'Mettre à jour',
                style: MabTextStyles.boutonPrincipal.copyWith(
                  color: MabColors.blanc,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
