# Recherche de l’émulateur Android — Résultat

Recherche effectuée sur ta machine pour trouver l’émulateur et préparer les tests de l’application Mécano à Bord.

---

## Ce qui a été trouvé

| Élément | Emplacement | Statut |
|--------|-------------|--------|
| **Android SDK** | `C:\Users\karuc\AppData\Local\Android\Sdk` | OK |
| **Emulateur (binaire)** | `C:\Users\karuc\AppData\Local\Android\Sdk\emulator\emulator.exe` | OK |
| **Dossier AVD** | `C:\Users\karuc\.android\avd` | Existe mais **vide** |

Conclusion : Android Studio et le SDK sont bien installés, mais **aucun appareil virtuel (AVD) n’a encore été créé**. Il faut en créer un pour pouvoir lancer un émulateur et tester l’app.

---

## Ce qu’il faut faire : créer un AVD

Sans AVD, l’émulateur n’a pas de “téléphone” à afficher. Il faut en créer un **une fois** depuis Android Studio.

### Étapes dans Android Studio

1. **Ouvrir Android Studio.**

2. **Ouvrir le Device Manager**  
   - Écran d’accueil : **More Actions** → **Virtual Device Manager**  
   - Ou menu : **Tools** → **Device Manager**

3. **Créer un appareil**  
   - Cliquer sur **Create Device** (ou l’icône “+”).
   - **Category** : Phone.
   - Choisir un modèle (ex. **Pixel 6** ou **Pixel 7**) → **Next**.

4. **Choisir une image système**  
   - Onglet **Recommended** (ou **x86 Images**).  
   - Sélectionner une image (ex. **API 34** “UpsideDownCake” ou **API 33** “Tiramisu”) avec **Google APIs** ou **Google Play**.  
   - Si elle n’est pas installée : cliquer **Download** à côté, attendre la fin, puis **Next**.

5. **Fin**  
   - Nom de l’AVD (tu peux laisser le nom proposé, ex. `Pixel_6_API_34`).  
   - **Finish**.

6. **Lancer l’émulateur**  
   - Dans la liste des appareils, cliquer sur le **bouton Play (▶)** à côté de l’AVD créé.  
   - Attendre que la fenêtre de l’émulateur s’ouvre et que l’écran Android s’affiche.

---

## Tester l’application Mécano à Bord

Une fois **Flutter** dans le PATH et **l’émulateur déjà lancé** (fenêtre ouverte) :

1. Ouvrir un terminal dans Cursor (ou PowerShell).
2. Aller dans le projet Flutter :
   ```bash
   cd "C:\Users\karuc\OneDrive\Bureau\Mecano A Bord\mecano_a_bord"
   ```
3. Récupérer les dépendances et lancer l’app :
   ```bash
   flutter pub get
   flutter run
   ```
   Flutter va compiler et installer l’app sur l’émulateur ouvert.

Si plusieurs appareils sont connectés (émulateur + téléphone réel), tu peux forcer l’émulateur :
```bash
flutter run -d emulator-5554
```
(Le bon identifiant s’affiche avec `flutter devices`.)

---

## Récapitulatif

- **SDK et binaire d’émulation** : trouvés, prêts à l’emploi.
- **AVD** : aucun pour l’instant → à créer **une fois** dans Android Studio (Device Manager → Create Device).
- **Test de l’app** : après création de l’AVD et démarrage de l’émulateur, utiliser `flutter run` depuis le dossier `mecano_a_bord` dans Cursor.
