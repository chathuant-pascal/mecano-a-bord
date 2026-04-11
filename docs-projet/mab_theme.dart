// ============================================================
// MAB_THEME.DART — Charte graphique Mécano à Bord
// Version 1.0 — 22/02/2026
// Compatible Flutter (Android + iOS)
// Conforme European Accessibility Act (EAA) 2025
// ============================================================

import 'package:flutter/material.dart';

// ------------------------------------------------------------
// COULEURS PRINCIPALES
// Extraites du logo Mécano à Bord
// ------------------------------------------------------------

class MabColors {

  // --- Couleurs du logo ---
  static const Color rouge        = Color(0xFFCC0000); // Rouge vif — couleur identitaire
  static const Color rougeSombre  = Color(0xFF990000); // Rouge foncé — hover, pressed
  static const Color rougeClair   = Color(0xFFFF3333); // Rouge clair — accents lumineux
  static const Color noir         = Color(0xFF1A1A1A); // Noir profond — fond principal
  static const Color noirMoyen    = Color(0xFF2C2C2C); // Noir moyen — cartes, surfaces
  static const Color noirClair    = Color(0xFF3D3D3D); // Noir clair — séparateurs
  static const Color grisDore     = Color(0xFFC8B89A); // Gris doré — texte "Mécano à Bord"
  static const Color blanc        = Color(0xFFFFFFFF); // Blanc pur — textes principaux
  static const Color blancCasse   = Color(0xFFF5F5F5); // Blanc cassé — fonds clairs

  // --- Couleurs de diagnostic (niveaux d'alerte) ---
  // IMPORTANT : ces couleurs ne servent QUE pour les alertes OBD
  // Elles ne remplacent jamais le rouge du logo dans l'interface
  static const Color diagnosticVert    = Color(0xFF2E7D32); // Tout va bien
  static const Color diagnosticOrange  = Color(0xFFE65100); // Attention requise
  static const Color diagnosticRouge   = Color(0xFFB71C1C); // Action urgente requise

  // Variantes claires pour les fonds de badge/carte de diagnostic
  static const Color diagnosticVertClair   = Color(0xFFE8F5E9);
  static const Color diagnosticOrangeClair = Color(0xFFFBE9E7);
  static const Color diagnosticRougeClair  = Color(0xFFFFEBEE);

  // --- Couleurs utilitaires ---
  static const Color grisTexte        = Color(0xFF9E9E9E); // Texte secondaire / désactivé
  static const Color grisContour      = Color(0xFF5A5A5A); // Bordures, séparateurs
  static const Color fondTransparent  = Color(0x00000000); // Transparent

  // -------------------------------------------------------
  // VÉRIFICATION ACCESSIBILITÉ EAA 2025
  // Ratio de contraste minimum requis : 4.5:1 (texte normal)
  //                                     3:1   (grands textes / icônes)
  //
  // ✅ blanc sur noir      → ratio ~18:1  (excellent)
  // ✅ blanc sur rouge     → ratio ~5.9:1 (conforme)
  // ✅ blanc sur rouge sombre → ratio ~8.5:1 (excellent)
  // ✅ grisDore sur noir   → ratio ~7.2:1 (excellent)
  // ✅ diagnosticVert fond clair + texte vert foncé → conforme
  // -------------------------------------------------------
}


// ------------------------------------------------------------
// TYPOGRAPHIE
// Police principale : Roboto (incluse nativement dans Flutter)
// Tailles conformes EAA 2025 (minimum 16sp pour le corps)
// ------------------------------------------------------------

class MabTextStyles {

  // --- Titres ---
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

  // --- Corps de texte ---
  // Minimum 16sp imposé par EAA 2025 pour la lisibilité
  static const TextStyle corpsNormal = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: MabColors.blanc,
    height: 1.6, // Interligne généreux pour la lisibilité
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

  // --- Boutons ---
  // Minimum 16sp, gras pour une identification rapide
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

  // --- Labels et badges ---
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

  // --- Diagnostic vocal / messages rassurants ---
  // Taille plus grande pour le confort de lecture en situation de conduite
  static const TextStyle messageVocal = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: MabColors.blanc,
    height: 1.7,
  );

  // --- Gris doré — style "logo" pour les titres d'écran principal ---
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
// Conformes EAA 2025 (zone tactile minimum 48x48 dp)
// ------------------------------------------------------------

class MabDimensions {

  // --- Zones tactiles (EAA 2025 : minimum 48x48 dp) ---
  static const double zoneTactileMin    = 48.0;
  static const double boutonHauteur     = 56.0; // Légèrement au-dessus du minimum
  static const double boutonHauteurGrand = 64.0; // Pour les actions principales

  // --- Rayons des coins arrondis ---
  static const double rayonPetit   = 8.0;
  static const double rayonMoyen   = 12.0;
  static const double rayonGrand   = 20.0;
  static const double rayonBouton  = 16.0;
  static const double rayonCard    = 16.0;
  static const double rayonCircle  = 999.0; // Bouton rond complet

  // --- Espacements ---
  static const double espacementXS  = 4.0;
  static const double espacementS   = 8.0;
  static const double espacementM   = 16.0;
  static const double espacementL   = 24.0;
  static const double espacementXL  = 32.0;
  static const double espacementXXL = 48.0;

  // --- Padding des écrans ---
  static const EdgeInsets paddingEcran = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );

  static const EdgeInsets paddingCard = EdgeInsets.all(16.0);

  // --- Icônes ---
  static const double iconeS  = 20.0;
  static const double iconeM  = 24.0;
  static const double iconeL  = 32.0;
  static const double iconeXL = 48.0; // Icônes de navigation principale
}


// ------------------------------------------------------------
// THÈME FLUTTER COMPLET
// À utiliser dans MaterialApp(theme: MabTheme.theme)
// ------------------------------------------------------------

class MabTheme {

  static ThemeData get theme => ThemeData(

    // --- Base ---
    useMaterial3: true,
    brightness: Brightness.dark,

    // --- Palette de couleurs ---
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

    // --- Fond général ---
    scaffoldBackgroundColor: MabColors.noir,

    // --- Barre d'application ---
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

    // --- Boutons principaux ---
    // Hauteur et padding conformes EAA 2025 (zone tactile ≥ 48dp)
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

    // --- Boutons secondaires (contour) ---
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

    // --- Boutons texte ---
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor:  MabColors.grisDore,
        minimumSize:      const Size(48, MabDimensions.zoneTactileMin),
        padding:          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle:        MabTextStyles.corpsMedium,
      ),
    ),

    // --- Cartes ---
    cardTheme: CardTheme(
      color:        MabColors.noirMoyen,
      elevation:    4,
      margin:       const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape:        RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
      ),
    ),

    // --- Champs de saisie ---
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

    // --- Navigation du bas ---
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:      MabColors.noirMoyen,
      selectedItemColor:    MabColors.rouge,
      unselectedItemColor:  MabColors.grisTexte,
      selectedLabelStyle:   TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
      showSelectedLabels:   true,
      showUnselectedLabels: true, // EAA : toujours visible
      type:                 BottomNavigationBarType.fixed,
      elevation:            8,
    ),

    // --- Divider ---
    dividerTheme: const DividerThemeData(
      color:      MabColors.grisContour,
      thickness:  1,
      space:      1,
    ),

    // --- Switch / Toggle ---
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

    // --- Snackbar (messages temporaires) ---
    snackBarTheme: SnackBarThemeData(
      backgroundColor:  MabColors.noirMoyen,
      contentTextStyle: MabTextStyles.corpsNormal,
      shape:            RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
      ),
      behavior:         SnackBarBehavior.floating,
    ),

    // --- Dialogue / Popup ---
    dialogTheme: DialogTheme(
      backgroundColor: MabColors.noirMoyen,
      titleTextStyle:  MabTextStyles.titreSection,
      contentTextStyle: MabTextStyles.corpsNormal,
      shape:           RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonGrand),
      ),
    ),

    // --- Typographie globale ---
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


// ------------------------------------------------------------
// WIDGETS RÉUTILISABLES — DIAGNOSTICS
// Badges colorés pour les 3 niveaux d'alerte OBD
// ------------------------------------------------------------

class MabDiagnosticBadge extends StatelessWidget {

  final String niveau; // 'vert', 'orange', 'rouge'
  final String texte;

  const MabDiagnosticBadge({
    super.key,
    required this.niveau,
    required this.texte,
  });

  Color get couleurFond {
    switch (niveau) {
      case 'vert':   return MabColors.diagnosticVertClair;
      case 'orange': return MabColors.diagnosticOrangeClair;
      case 'rouge':  return MabColors.diagnosticRougeClair;
      default:       return MabColors.noirMoyen;
    }
  }

  Color get couleurTexte {
    switch (niveau) {
      case 'vert':   return MabColors.diagnosticVert;
      case 'orange': return MabColors.diagnosticOrange;
      case 'rouge':  return MabColors.diagnosticRouge;
      default:       return MabColors.blanc;
    }
  }

  String get icone {
    switch (niveau) {
      case 'vert':   return '✅';
      case 'orange': return '⚠️';
      case 'rouge':  return '🔴';
      default:       return 'ℹ️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // EAA 2025 : description lisible par les lecteurs d'écran
      label: 'Niveau de diagnostic : $texte',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:        couleurFond,
          borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
          border:       Border.all(color: couleurTexte, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icone, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              texte,
              style: MabTextStyles.badge.copyWith(color: couleurTexte),
            ),
          ],
        ),
      ),
    );
  }
}


// ------------------------------------------------------------
// WIDGET BOUTON ACCESSIBLE
// Respecte la zone tactile minimum EAA 2025 (48x48 dp)
// Avec description pour les lecteurs d'écran
// ------------------------------------------------------------

class MabBoutonPrincipal extends StatelessWidget {

  final String texte;
  final VoidCallback onPressed;
  final String? descriptionAccessibilite; // Pour TalkBack / VoiceOver
  final bool estCharge; // Affiche un spinner si true
  final IconData? icone;

  const MabBoutonPrincipal({
    super.key,
    required this.texte,
    required this.onPressed,
    this.descriptionAccessibilite,
    this.estCharge = false,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: descriptionAccessibilite ?? texte,
      button: true,
      child: ElevatedButton(
        onPressed: estCharge ? null : onPressed,
        child: estCharge
            ? const SizedBox(
                width:  24,
                height: 24,
                child:  CircularProgressIndicator(
                  color:       MabColors.blanc,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icone != null) ...[
                    Icon(icone, size: MabDimensions.iconeM),
                    const SizedBox(width: 10),
                  ],
                  Text(texte),
                ],
              ),
      ),
    );
  }
}
