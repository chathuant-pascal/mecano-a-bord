// Formation « Ta Voiture Sans Galère » — WebView interne (post-onboarding).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/formation_url.dart';
import 'package:mecano_a_bord/screens/home_screen.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FormationWebViewScreen extends StatefulWidget {
  const FormationWebViewScreen({super.key});

  @override
  State<FormationWebViewScreen> createState() => _FormationWebViewScreenState();
}

class _FormationWebViewScreenState extends State<FormationWebViewScreen>
    with WidgetsBindingObserver {
  static const String _kFormationDoneKey = 'formation_done';

  late final WebViewController _controller;
  Timer? _pollTimer;
  bool _navigated = false;

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
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_kFormationDoneKey, true);
            if (mounted) await _checkFormationDone();
          }
        },
      )
      ..loadRequest(Uri.parse(kFormationUrl));

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkFormationDone();
    });
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
    if (state == AppLifecycleState.resumed) {
      _checkFormationDone();
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
      body: WebViewWidget(controller: _controller),
    );
  }
}
