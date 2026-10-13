"""Régénère l'écran de l'app (mecano_a_bord/lib/screens/privacy_policy_screen.dart)
à partir du texte maître docs-projet/juridique/POLITIQUE_CONFIDENTIALITE.md,
sans aucune recopie à la main. À lancer APRÈS chaque modification du texte maître :

    python docs-projet/juridique/outils/generer_ecran_confidentialite.py

puis vérifier (voir README.md de ce dossier).
"""
import io, os, re, subprocess, sys, textwrap

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
MASTER = os.path.join(ROOT, 'docs-projet', 'juridique', 'POLITIQUE_CONFIDENTIALITE.md')
SCREEN = os.path.join(ROOT, 'mecano_a_bord', 'lib', 'screens', 'privacy_policy_screen.dart')
src = io.open(MASTER, encoding='utf-8').read()
src = re.sub(r'<!-- NOTE-PASCAL-DEBUT -->.*?<!-- NOTE-PASCAL-FIN -->\n?', '', src, flags=re.S)


def clean(line):
    line = line.replace('**', '').replace('`', '')
    line = re.sub(r'^  - ', '    – ', line)
    line = re.sub(r'^- ', '• ', line)
    return line


# Découpage : titre (#), date, intro, puis sections ## / ###
title = re.search(r'^# (.+)$', src, re.M).group(1)
date = re.search(r'^(Dernière mise à jour.*)$', src, re.M).group(1)
blocks = re.split(r'^(#{2,3}) (.+)$', src, flags=re.M)
preamble = blocks[0]
intro = preamble.split(date, 1)[1].strip()
sections = []
for i in range(1, len(blocks), 3):
    level, head, body = blocks[i], blocks[i + 1], blocks[i + 2]
    lines = [clean(l) for l in body.strip().split('\n')]
    # paragraphes séparés par une ligne vide ; lignes d'une liste séparées par \n
    text = '\n'.join(lines)
    text = re.sub(r'\n{2,}', '\n\n', text).strip()
    sections.append((len(level), head.strip(), text))


def dart_str(s, indent):
    """Chaîne Dart entre apostrophes, découpée en littéraux adjacents."""
    s = s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
    parts = []
    for para in re.split(r'(\n)', s):
        if para == '\n':
            if parts:
                parts[-1] += '\\n'
            else:
                parts.append('\\n')
            continue
        if not para:
            continue
        chunks = textwrap.wrap(para, 66, drop_whitespace=False, break_long_words=False,
                               break_on_hyphens=False) or ['']
        parts.extend(chunks)
    pad = ' ' * indent
    return ('\n' + pad).join("'" + p + "'" for p in parts)


out = []
out.append("""// privacy_policy_screen.dart — Mécano à Bord
// Écran intégré affichant la politique de confidentialité.
//
// ⚠️ TEXTE GÉNÉRÉ depuis le texte maître
// docs-projet/juridique/POLITIQUE_CONFIDENTIALITE.md (dépôt principal).
// Ne jamais modifier le texte ici seul : modifier le texte maître, puis
// régénérer ce fichier, pour que l'application, la formation web et les
// stores affichent exactement la même politique.

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/widgets/mab_watermark_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      appBar: AppBar(
        backgroundColor: MabColors.noir,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: MabColors.blanc),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Politique de confidentialité',
          style: MabTextStyles.titreSection,
        ),
      ),
      body: MabWatermarkBackground(
        child: SingleChildScrollView(
          padding: MabDimensions.paddingEcran,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/legal-mentions');
                },
                child: Text(
                  'Voir aussi : Mentions légales complètes →',
                  style: MabTextStyles.label.copyWith(color: MabColors.grisDore),
                ),
              ),
              const SizedBox(height: MabDimensions.espacementM),
              Text(""")
out.append("                " + dart_str(title.upper(), 16) + ",")
out.append("""                style: MabTextStyles.titreSection,
              ),
              const SizedBox(height: MabDimensions.espacementS),
              Text(""")
out.append("                " + dart_str(date, 16) + ",")
out.append("""                style: MabTextStyles.corpsSecondaire,
              ),
              const SizedBox(height: MabDimensions.espacementM),
              Text(""")
out.append("                " + dart_str(clean(intro), 16) + ",")
out.append("""                style: MabTextStyles.corpsNormal.copyWith(height: 1.5),
              ),
              const SizedBox(height: MabDimensions.espacementXL),
""")
for level, head, text in sections:
    out.append("              _Section(")
    out.append("                title: " + dart_str(head, 24) + ",")
    if level == 3:
        out.append("                isSubsection: true,")
    if text:
        out.append("                body:")
        out.append("                    " + dart_str(text, 20) + ",")
    out.append("              ),")
out.append("""              const SizedBox(height: MabDimensions.espacementXXL),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une section de la politique. [isSubsection] : sous-partie (ex. 4.1),
/// titre en doré pour la distinguer des grandes sections. Sans [body], seul
/// le titre est affiché (ex. section 4, qui ne contient que des sous-parties).
class _Section extends StatelessWidget {
  final String title;
  final String body;
  final bool isSubsection;

  const _Section({
    required this.title,
    this.body = '',
    this.isSubsection = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MabDimensions.espacementL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: isSubsection
                ? MabTextStyles.titreCard.copyWith(color: MabColors.grisDore)
                : MabTextStyles.titreCard,
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: MabDimensions.espacementS),
            Text(
              body,
              style: MabTextStyles.corpsNormal.copyWith(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
""")
io.open(SCREEN, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print(len(sections), 'sections écrites dans', SCREEN)
try:
    subprocess.run('dart format "' + SCREEN + '"', shell=True, check=True)
except Exception as e:  # dart absent du PATH : formater à la main
    print('ATTENTION : dart format a échoué (' + str(e) + ') — lancer : dart format ' + SCREEN)
