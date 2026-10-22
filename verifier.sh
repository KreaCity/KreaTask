#!/bin/bash
# Vérifie le kit comme sur une machine neuve : copie le dossier ailleurs, le
# lance avec son propre PocketBase sur une base vide, contrôle par l'API que
# les données et les images de démonstration sont là et que la page répond,
# puis arrête tout.
#
#   ./verifier.sh          copie le dossier tel qu'il est
#   ./verifier.sh --zip    part de l'archive ZIP du dernier commit (ce que
#                          donne « Download ZIP » sur GitHub : un dossier
#                          KreaTask-main), marquée en quarantaine comme un
#                          téléchargement Safari, puis renommée comme le dit
#                          le README
set -uo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
PORT="${PORT:-8197}"
BASE="http://127.0.0.1:${PORT}"
TMP="$(mktemp -d)"
DOSSIER="$TMP/KreaTask"
ECHECS=0

ok()   { echo "  ok    $1"; }
ko()   { echo "  ÉCHEC $1"; ECHECS=$((ECHECS + 1)); }
test_() { if eval "$2"; then ok "$1"; else ko "$1"; fi; }

nettoyer() {
  [ -n "${PID:-}" ] && kill "$PID" 2>/dev/null && wait "$PID" 2>/dev/null
  rm -rf "$TMP"
}
trap nettoyer EXIT

echo "1. Copie du kit dans un dossier neuf ($DOSSIER)"
if [ "${1:-}" = "--zip" ]; then
  # Chemin du kit dans son dépôt git (vide quand le kit EST la racine du dépôt)
  SOUS=$(cd "$KIT" && git rev-parse --show-prefix) || { echo "pas de dépôt git"; exit 1; }
  RACINE=$(cd "$KIT" && git rev-parse --show-toplevel)
  (cd "$RACINE" && git archive --format=zip --prefix=KreaTask-main/ "HEAD:${SOUS}" -o "$TMP/kit.zip") || { echo "git archive impossible"; exit 1; }
  xattr -w com.apple.quarantine "0083;$(printf %x "$(date +%s)");Safari;" "$TMP/kit.zip"
  # ditto, comme l'utilitaire d'archive de macOS, propage la quarantaine
  ditto -x -k "$TMP/kit.zip" "$TMP"
  mv "$TMP/KreaTask-main" "$DOSSIER"
  test_ "le ZIP est marqué en quarantaine, comme un téléchargement" \
    'xattr -p com.apple.quarantine "$DOSSIER/demarrer" >/dev/null 2>&1'
else
  rsync -a --exclude pb_data --exclude /pocketbase --exclude /pocketbase.exe "$KIT/" "$DOSSIER/"
fi
test_ "aucune base ni binaire dans la copie" '[ ! -e "$DOSSIER/pb_data" ] && [ ! -e "$DOSSIER/pocketbase" ]'
test_ "demarrer est exécutable" '[ -x "$DOSSIER/demarrer" ]'

echo "2. Lancement (./demarrer)"
# demarrer remplace son processus par PocketBase : ce PID est celui du serveur.
PORT="$PORT" SANS_NAVIGATEUR=1 "$DOSSIER/demarrer" >"$TMP/serveur.log" 2>&1 &
PID=$!
if curl -sf "$BASE/api/health" >/dev/null 2>&1; then
  echo "Le port $PORT est déjà pris par un autre serveur : arrête-le ou lance PORT=… ./verifier.sh"; exit 1
fi
for _ in $(seq 1 60); do curl -sf "$BASE/api/health" >/dev/null 2>&1 && break; sleep 0.25; done
test_ "le serveur répond" 'curl -sf "$BASE/api/health" >/dev/null'
if [ "$ECHECS" != 0 ]; then echo "Arrêt : le kit ne démarre pas. Journal :"; cat "$TMP/serveur.log"; exit 1; fi
test_ "le terminal affiche le lien de création du compte d'administration" 'grep -q "pbinstall" "$TMP/serveur.log"'
test_ "PocketBase 0.40.5" '"$DOSSIER/pocketbase" --version | grep -q "0.40.5"'

echo "3. Les données, lues sans connexion"
json() { curl -sf "$BASE$1"; }
compte() { json "$1" | python3 -c 'import json,sys; print(json.load(sys.stdin)["totalItems"])'; }
test_ "1 projet" '[ "$(compte /api/collections/projets/records)" = 1 ]'
test_ "6 cartes" '[ "$(compte /api/collections/cartes/records)" = 6 ]'
test_ "2 cartes par statut" '[ "$(json "/api/collections/cartes/records?perPage=50" | python3 -c "import json,sys,collections; c=collections.Counter(i[\"statut\"] for i in json.load(sys.stdin)[\"items\"]); print(sorted(c.items()))")" = "[('"'"'En cours'"'"', 2), ('"'"'Fait'"'"', 2), ('"'"'À faire'"'"', 2)]" ]'
test_ "chaque carte a un responsable et une échéance" '[ "$(json "/api/collections/cartes/records?perPage=50&filter=(responsable%3D%22%22%7C%7Cecheance%3D%22%22)" | python3 -c "import json,sys; print(json.load(sys.stdin)[\"totalItems\"])")" = 0 ]'
test_ "2 utilisateurs, nom visible" '[ "$(json "/api/collections/users/records" | python3 -c "import json,sys; print(sorted(u[\"name\"] for u in json.load(sys.stdin)[\"items\"]))")" = "['"'"'Karim'"'"', '"'"'Léa'"'"']" ]'
test_ "Léa et Karim sans photo (pastilles à initiales)" '[ "$(json "/api/collections/users/records" | python3 -c "import json,sys; print(sum(1 for u in json.load(sys.stdin)[\"items\"] if u[\"avatar\"]))")" = 0 ]'
test_ "l'e-mail des utilisateurs reste masqué" '! json "/api/collections/users/records" | grep -q "exemple.test"'

echo "4. Les images"
image() { # collection champ
  json "/api/collections/$1/records" | python3 -c "
import json,sys
for r in json.load(sys.stdin)['items']:
    print(r['collectionId'] + '/' + r['id'] + '/' + r['$2'])"
}
for chemin in $(image projets couverture); do
  test_ "image servie : ${chemin##*/}" 'curl -sf "$BASE/api/files/$chemin" | file - | grep -q JPEG'
done
test_ "visuel d'en-tête" 'curl -sf "$BASE/images/entete.jpg" | file - | grep -q JPEG'

echo "5. La page"
test_ "la page répond et charge le SDK" 'curl -sf "$BASE/" | grep -q "pocketbase.umd.js"'
test_ "le SDK est servi" 'curl -sf "$BASE/pocketbase.umd.js" | grep -q "PocketBase"'

echo "6. L'écriture est fermée (elle s'ouvre pendant le live)"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{"titre":"test"}' "$BASE/api/collections/cartes/records")
test_ "créer une carte sans compte est refusé ($CODE)" '[ "$CODE" = 400 ] || [ "$CODE" = 403 ]'

echo "7. Le tableau d'administration"
(cd "$DOSSIER" && ./pocketbase superuser upsert verif@exemple.test verif-cartes-2026 --dir ./pb_data >/dev/null 2>&1)
JETON=$(curl -sf -X POST -H "Content-Type: application/json" \
  -d '{"identity":"verif@exemple.test","password":"verif-cartes-2026"}' \
  "$BASE/api/collections/_superusers/auth-with-password" | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')
COLLECTIONS=$(curl -sf -H "Authorization: $JETON" "$BASE/api/collections?perPage=100" | python3 -c 'import json,sys; print(" ".join(sorted(c["name"] for c in json.load(sys.stdin)["items"] if not c["system"])))')
test_ "collections visibles : $COLLECTIONS" '[ "$COLLECTIONS" = "cartes projets users" ]'

echo
if [ "$ECHECS" = 0 ]; then echo "Tout est bon."; else echo "$ECHECS échec(s). Journal du serveur :"; cat "$TMP/serveur.log"; fi
exit "$ECHECS"
