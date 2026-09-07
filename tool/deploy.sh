#!/usr/bin/env bash
# Masters of Magic 2 — one-command release.
#
# The release ritual (ruled 2026-08-25/26, "one release, one number"):
#   ContentVersion.current == pubspec's +N == About panel's "release N"
#   == the server doc config/content.version — and the SERVER DOC MOVES LAST,
#   after hosting is live, so no client is ever gated by a number the build
#   behind it does not carry.
#
# Usage:  tool/deploy.sh [--rules] [--skip-tests] [--dry-run] [--yes]
#   --rules       also deploy firestore.rules (only when they changed)
#   --skip-tests  skip both suites (you'd better have a reason)
#   --dry-run     preflight + summary only; build, deploy and doc untouched
#   --yes         no confirmation prompt
set -euo pipefail

PROJECT=mastersofmagic2
SITE="https://$PROJECT.web.app"
DOC_URL="https://firestore.googleapis.com/v1/projects/$PROJECT/databases/(default)/documents/config/content"

RULES=0; SKIP_TESTS=0; DRY=0; YES=0
for a in "$@"; do
  case "$a" in
    --rules) RULES=1 ;;
    --skip-tests) SKIP_TESTS=1 ;;
    --dry-run) DRY=1 ;;
    --yes) YES=1 ;;
    *) echo "unknown flag: $a" >&2; exit 2 ;;
  esac
done

cd "$(dirname "$0")/.."
step() { printf '\n\033[1;33m▶ %s\033[0m\n' "$*"; }
die()  { printf '\n\033[1;31m✖ %s\033[0m\n' "$*" >&2; exit 1; }
ok()   { printf '\033[1;32m✔ %s\033[0m\n' "$*"; }

# ---- 1. The three numbers in the repo must agree --------------------------
step "Preflight: version ritual"
CODE_V=$(grep -oE 'static const int current = [0-9]+' lib/game/content_version.dart | grep -oE '[0-9]+$')
APP_V=$(grep -oE "const String appVersion = '[^']+'" lib/game/app_version.dart | grep -oE "[0-9]+\.[0-9]+\.[0-9]+")
PUB_LINE=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')
PUB_APP=${PUB_LINE%%+*}; PUB_BUILD=${PUB_LINE##*+}
[[ "$PUB_BUILD" == "$CODE_V" ]] || die "pubspec +$PUB_BUILD != ContentVersion.current $CODE_V (version_sync_test would fail too)"
[[ "$PUB_APP" == "$APP_V" ]]   || die "pubspec $PUB_APP != appVersion $APP_V"
ok "release $CODE_V · app $APP_V · pubspec $PUB_LINE"

# ---- 2. Git must be clean and on main --------------------------------------
step "Preflight: git"
[[ -z "$(git status --porcelain)" ]] || die "working tree is dirty — commit or stash first"
BRANCH=$(git rev-parse --abbrev-ref HEAD)
[[ "$BRANCH" == "main" ]] || echo "  ⚠ on branch '$BRANCH', not main"
ok "clean at $(git rev-parse --short HEAD) on $BRANCH"

# ---- 3. What is live right now ---------------------------------------------
step "Preflight: live state"
TOKEN=$(gcloud auth print-access-token 2>/dev/null) || die "gcloud has no token — run: gcloud auth login"
LIVE_DOC=$(curl -sf -H "Authorization: Bearer $TOKEN" "$DOC_URL" | jq -r '.fields.version.integerValue') \
  || die "could not read $DOC_URL"
LIVE_BUILD=$(curl -sf "$SITE/version.json" | jq -r '.build_number') || die "could not read $SITE/version.json"
echo "  server doc config/content.version = $LIVE_DOC"
echo "  deployed build_number             = $LIVE_BUILD"
if (( LIVE_DOC >= CODE_V )); then
  die "the server doc is already at $LIVE_DOC but the code says $CODE_V — bump ContentVersion.current AND pubspec's +N first (the batch-opening rule)"
fi
ok "this release moves $LIVE_DOC → $CODE_V"

# ---- 4. Summary + confirmation ---------------------------------------------
step "Plan"
echo "  1. tests (engine + app)$( ((SKIP_TESTS)) && echo '  [SKIPPED]')"
echo "  2. flutter clean && flutter build web --pwa-strategy=none && cp web/flutter_service_worker.js build/web/"
echo "  3. firebase deploy --only hosting --project $PROJECT"
((RULES)) && echo "  4. firebase deploy --only firestore:rules --project $PROJECT"
echo "  5. verify $SITE/version.json reports build $CODE_V"
echo "  6. set config/content.version = $CODE_V   (LAST — the gate flips here)"
echo "  7. git tag release-$CODE_V"
if ((DRY)); then ok "dry run — stopping before anything changes"; exit 0; fi
if ! ((YES)); then
  read -r -p "Proceed with release $CODE_V? [y/N] " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]] || die "aborted"
fi

# ---- 5. Tests ---------------------------------------------------------------
if ! ((SKIP_TESTS)); then
  step "Tests: engine"
  (cd packages/mom_engine && dart test) | tail -1
  step "Tests: app"
  flutter test | tail -1
  ok "both suites green"
fi

# ---- 6. Build ---------------------------------------------------------------
step "Build"
flutter clean >/dev/null
flutter build web --pwa-strategy=none
cp web/flutter_service_worker.js build/web/
BUILT=$(jq -r '.build_number' build/web/version.json)
[[ "$BUILT" == "$CODE_V" ]] || die "build/web/version.json says build $BUILT, expected $CODE_V"
ok "built release $CODE_V"

# ---- 7. Deploy hosting (and rules on request) ------------------------------
step "Deploy: hosting"
firebase deploy --only hosting --project "$PROJECT"
if ((RULES)); then
  step "Deploy: firestore rules"
  firebase deploy --only firestore:rules --project "$PROJECT"
fi

# ---- 8. Verify the live build before touching the gate ---------------------
step "Verify: live build"
for i in 1 2 3 4 5 6; do
  NOW=$(curl -sf "$SITE/version.json" | jq -r '.build_number' || echo '?')
  [[ "$NOW" == "$CODE_V" ]] && break
  echo "  live build_number is $NOW, waiting for $CODE_V… ($i/6)"; sleep 5
done
[[ "$NOW" == "$CODE_V" ]] || die "hosting still serves build $NOW — NOT moving the server doc (clients would be gated against a build that is not there)"
ok "$SITE serves build $CODE_V"

# ---- 9. The server doc moves LAST ------------------------------------------
step "Gate: config/content.version → $CODE_V"
TOKEN=$(gcloud auth print-access-token)
curl -sf -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$DOC_URL?updateMask.fieldPaths=version" \
  -d "{\"fields\":{\"version\":{\"integerValue\":\"$CODE_V\"}}}" >/dev/null \
  || die "PATCH of the server doc failed — set config/content.version = $CODE_V by hand in the Firebase console"
AFTER=$(curl -sf -H "Authorization: Bearer $TOKEN" "$DOC_URL" | jq -r '.fields.version.integerValue')
[[ "$AFTER" == "$CODE_V" ]] || die "server doc reads $AFTER after the write"
ok "server doc is $AFTER — every client on an older build is now asked to refresh"

# ---- 10. Tag ----------------------------------------------------------------
step "Tag"
if git rev-parse "release-$CODE_V" >/dev/null 2>&1; then
  echo "  tag release-$CODE_V already exists"
else
  git tag -a "release-$CODE_V" -m "Release $CODE_V (app $APP_V)"
  ok "tagged release-$CODE_V (push with: git push origin main --tags)"
fi

printf '\n\033[1;32m🎉 Release %s is live at %s\033[0m\n' "$CODE_V" "$SITE"
echo "Next batch opens with: bump ContentVersion.current + pubspec's +N to $((CODE_V + 1)) as its first commit."
