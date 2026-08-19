#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

APP_NAME="Harmonix"
VERSION="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n 1)"
DIST_DIR="$PROJECT_ROOT/dist/$VERSION"

usage() {
  cat <<'EOF'
Usage: ./tool/build_releases.sh [cible]

Cibles disponibles sur macOS :
  all             APK + AAB + DMG + ZIP macOS + ZIP Web (défaut)
  android         APK et Android App Bundle (AAB)
  macos           DMG et archive ZIP de l'application macOS
  ios             IPA (nécessite une signature Apple configurée dans Xcode)
  web             Archive ZIP de la version Web
  remote-desktop  Déclenche la CI GitHub pour produire Windows EXE et Linux
  help            Affiche cette aide

Les fichiers générés sont placés dans dist/<version>/.
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Commande requise introuvable : $1" >&2
    exit 1
  fi
}

prepare_dist() {
  mkdir -p "$DIST_DIR"
}

build_android() {
  echo "==> Construction Android (APK et AAB)"
  flutter build apk --release
  flutter build appbundle --release
  cp build/app/outputs/flutter-apk/app-release.apk \
    "$DIST_DIR/${APP_NAME}-${VERSION}.apk"
  cp build/app/outputs/bundle/release/app-release.aab \
    "$DIST_DIR/${APP_NAME}-${VERSION}.aab"
}

build_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "La cible macOS doit être construite depuis macOS." >&2
    exit 1
  fi

  require_command hdiutil
  require_command ditto

  echo "==> Construction macOS (DMG et ZIP)"
  flutter build macos --release

  local app_path
  app_path="$(find build/macos/Build/Products/Release -maxdepth 1 -type d -name '*.app' -print -quit)"
  if [[ -z "$app_path" ]]; then
    echo "Application macOS introuvable après la compilation." >&2
    exit 1
  fi

  local staging_dir
  staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/harmonix-dmg.XXXXXX")"
  trap 'rm -rf "$staging_dir"' RETURN

  cp -R "$app_path" "$staging_dir/"
  ln -s /Applications "$staging_dir/Applications"

  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$staging_dir" \
    -ov \
    -format UDZO \
    "$DIST_DIR/${APP_NAME}-${VERSION}-macOS.dmg"

  ditto -c -k --sequesterRsrc --keepParent "$app_path" \
    "$DIST_DIR/${APP_NAME}-${VERSION}-macOS.zip"

  rm -rf "$staging_dir"
  trap - RETURN
}

build_ios() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "La cible iOS doit être construite depuis macOS." >&2
    exit 1
  fi

  echo "==> Construction iOS (IPA signée)"
  echo "Une équipe Apple et un profil de signature doivent être configurés dans Xcode."
  flutter build ipa --release

  local ipa_path
  ipa_path="$(find build/ios/ipa -maxdepth 1 -type f -name '*.ipa' -print -quit)"
  if [[ -z "$ipa_path" ]]; then
    echo "IPA introuvable après la compilation." >&2
    exit 1
  fi
  cp "$ipa_path" "$DIST_DIR/${APP_NAME}-${VERSION}.ipa"
}

build_web() {
  require_command ditto
  echo "==> Construction Web (ZIP)"
  flutter build web --release
  ditto -c -k --sequesterRsrc build/web \
    "$DIST_DIR/${APP_NAME}-${VERSION}-web.zip"
}

build_remote_desktop() {
  require_command gh
  echo "==> Déclenchement des builds Windows et Linux sur GitHub Actions"
  gh workflow run desktop-builds.yml
  echo "Build déclenché. Suivi : gh run watch"
  echo "Téléchargement à la fin : gh run download --dir dist/remote-desktop"
}

TARGET="${1:-all}"

if [[ "$TARGET" == "help" || "$TARGET" == "--help" || "$TARGET" == "-h" ]]; then
  usage
  exit 0
fi

require_command flutter

case "$TARGET" in
  all|android|macos|ios|web)
    prepare_dist
    echo "==> Installation des dépendances Flutter"
    flutter pub get
    ;;
esac

case "$TARGET" in
  all)
    build_android
    build_macos
    build_web
    ;;
  android)
    build_android
    ;;
  macos)
    build_macos
    ;;
  ios)
    build_ios
    ;;
  web)
    build_web
    ;;
  remote-desktop)
    build_remote_desktop
    ;;
  *)
    echo "Cible inconnue : $TARGET" >&2
    usage >&2
    exit 2
    ;;
esac

if [[ "$TARGET" != "remote-desktop" ]]; then
  echo "==> Terminé. Fichiers disponibles dans : $DIST_DIR"
  find "$DIST_DIR" -maxdepth 1 -type f -print
fi
