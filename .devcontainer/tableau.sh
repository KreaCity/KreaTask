#!/bin/bash
# Dans l'atelier : dit où est le tableau, et le relance s'il ne tourne plus.
set -u
cd "$(dirname "$(readlink -f "$0")")/.."
if ! curl -sf http://127.0.0.1:8090/api/health >/dev/null 2>&1; then
  echo "Le tableau ne tournait pas, je le relance..."
  nohup bash -c 'SANS_NAVIGATEUR=1 ./demarrer' > /tmp/tableau.log 2>&1 &
  for _ in $(seq 1 40); do
    curl -sf http://127.0.0.1:8090/api/health >/dev/null 2>&1 && break
    sleep 0.25
  done
fi
BASE="https://${CODESPACE_NAME}-8090.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
echo
echo "Ton tableau :         $BASE"
echo "Ton administration :  $BASE/_/"
echo
