#!/bin/bash
# Dans l'atelier : dit où est le tableau, et le relance s'il ne tourne plus.
set -u
cd "$(dirname "$(readlink -f "$0")")/.."

en_route() { curl -sf http://127.0.0.1:8090/api/health >/dev/null 2>&1; }

if ! en_route; then
  # setsid : le serveur survit à la fermeture du terminal qui l'a lancé.
  SANS_NAVIGATEUR=1 setsid nohup ./demarrer > /tmp/tableau.log 2>&1 < /dev/null &
  for _ in $(seq 1 120); do
    en_route && break
    sleep 0.25
  done
fi

if ! en_route; then
  echo "❌ Le tableau ne démarre pas. Voici ce qu'il dit :"
  tail -5 /tmp/tableau.log
  exit 1
fi

# Hors d'un terminal de l'atelier, ces deux variables ne sont pas toujours posées.
[ -n "${CODESPACE_NAME:-}" ] || . /workspaces/.codespaces/shared/.env 2>/dev/null || true
BASE="https://${CODESPACE_NAME:-}-8090.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
echo
echo "Ton tableau :         $BASE"
echo "Ton administration :  $BASE/_/"
echo
