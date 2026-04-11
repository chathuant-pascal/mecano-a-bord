import 'package:flutter/material.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';

class MabLogo extends StatelessWidget {
  final double size;
  final bool withText;

  const MabLogo({
    super.key,
    this.size = 160,
    this.withText = true,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      withText
          ? 'assets/images/logo.png'
          : 'assets/images/logo_mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (!withText) {
      return logo;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(height: MabDimensions.espacementM),
        Text(
          'Mécano à Bord',
          style: MabTextStyles.titreApp,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

