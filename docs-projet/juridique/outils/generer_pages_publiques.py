"""Régénère les deux pages publiques, à la racine du dépôt principal, à partir
des textes maîtres (sans aucune recopie à la main) :

    confidentialite.html  <-  docs-projet/juridique/POLITIQUE_CONFIDENTIALITE.md
    cgv.html              <-  docs-projet/juridique/CGV_MECANO_A_BORD.md

À lancer APRÈS chaque modification d'un texte maître :
    python docs-projet/juridique/outils/generer_pages_publiques.py
puis vérifier (voir README.md de ce dossier).

Adresses publiques (GitHub Pages) :
    https://chathuant-pascal.github.io/mecano-a-bord/confidentialite.html
    https://chathuant-pascal.github.io/mecano-a-bord/cgv.html
(puis https://mecanoabord.fr/... quand le nom de domaine sera branché).
"""
import html, os, re, sys

from juridique_commun import (ITALIQUE, MASTER_CGV, MASTER_CONFIDENTIALITE, PAGE_CGV,
                              PAGE_CONFIDENTIALITE, decouper, lire_maitre)

sys.stdout.reconfigure(encoding='utf-8')

E_MAIL = 'mecanoabord@gmail.com'


def en_ligne(s):
    """Une ligne de Markdown -> HTML (gras, italique, lien e-mail)."""
    s = html.escape(s, quote=False).replace('`', '')
    s = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', s)
    s = ITALIQUE.sub(r'<em>\1</em>', s)
    s = s.replace(E_MAIL, '<a href="mailto:' + E_MAIL + '">' + E_MAIL + '</a>')
    return s


def ancre(titre):
    a = re.sub(r'[^a-z0-9]+', '-', titre.lower().translate(str.maketrans(
        'àâäéèêëîïôöùûüçœ', 'aaaeeeeiioouuuco')))
    return a.strip('-')[:60]


def corps_html(blocs):
    out = []
    for b in blocs:
        if b[0] == 'titre':
            niveau, t = b[1], b[2]
            out.append('<h%d id="%s">%s</h%d>' % (niveau, ancre(t), en_ligne(t), niveau))
        elif b[0] == 'separateur':
            out.append('<hr>')
        elif b[0] == 'paragraphe':
            out.append('<p>' + '<br>\n'.join(en_ligne(l) for l in b[1]) + '</p>')
        elif b[0] == 'tableau':
            entete, rangs = b[1][0], b[1][1:]
            t = ['<div class="tableau"><table>', '<thead><tr>']
            t += ['<th scope="col">%s</th>' % en_ligne(c) for c in entete]
            t.append('</tr></thead><tbody>')
            for r in rangs:
                t.append('<tr><th scope="row">%s</th>%s</tr>' % (
                    en_ligne(r[0]), ''.join('<td>%s</td>' % en_ligne(c) for c in r[1:])))
            t.append('</tbody></table></div>')
            out.append('\n'.join(t))
        elif b[0] == 'liste':
            ordonnee = b[1][0][0] == 'numero'
            t = ['<ul class="numeros">' if ordonnee else '<ul>']
            ouvert_sous = False
            for typ, niveau, num, texte in b[1]:
                contenu = en_ligne(texte)
                if typ == 'numero':
                    contenu = '<span class="num">%s.</span> %s' % (num, contenu)
                if niveau == 2 and not ouvert_sous:
                    t[-1] = t[-1][:-len('</li>')] if t[-1].endswith('</li>') else t[-1]
                    t.append('<ul>')
                    ouvert_sous = True
                elif niveau == 1 and ouvert_sous:
                    t.append('</ul></li>')
                    ouvert_sous = False
                t.append('<li>%s</li>' % contenu)
            if ouvert_sous:
                t.append('</ul></li>')
            t.append('</ul>')
            out.append('\n'.join(t))
    return '\n'.join(out)


PAGE = """<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<!-- FICHIER GÉNÉRÉ par docs-projet/juridique/outils/generer_pages_publiques.py
     depuis {source}. Ne pas modifier à la main : modifier le texte maître,
     puis relancer le script. -->
<title>{titre} — Mécano à Bord</title>
<meta name="description" content="{description}">
<style>
  :root {{
    --fond: #111111;
    --fond-carte: #1c1c1c;
    --texte: #f2f2f2;
    --texte-secondaire: #c9c9c9;
    --rouge: #e03131;
    --bordure: #333333;
  }}
  * {{ box-sizing: border-box; }}
  html {{ -webkit-text-size-adjust: 100%; }}
  body {{
    margin: 0; background: var(--fond); color: var(--texte);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
    font-size: 17px; line-height: 1.65;
  }}
  header, main, footer {{ max-width: 780px; margin: 0 auto; padding: 0 16px; }}
  header {{ padding-top: 20px; color: var(--texte-secondaire); font-weight: 700; letter-spacing: .04em; }}
  header span {{ color: var(--rouge); }}
  h1 {{ font-size: 1.7em; line-height: 1.25; margin: .6em 0 .4em; }}
  h2 {{ font-size: 1.3em; line-height: 1.3; margin: 2em 0 .5em; padding-left: 12px;
        border-left: 4px solid var(--rouge); }}
  h3 {{ font-size: 1.08em; margin: 1.6em 0 .4em; color: #ffd27a; }}
  p, li {{ color: var(--texte-secondaire); overflow-wrap: anywhere; }}
  strong {{ color: var(--texte); }}
  a {{ color: #ff6b6b; }}
  ul {{ padding-left: 1.3em; }}
  ul.numeros {{ list-style: none; padding-left: 0; }}
  .num {{ color: var(--texte); font-weight: 700; }}
  li {{ margin: .35em 0; }}
  hr {{ border: 0; border-top: 1px solid var(--bordure); margin: 2.2em 0; }}
  .tableau {{ overflow-x: auto; margin: 1em 0; }}
  table {{ border-collapse: collapse; min-width: 560px; font-size: .92em; }}
  th, td {{ border: 1px solid var(--bordure); padding: 8px 10px; text-align: left; vertical-align: top; }}
  thead th {{ background: var(--fond-carte); color: var(--texte); }}
  tbody th {{ color: var(--texte); background: var(--fond-carte); }}
  td {{ color: var(--texte-secondaire); }}
  footer {{ margin-top: 3em; padding-bottom: 32px; border-top: 1px solid var(--bordure); }}
  footer nav {{ display: flex; flex-wrap: wrap; gap: 4px 20px; }}
  footer a {{ display: inline-block; padding: 12px 0; min-height: 48px; }}
</style>
</head>
<body>
<header>MÉCANO <span>À</span> BORD</header>
<main>
<!-- TEXTE-DEBUT -->
{corps}
<!-- TEXTE-FIN -->
</main>
<footer>
<nav>
  <a href="confidentialite.html">Politique de confidentialité</a>
  <a href="cgv.html">Conditions générales de vente</a>
  <a href="mailto:{email}">{email}</a>
</nav>
</footer>
</body>
</html>
"""


def generer(maitre, page, description):
    texte = lire_maitre(maitre)
    blocs = decouper(texte)
    titre = next(b[2] for b in blocs if b[0] == 'titre' and b[1] == 1)
    titre_court = titre.split(' — ')[0]
    contenu = PAGE.format(source='docs-projet/juridique/' + os.path.basename(maitre),
                          titre=html.escape(titre_court), description=html.escape(description),
                          corps=corps_html(blocs), email=E_MAIL)
    with open(page, 'w', encoding='utf-8', newline='\n') as f:
        f.write(contenu)
    print('écrit :', page)


generer(MASTER_CONFIDENTIALITE, PAGE_CONFIDENTIALITE,
        'Politique de confidentialité de Mécano à Bord : données utilisées, durées, vos droits.')
generer(MASTER_CGV, PAGE_CGV,
        'Conditions générales de vente de l\'offre Mécano à Bord.')
