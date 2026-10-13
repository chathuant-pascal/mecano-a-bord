"""Outils communs aux scripts de ce dossier : lecture des textes maîtres
(POLITIQUE_CONFIDENTIALITE.md, CGV_MECANO_A_BORD.md) et découpage en blocs.
Ce fichier ne se lance pas seul.
"""
import io, os, re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
JURIDIQUE = os.path.join(ROOT, 'docs-projet', 'juridique')
MASTER_CONFIDENTIALITE = os.path.join(JURIDIQUE, 'POLITIQUE_CONFIDENTIALITE.md')
MASTER_CGV = os.path.join(JURIDIQUE, 'CGV_MECANO_A_BORD.md')
PAGE_CONFIDENTIALITE = os.path.join(ROOT, 'confidentialite.html')
PAGE_CGV = os.path.join(ROOT, 'cgv.html')
TEXTE_SYSTEMEIO = os.path.join(JURIDIQUE, 'CGV_SYSTEMEIO.txt')
ECRAN_APP = os.path.join(ROOT, 'mecano_a_bord', 'lib', 'screens', 'privacy_policy_screen.dart')

NOTE = re.compile(r'<!-- NOTE-PASCAL-DEBUT -->.*?<!-- NOTE-PASCAL-FIN -->\n?', re.S)
# Italique *texte* — sans toucher aux « (*) » du formulaire de rétractation.
ITALIQUE = re.compile(r'(?<![(\w*])\*(?![)*\s])([^*\n]+?)(?<![(\s])\*(?![\w)*])')


def lire_maitre(chemin):
    """Texte maître sans les notes réservées à Pascal."""
    return NOTE.sub('', io.open(chemin, encoding='utf-8').read())


def decouper(texte):
    """Découpe le Markdown en blocs : ('titre', niveau, texte), ('separateur',),
    ('tableau', [lignes de cellules]), ('liste', [(type, niveau, numéro, texte)]),
    ('paragraphe', [lignes])."""
    blocs, lignes, i = [], texte.split('\n'), 0
    while i < len(lignes):
        l = lignes[i]
        if not l.strip():
            i += 1
            continue
        m = re.match(r'^(#{1,3}) (.+)$', l)
        if m:
            blocs.append(('titre', len(m.group(1)), m.group(2).strip()))
            i += 1
            continue
        if l.strip() == '---':
            blocs.append(('separateur',))
            i += 1
            continue
        if l.startswith('|'):
            rangs = []
            while i < len(lignes) and lignes[i].startswith('|'):
                cells = [c.strip() for c in lignes[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r'-+', c) for c in cells):
                    rangs.append(cells)
                i += 1
            blocs.append(('tableau', rangs))
            continue
        if re.match(r'^( {2})?(- |\d+\. )', l):
            items = []
            while i < len(lignes) and re.match(r'^( {2})?(- |\d+\. )', lignes[i]):
                m = re.match(r'^( {2})?(?:(- )|(\d+)\. )(.*)$', lignes[i])
                niveau = 2 if m.group(1) else 1
                if m.group(2):
                    items.append(('puce', niveau, None, m.group(4)))
                else:
                    items.append(('numero', niveau, m.group(3), m.group(4)))
                i += 1
            blocs.append(('liste', items))
            continue
        para = []
        while i < len(lignes) and lignes[i].strip() and not re.match(r'^(#{1,3} |\||---$|( {2})?(- |\d+\. ))', lignes[i]):
            para.append(lignes[i])
            i += 1
        blocs.append(('paragraphe', para))
    return blocs


def sans_marques(s):
    """Texte brut d'une ligne : sans gras, italique ni code."""
    s = s.replace('**', '').replace('`', '')
    return ITALIQUE.sub(r'\1', s)


MOT = re.compile(r"[0-9A-Za-zÀ-ÖØ-öø-ÿŒœ@.]+")


def mots(texte):
    """Suite des mots d'un texte, pour une comparaison mot pour mot."""
    return [w.strip('.').lower() for w in MOT.findall(texte) if w.strip('.')]


def mots_maitre(texte_maitre):
    return mots(sans_marques(texte_maitre))
