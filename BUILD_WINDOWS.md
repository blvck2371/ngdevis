# Obtenir le fichier .exe (version Windows)

Pour générer l’exécutable Windows (`.exe`) de NG Devis, il faut **compiler le projet sur un PC Windows** (Flutter ne peut pas créer un .exe depuis macOS ou Linux).

## 1. Sur un PC Windows

### Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) installé sur Windows
- [Visual Studio 2022](https://visualstudio.microsoft.com/) avec la charge de travail **« Développement Desktop en C++ »** (pour Flutter Windows)

### Étapes

1. **Activer le support Windows** (une seule fois) :
   ```bash
   flutter config --enable-windows-desktop
   ```

2. **Cloner ou copier le projet** sur le PC Windows (par ex. depuis Git ou une copie du dossier du projet).

3. **Dans le dossier du projet**, exécuter :
   ```bash
   flutter pub get
   flutter build windows
   ```

4. **Récupérer l’exécutable**  
   Après la build, vous trouverez :
   - **Exécutable** : `build\windows\x64\runner\Release\ngdevis.exe`
   - Pour distribuer l’app, copiez **tout le contenu** du dossier `Release` (le .exe et les DLL associées).

## 2. Sans PC Windows sous la main

- Utiliser une **machine virtuelle Windows** (VirtualBox, VMware, etc.) sur votre Mac, y installer Flutter + Visual Studio, puis lancer les commandes ci-dessus.
- Ou utiliser un **service CI** (GitHub Actions, etc.) avec un runner Windows pour faire la build à votre place.

## 3. Lancer l’app sur Windows

Double-cliquez sur `ngdevis.exe` dans le dossier `Release`, ou en ligne de commande :
```bash
cd build\windows\x64\runner\Release
ngdevis.exe
```
