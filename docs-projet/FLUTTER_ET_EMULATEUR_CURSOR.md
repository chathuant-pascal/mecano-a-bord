# Flutter 3.3.8 + Émulateur pour Cursor — Mécano à Bord

Ce document décrit où placer Flutter pour que l’assistant (et Cursor) puissent l’utiliser, et quel émulateur choisir pour tester l’application depuis Cursor.

---

## 1. Fichiers / emplacement dont l’assistant a besoin (Flutter)

Pour que les commandes `flutter` fonctionnent dans le terminal de Cursor (et que l’assistant puisse lancer `flutter pub get`, `flutter run`, etc.), il faut :

- **Flutter installé** : le dossier extrait du zip (ex. `flutter_3.3.8` ou `flutter`) contenant notamment le sous-dossier **`bin`** avec `flutter.bat` (Windows).
- **Flutter dans le PATH** : le chemin vers ce dossier **`bin`** doit être dans la variable d’environnement **PATH** de Windows.

### Où installer / mettre Flutter

- **Recommandé** : un chemin court sans espaces ni caractères spéciaux, par exemple :
  - `C:\flutter`
  - ou `C:\src\flutter`
- Après extraction : le dossier doit contenir `bin\flutter.bat`. C’est ce dossier **parent** (ex. `C:\flutter`) qu’il ne faut pas déplacer ; on ajoute au PATH le chemin **`C:\flutter\bin`** (avec `\bin`).

### Ajouter Flutter au PATH (Windows)

1. **Paramètres Windows** → **Système** → **À propos** → **Paramètres système avancés** → **Variables d’environnement**.
2. Dans **Variables utilisateur**, sélectionner **Path** → **Modifier** → **Nouveau**.
3. Ajouter la ligne : `C:\flutter\bin` (adapter si ton dossier est ailleurs).
4. Valider par **OK** partout.
5. **Fermer puis rouvrir Cursor** (et tout terminal déjà ouvert), pour que le nouveau PATH soit pris en compte.

### Vérification

Dans le **terminal intégré de Cursor** (ou un PowerShell/cmd fraîchement ouvert) :

```bash
flutter --version
```

Tu dois voir la version (ex. Flutter 3.3.8). Si cette commande fonctionne, l’assistant pourra aussi utiliser `flutter` dans le même environnement.

---

## 2. Émulateur compatible avec Cursor

Cursor n’a pas d’émulateur intégré. Il utilise le **terminal** pour lancer les commandes Flutter. Tout émulateur que **Flutter voit** avec `flutter devices` fonctionne donc avec Cursor.

### Choix recommandé : **Android Emulator** (AVD)

- **Compatible Cursor** : oui, car tu lances `flutter run` dans le terminal de Cursor ; Flutter envoie l’app à l’émulateur Android déjà ouvert.
- **Standard** pour développer des apps Flutter sur Windows (mobile Android).
- **Requis** : Android Studio (ou au minimum le SDK Android + outil `avdmanager`).

### Étapes pour avoir un émulateur Android

1. **Installer Android Studio** (si ce n’est pas déjà fait)  
   - https://developer.android.com/studio  
   - Lors de l’installation, accepter l’installation du **Android SDK** et des **Android SDK Build-Tools**.

2. **Créer un appareil virtuel (AVD)**  
   - Ouvrir Android Studio → **More Actions** (ou **Tools**) → **Device Manager** (ou **AVD Manager**).  
   - **Create Device** → choisir un téléphone (ex. **Pixel 6** ou **Pixel 7**) → **Next**.  
   - Choisir une **system image** (ex. **API 34** ou **API 33**, “Google APIs” ou “Google Play”) → **Download** si besoin → **Next** → **Finish**.

3. **Lancer l’émulateur**  
   - Dans Device Manager, cliquer sur **Play** (▶) à côté de l’appareil créé.  
   - Attendre que l’écran Android s’affiche.

4. **Vérifier que Flutter le voit**  
   Dans le terminal (Cursor ou autre) :

   ```bash
   flutter devices
   ```

   Tu dois voir une ligne du type **Android SDK built for x86_64** (ou similaire) avec un **id** (ex. `emulator-5554`).

5. **Lancer l’app Mécano à Bord depuis Cursor**  
   Dans le terminal, depuis la racine du projet :

   ```bash
   cd mecano_a_bord
   flutter pub get
   flutter run
   ```

   Flutter va compiler et installer l’app sur l’émulateur ouvert ; tu pourras ainsi tester le bon fonctionnement depuis Cursor.

### Alternative : Chrome (app web)

Si tu ne veux pas installer Android Studio tout de suite :

- Installer Flutter comme ci-dessus, puis dans `mecano_a_bord` :
  ```bash
  flutter run -d chrome
  ```
- L’app s’ouvre dans Chrome. C’est utile pour des tests rapides, mais le comportement n’est pas identique à un vrai appareil Android (pas d’APK, pas de capteurs, etc.).

---

## 3. Résumé

| Besoin | Action |
|--------|--------|
| Fichiers Flutter pour Cursor | Flutter 3.3.8 extrait dans un dossier (ex. `C:\flutter`) avec **`bin`** ajouté au **PATH**. |
| Vérifier que Cursor “voit” Flutter | Ouvrir le terminal Cursor → `flutter --version`. |
| Émulateur compatible Cursor | **Android Emulator** (AVD) via Android Studio : créer un AVD, lancer l’émulateur, puis `flutter run` dans le terminal. |
| Tester l’app | `cd mecano_a_bord` → `flutter pub get` → `flutter run` (avec l’émulateur déjà démarré). |

Une fois Flutter dans le PATH et un AVD créé, tu peux tout faire depuis le terminal de Cursor ; aucun émulateur “spécifique Cursor” n’est nécessaire — l’émulateur Android standard est celui recommandé.
