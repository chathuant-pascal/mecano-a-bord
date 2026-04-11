import 'package:flutter/material.dart';

/// Filigrane centré (opacité par défaut 0,45).
class MabWatermarkBackground extends StatelessWidget {
  final Widget child;

  /// Image affichée en filigrane (défaut : marque MAB).
  final String assetPath;

  /// Opacité du filigrane (défaut 0,45 — plus lisible qu’à 0,38).
  final double watermarkOpacity;

  /// Si non null (ex. `0.85`), la boîte du filigrane fait [largeur écran × cette valeur]
  /// en largeur et hauteur (carré), centrée. Si null : 320×320 dp (comportement historique).
  final double? watermarkWidthFraction;

  const MabWatermarkBackground({
    super.key,
    required this.child,
    this.assetPath = 'assets/images/logo_mark.png',
    this.watermarkOpacity = 0.45,
    this.watermarkWidthFraction,
  });

  @override
  Widget build(BuildContext context) {
    // StackFit.expand + Positioned.fill sur le contenu : sans cela, le child peut
    // recevoir des contraintes de hauteur incorrectes et provoquer un overflow
    // vertical (ex. Column dans RefreshIndicator / SingleChildScrollView).
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: watermarkOpacity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fraction = watermarkWidthFraction;
                  final double side = fraction != null
                      ? constraints.maxWidth * fraction
                      : 320.0;
                  return Center(
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

