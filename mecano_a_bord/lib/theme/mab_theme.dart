// ============================================================
// MAB_THEME.DART — Charte graphique Mécano à Bord
// Version 1.0 — 22/02/2026
// Compatible Flutter (Android + iOS)
// Conforme European Accessibility Act (EAA) 2025
// ============================================================

import 'package:flutter/material.dart';

// ------------------------------------------------------------
// COULEURS PRINCIPALES
// ------------------------------------------------------------

class MabColors {
  // Palette identité visuelle 1.0.1
  // Rouge principal / secondaire, noirs et gris métallisé
  static const Color rouge        = Color(0xFFC4161C); // Rouge principal
  static const Color rougeSombre  = Color(0xFFE31E24); // Rouge secondaire (accent / hover)
  static const Color rougeClair   = Color(0xFFFF3333);
  static const Color noir         = Color(0xFF111111); // Noir profond
  static const Color noirMoyen    = Color(0xFF2A2A2A); // Gris anthracite
  static const Color noirClair    = Color(0xFF3D3D3D);
  static const Color grisDore     = Color(0xFFB8A98A); // Gris métallique
  static const Color blanc        = Color(0xFFFFFFFF);
  static const Color blancCasse   = Color(0xFFF5F5F5); // Fond clair
  static const Color diagnosticVert    = Color(0xFF2E7D32);
  static const Color diagnosticOrange  = Color(0xFFE65100);
  static const Color diagnosticRouge   = Color(0xFFB71C1C);
  static const Color diagnosticVertClair   = Color(0xFFE8F5E9);
  static const Color diagnosticOrangeClair = Color(0xFFFBE9E7);
  static const Color diagnosticRougeClair  = Color(0xFFFFEBEE);
  /// Info / phase normale (ex. chauffe moteur) — bleu discret, pas alerte.
  static const Color etatInfo      = Color(0xFF1976D2);
  static const Color grisTexte    = Color(0xFF9E9E9E);
  static const Color grisContour  = Color(0xFF5A5A5A);
  static const Color fondTransparent = Color(0x00000000);
}

// ------------------------------------------------------------
// TYPOGRAPHIE
// ------------------------------------------------------------

class MabTextStyles {
  static const TextStyle titrePrincipal = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: MabColors.blanc,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle titreSection = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: MabColors.blanc,
    letterSpacing: 0.3,
    height: 1.3,
  );

  static const TextStyle titreCard = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: MabColors.blanc,
    height: 1.4,
  );

  static const TextStyle corpsNormal = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: MabColors.blanc,
    height: 1.6,
  );

  static const TextStyle corpsSecondaire = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: MabColors.grisTexte,
    height: 1.6,
  );

  static const TextStyle corpsMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: MabColors.blanc,
    height: 1.5,
  );

  static const TextStyle boutonPrincipal = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: MabColors.blanc,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle boutonSecondaire = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MabColors.rouge,
    letterSpacing: 0.3,
    height: 1.2,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: MabColors.grisTexte,
    letterSpacing: 0.4,
    height: 1.4,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: MabColors.blanc,
    letterSpacing: 0.3,
  );

  static const TextStyle messageVocal = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: MabColors.blanc,
    height: 1.7,
  );

  static const TextStyle titreApp = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: MabColors.grisDore,
    letterSpacing: 1.5,
    height: 1.1,
  );
}

// ------------------------------------------------------------
// DIMENSIONS ET ESPACEMENTS
// ------------------------------------------------------------

class MabDimensions {
  static const double zoneTactileMin    = 48.0;
  static const double boutonHauteur     = 56.0;
  static const double boutonHauteurGrand = 64.0;
  static const double rayonPetit   = 8.0;
  static const double rayonMoyen   = 12.0;
  static const double rayonGrand   = 20.0;
  static const double rayonBouton  = 16.0;
  static const double rayonCard    = 16.0;
  static const double rayonCircle  = 999.0;
  static const double espacementXS  = 4.0;
  static const double espacementS   = 8.0;
  static const double espacementM   = 16.0;
  static const double espacementL   = 24.0;
  static const double espacementXL  = 32.0;
  static const double espacementXXL = 48.0;
  static const EdgeInsets paddingEcran = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );
  static const EdgeInsets paddingCard = EdgeInsets.all(16.0);
  static const double iconeS  = 20.0;
  static const double iconeM  = 24.0;
  static const double iconeL  = 32.0;
  static const double iconeXL = 48.0;
}

// ------------------------------------------------------------
// THÈME FLUTTER COMPLET
// ------------------------------------------------------------

class MabTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary:          MabColors.rouge,
      onPrimary:        MabColors.blanc,
      secondary:        MabColors.grisDore,
      onSecondary:      MabColors.noir,
      surface:          MabColors.noirMoyen,
      onSurface:        MabColors.blanc,
      error:            MabColors.diagnosticRouge,
      onError:          MabColors.blanc,
    ),
    scaffoldBackgroundColor: MabColors.noir,
    appBarTheme: const AppBarTheme(
      backgroundColor:  MabColors.noir,
      foregroundColor:  MabColors.blanc,
      elevation:        0,
      centerTitle:      true,
      titleTextStyle:   MabTextStyles.titreSection,
      iconTheme:        IconThemeData(
        color:  MabColors.blanc,
        size:   MabDimensions.iconeM,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:  MabColors.rouge,
        foregroundColor:  MabColors.blanc,
        minimumSize:      const Size(double.infinity, MabDimensions.boutonHauteur),
        padding:          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape:            RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MabDimensions.rayonBouton),
        ),
        textStyle:        MabTextStyles.boutonPrincipal,
        elevation:        2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor:  MabColors.rouge,
        minimumSize:      const Size(double.infinity, MabDimensions.boutonHauteur),
        padding:          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side:             const BorderSide(color: MabColors.rouge, width: 2),
        shape:            RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MabDimensions.rayonBouton),
        ),
        textStyle:        MabTextStyles.boutonSecondaire,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor:  MabColors.grisDore,
        minimumSize:      const Size(48, MabDimensions.zoneTactileMin),
        padding:          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle:        MabTextStyles.corpsMedium,
      ),
    ),
    cardTheme: CardThemeData(
      color:        MabColors.noirMoyen,
      elevation:    4,
      margin:       const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape:        RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled:           true,
      fillColor:        MabColors.noirMoyen,
      contentPadding:   const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius:   BorderRadius.circular(MabDimensions.rayonMoyen),
        borderSide:     const BorderSide(color: MabColors.grisContour),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:   BorderRadius.circular(MabDimensions.rayonMoyen),
        borderSide:     const BorderSide(color: MabColors.grisContour),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:   BorderRadius.circular(MabDimensions.rayonMoyen),
        borderSide:     const BorderSide(color: MabColors.rouge, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:   BorderRadius.circular(MabDimensions.rayonMoyen),
        borderSide:     const BorderSide(color: MabColors.diagnosticRouge, width: 2),
      ),
      labelStyle:       MabTextStyles.corpsSecondaire,
      hintStyle:        MabTextStyles.corpsSecondaire,
      errorStyle:       const TextStyle(
        fontSize: 14,
        color:    MabColors.diagnosticRouge,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:      MabColors.noirMoyen,
      selectedItemColor:    MabColors.rouge,
      unselectedItemColor:  MabColors.grisTexte,
      selectedLabelStyle:   TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
      showSelectedLabels:   true,
      showUnselectedLabels: true,
      type:                 BottomNavigationBarType.fixed,
      elevation:            8,
    ),
    dividerTheme: const DividerThemeData(
      color:      MabColors.grisContour,
      thickness:  1,
      space:      1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor:   MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return MabColors.rouge;
        return MabColors.grisTexte;
      }),
      trackColor:   MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return MabColors.rougeSombre;
        return MabColors.noirClair;
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor:  MabColors.noirMoyen,
      contentTextStyle: MabTextStyles.corpsNormal,
      shape:            RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
      ),
      behavior:         SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: MabColors.noirMoyen,
      titleTextStyle:  MabTextStyles.titreSection,
      contentTextStyle: MabTextStyles.corpsNormal,
      shape:           RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonGrand),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge:   MabTextStyles.titreApp,
      displayMedium:  MabTextStyles.titrePrincipal,
      displaySmall:   MabTextStyles.titreSection,
      headlineMedium: MabTextStyles.titreCard,
      bodyLarge:      MabTextStyles.corpsNormal,
      bodyMedium:     MabTextStyles.corpsSecondaire,
      bodySmall:      MabTextStyles.label,
      labelLarge:     MabTextStyles.boutonPrincipal,
      labelMedium:    MabTextStyles.badge,
    ),
  );
}
