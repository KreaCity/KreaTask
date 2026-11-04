#!/bin/bash
# Dans l'atelier : crée ton compte d'administration (ou change son mot de passe).
set -eu
cd "$(dirname "$(readlink -f "$0")")/.."
echo "Ton compte d'administration reste dans ton atelier."
read -r -p "Ton e-mail : " EMAIL
read -r -s -p "Choisis un mot de passe (10 caractères au moins, il ne s'affiche pas) : " MOT
echo
./pocketbase superuser upsert "$EMAIL" "$MOT" --dir ./pb_data
tableau
