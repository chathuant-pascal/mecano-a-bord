"""Vérifie, MOT POUR MOT, que chaque affichage reprend fidèlement son texte maître :

    1. écran de l'app          privacy_policy_screen.dart  <- POLITIQUE_CONFIDENTIALITE.md
    2. page publique           confidentialite.html        <- POLITIQUE_CONFIDENTIALITE.md
    3. page publique           cgv.html                    <- CGV_MECANO_A_BORD.md
    4. texte pour Systeme.io   CGV_SYSTEMEIO.txt           <- CGV_MECANO_A_BORD.md
       (le tableau devient une liste : chaque case du tableau doit s'y retrouver)

    python docs-projet/juridique/outils/verifier_textes_juridiques.py

Chaque ligne doit finir par « OK ». Sinon, relancer le script de génération concerné.
"""
import html, io, re, sys

from juridique_commun import (ECRAN_APP, MASTER_CGV, MASTER_CONFIDENTIALITE, PAGE_CGV,
                              PAGE_CONFIDENTIALITE, TEXTE_SYSTEMEIO, decouper, lire_maitre,
                              mots, mots_maitre, sans_marques)

sys.stdout.reconfigure(encoding='utf-8')


def comparer(nom, attendu, obtenu):
    if attendu == obtenu:
        print('OK      %-24s %d mots identiques' % (nom, len(attendu)))
        return True
    for i in range(max(len(attendu), len(obtenu))):
        if i >= len(attendu) or i >= len(obtenu) or attendu[i] != obtenu[i]:
            print('ÉCART   %-24s au mot %d : %s <-> %s' % (
                nom, i, attendu[max(0, i - 3):i + 4], obtenu[max(0, i - 3):i + 4]))
            return False


def lire(chemin):
    try:
        return io.open(chemin, encoding='utf-8').read()
    except OSError:
        return None


def texte_ecran():
    dart = lire(ECRAN_APP)
    if dart is None:
        return None
    corps = dart.split("complètes →',")[1].split('class _Section')[0]
    litteraux = re.findall(r"'((?:[^'\\]|\\.)*)'", corps)
    return ' '.join(litteraux).replace("\\'", "'").replace('\\n', '\n').replace('\\$', '$')


def texte_page(chemin):
    page = lire(chemin)
    if page is None:
        return None
    debut, fin = page.find('<!-- TEXTE-DEBUT -->'), page.find('<!-- TEXTE-FIN -->')
    return html.unescape(re.sub(r'<[^>]+>', ' ', page[debut:fin]))


ok = True
confidentialite = lire_maitre(MASTER_CONFIDENTIALITE)
cgv = lire_maitre(MASTER_CGV)

for nom, attendu, obtenu in [
    ('écran app', confidentialite, texte_ecran()),
    ('confidentialite.html', confidentialite, texte_page(PAGE_CONFIDENTIALITE)),
    ('cgv.html', cgv, texte_page(PAGE_CGV)),
]:
    if obtenu is None:
        print('ABSENT  %s' % nom)
        ok = False
    else:
        ok = comparer(nom, mots_maitre(attendu), mots(obtenu)) and ok

# Texte Systeme.io : hors tableau, mot pour mot ; tableau, chaque case présente.
txt = lire(TEXTE_SYSTEMEIO)
if txt is None:
    print('ABSENT  CGV_SYSTEMEIO.txt')
    ok = False
else:
    from generer_cgv_systemeio import tableau_en_texte
    maitre_sans_tableau = re.sub(r'(?m)^\|.*\n', '', cgv)
    txt_sans_tableau = txt
    cases = []
    for b in decouper(cgv):
        if b[0] == 'tableau':
            for ligne in tableau_en_texte(b[1]):
                txt_sans_tableau = txt_sans_tableau.replace(ligne, '')
            cases += [sans_marques(c) for r in b[1] for c in r if c]
    ok = comparer('CGV_SYSTEMEIO.txt', mots_maitre(maitre_sans_tableau), mots(txt_sans_tableau)) and ok
    absentes = [c for c in cases if c not in txt]
    if absentes:
        print('ÉCART   CGV_SYSTEMEIO.txt        cases du tableau absentes :', absentes)
        ok = False
    else:
        print('OK      CGV_SYSTEMEIO.txt        %d cases du tableau présentes' % len(cases))

sys.exit(0 if ok else 1)
