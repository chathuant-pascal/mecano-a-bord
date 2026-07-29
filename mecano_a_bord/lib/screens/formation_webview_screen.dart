// Formation « Ta Voiture Sans Galère » — WebView interne (post-onboarding).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/formation_url.dart';
import 'package:mecano_a_bord/screens/home_screen.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Hôtes autorisés à s’afficher dans la WebView (MODULE 4 — OWASP).
bool _isAllowedFormationHost(String? host) {
  if (host == null || host.isEmpty) return false;
  final h = host.toLowerCase();
  if (h == 'mecanoabord.fr' || h.endsWith('.mecanoabord.fr')) return true;
  if (h == 'chathuant-pascal.github.io') return true;
  return false;
}

class FormationWebViewScreen extends StatefulWidget {
  const FormationWebViewScreen({super.key});

  @override
  State<FormationWebViewScreen> createState() => _FormationWebViewScreenState();
}

class _FormationWebViewScreenState extends State<FormationWebViewScreen>
    with WidgetsBindingObserver {
  static const String _kFormationDoneKey = 'formation_done';

  /// Lit la position de lecture dans la page (une seule longue page, modules en sections).
  static const String _kScrollProgressJs = '''
    (function() {
      var d = document.documentElement;
      var b = document.body;
      var scrollTop = d.scrollTop || b.scrollTop || 0;
      var scrollable = Math.max(d.scrollHeight || 0, b.scrollHeight || 0) - d.clientHeight;
      if (scrollable <= 0) return 100;
      return Math.min(100, Math.round((scrollTop / scrollable) * 100));
    })();
  ''';

  late final WebViewController _controller;
  Timer? _pollTimer;
  bool _navigated = false;
  bool _loadError = false;
  bool _pageLoading = true;
  /// Avancement de lecture (0-100), déduit du scroll de la page formation.
  /// Ne redescend jamais : remonter dans la page pour relire ne doit pas faire reculer la barre.
  double _progressPercent = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'MABFormation',
        onMessageReceived: (JavaScriptMessage message) async {
          final text = message.message.trim().toLowerCase();
          if (text == 'done' || text == '1' || text == 'true') {
            final current = await _controller.currentUrl();
            final pageUri = current != null ? Uri.tryParse(current) : null;
            final scheme = pageUri?.scheme.toLowerCase();
            final trusted = pageUri != null &&
                (scheme == 'https' || scheme == 'http') &&
                _isAllowedFormationHost(pageUri.host);
            if (!trusted) return;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_kFormationDoneKey, true);
            if (mounted) await _checkFormationDone();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            final scheme = uri.scheme.toLowerCase();
            if (scheme != 'https' && scheme != 'http') {
              return NavigationDecision.prevent;
            }
            if (_isAllowedFormationHost(uri.host)) {
              return NavigationDecision.navigate;
            }
            try {
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            } catch (_) {}
            return NavigationDecision.prevent;
          },
          onPageStarted: (String url) {
            if (!mounted) return;
            setState(() {
              _pageLoading = true;
            });
          },
          onPageFinished: (String url) {
            if (!mounted) return;
            setState(() {
              _pageLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame == false) return;
            if (!mounted) return;
            setState(() {
              _loadError = true;
              _pageLoading = false;
            });
          },
        ),
      );

    unawaited(_loadFormationPage());

    _startPollTimer();
  }

  void _startPollTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkFormationDone();
      unawaited(_updateProgress());
    });
  }

  /// Déduit l'avancement de lecture du scroll de la page (une seule longue page,
  /// modules en sections). Ne fait jamais reculer la barre.
  Future<void> _updateProgress() async {
    if (!mounted || _pageLoading) return;
    try {
      final result =
          await _controller.runJavaScriptReturningResult(_kScrollProgressJs);
      final value = num.tryParse(result.toString());
      if (value == null || !mounted) return;
      final clamped = value.clamp(0, 100).toDouble();
      if (clamped > _progressPercent) {
        setState(() => _progressPercent = clamped);
      }
    } catch (_) {
      // Page pas encore prête ou navigation en cours : on garde la dernière valeur connue.
    }
  }

  Future<void> _loadFormationPage({bool retry = false}) async {
    if (retry && mounted) {
      setState(() {
        _loadError = false;
        _pageLoading = true;
      });
    }
    try {
      final uri = Uri.parse(kFormationUrl);
      await _controller.loadRequest(uri);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = true;
        _pageLoading = false;
      });
    }
  }

  Future<void> _checkFormationDone() async {
    if (_navigated || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_kFormationDoneKey) ?? false;
    if (!done) return;
    _navigated = true;
    _pollTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _pollTimer?.cancel();
        _pollTimer = null;
        break;
      case AppLifecycleState.resumed:
        _startPollTimer();
        unawaited(_checkFormationDone());
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _pollTimer?.cancel();
        _pollTimer = null;
        break;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      appBar: AppBar(
        backgroundColor: MabColors.noir,
        title: const Text(
          'Ta Voiture Sans Galère',
          style: MabTextStyles.titreSection,
        ),
      ),
      body: _loadError
          ? Center(
              child: Padding(
                padding: MabDimensions.paddingEcran,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'La page n’a pas pu se charger. '
                      'Vérifie ta connexion internet, puis touche « Réessayer ». '
                      'L’application va simplement recharger la formation.',
                      style: MabTextStyles.corpsNormal,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: MabDimensions.espacementL),
                    ElevatedButton(
                      onPressed: () {
                        unawaited(_loadFormationPage(retry: true));
                      },
                      child: const Text(
                        'Réessayer',
                        style: MabTextStyles.boutonPrincipal,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProgressBar(),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_pageLoading)
                        Positioned.fill(
                          child: ColoredBox(
                            color: MabColors.noir.withValues(alpha: 0.45),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: MabColors.rouge,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildLockedPreviewStrip(),
              ],
            ),
    );
  }

  /// Barre de progression permanente, déduite de la lecture de la formation.
  Widget _buildProgressBar() {
    return Container(
      color: MabColors.noirMoyen,
      padding: const EdgeInsets.symmetric(
        horizontal: MabDimensions.espacementM,
        vertical: MabDimensions.espacementS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(MabDimensions.rayonPetit),
            child: LinearProgressIndicator(
              value: _progressPercent / 100,
              minHeight: 6,
              backgroundColor: MabColors.noirClair,
              valueColor: const AlwaysStoppedAnimation<Color>(MabColors.rouge),
            ),
          ),
          const SizedBox(height: MabDimensions.espacementXS),
          Text(
            '${_progressPercent.round()}% de la formation lue',
            style: MabTextStyles.label.copyWith(color: MabColors.grisTexte),
          ),
        ],
      ),
    );
  }

  /// Aperçu grisé des écrans qui se débloquent une fois la formation terminée.
  Widget _buildLockedPreviewStrip() {
    return Container(
      color: MabColors.noirMoyen,
      padding: const EdgeInsets.symmetric(
        horizontal: MabDimensions.espacementM,
        vertical: MabDimensions.espacementS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ce qui vous attend une fois la formation terminée',
            style: MabTextStyles.label.copyWith(color: MabColors.grisTexte),
          ),
          const SizedBox(height: MabDimensions.espacementS),
          const Row(
            children: [
              Expanded(
                child: _LockedPreviewTile(
                  asset: 'assets/images/modeconduite.png',
                  label: 'Mode Conduite',
                ),
              ),
              SizedBox(width: MabDimensions.espacementS),
              Expanded(
                child: _LockedPreviewTile(
                  asset: 'assets/images/suv_images.png',
                  label: 'Diagnostic OBD',
                ),
              ),
              SizedBox(width: MabDimensions.espacementS),
              Expanded(
                child: _LockedPreviewTile(
                  asset: 'assets/images/boite_a_gant.png',
                  label: 'Boîte à gants',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vignette grisée (icône + libellé) d'un écran encore verrouillé, avec cadenas
/// en surimpression — aperçu de ce que la formation débloque à la fin.
class _LockedPreviewTile extends StatelessWidget {
  const _LockedPreviewTile({required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Opacity(
                  opacity: 0.45,
                  child: Image.asset(
                    asset,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: MabColors.noirClair,
                    ),
                  ),
                ),
              ),
            ),
            const Icon(
              Icons.lock_outline_rounded,
              color: MabColors.blanc,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: MabDimensions.espacementXS),
        Text(
          label,
          textAlign: TextAlign.center,
          style: MabTextStyles.label.copyWith(color: MabColors.grisTexte),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
