"""Régénère docs-projet/juridique/CGV_SYSTEMEIO.txt (texte brut à coller dans
Systeme.io) à partir du texte maître CGV_MECANO_A_BORD.md, sans recopie à la main.

À lancer APRÈS chaque modification des CGV :
    python docs-projet/juridique/outils/generer_cgv_systemeio.py
puis vérifier (voir README.md de ce dossier).
"""
import io, re, sys

from juridique_commun import MASTER_CGV, TEXTE_SYSTEMEIO, decouper, lire_maitre, sans_marques

sys.stdout.reconfigure(encoding='utf-8')


def tableau_en_texte(rangs):
    """Un tableau devient une liste : une puce par colonne (ex. un régime de
    garantie), qui reprend chaque ligne « intitulé : valeur »."""
    entete, lignes = rangs[0], rangs[1:]
    out = []
    for c in range(1, len(entete)):
        details = ' ; '.join('%s : %s' % (sans_marques(r[0]), sans_marques(r[c])) for r in lignes)
        out.append('• %s — %s.' % (sans_marques(entete[c]), details))
    return out


def generer():
    blocs = decouper(lire_maitre(MASTER_CGV))
    out = []
    for b in blocs:
        if b[0] == 'titre':
            t = sans_marques(b[2])
            out.append(t.upper() if b[1] <= 2 else t)
        elif b[0] == 'separateur':
            continue
        elif b[0] == 'paragraphe':
            out.append('\n'.join(sans_marques(l) for l in b[1]))
        elif b[0] == 'tableau':
            out.append('\n'.join(tableau_en_texte(b[1])))
        elif b[0] == 'liste':
            lignes = []
            for typ, niveau, num, texte in b[1]:
                marque = (num + '.') if typ == 'numero' else ('•' if niveau == 1 else '    –')
                lignes.append('%s %s' % (marque, sans_marques(texte)))
            out.append('\n'.join(lignes))
    texte = '\n\n'.join(out).strip() + '\n'
    with open(TEXTE_SYSTEMEIO, 'w', encoding='utf-8', newline='\n') as f:
        f.write(texte)
    print('écrit :', TEXTE_SYSTEMEIO)


if __name__ == '__main__':
    generer()
