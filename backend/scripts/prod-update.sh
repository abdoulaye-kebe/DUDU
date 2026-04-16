#!/usr/bin/env bash
# Mise à jour production backend : deps + PM2 reload
# - Depuis la racine du monorepo : utiliser scripts/prod-update-backend.sh (git pull + ce script avec SKIP_GIT=1)
# - Depuis le dossier backend seul (clone dédié) :
#     bash scripts/prod-update.sh
#     bash scripts/prod-update.sh main
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BRANCH="${1:-main}"

cd "${BACKEND_DIR}"
echo "==> DuDu backend — ${BACKEND_DIR}"

if [[ ! -f .env ]]; then
  echo "Erreur : fichier .env absent. Copiez le modèle :"
  echo "  cp .env.example .env && nano .env"
  exit 1
fi

if [[ "${SKIP_GIT:-0}" != "1" ]]; then
  echo "==> git pull (${BRANCH})"
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git fetch origin "${BRANCH}" 2>/dev/null || true
    git pull origin "${BRANCH}" || git pull
  else
    echo "Pas de dépôt git dans backend/ — utilisez la racine du repo ou déployez les fichiers à la main."
  fi
else
  echo "==> SKIP_GIT=1 — pas de git pull ici (déjà fait à la racine)."
fi

echo "==> npm (dépendances production)"
if [[ -f package-lock.json ]]; then
  npm ci --omit=dev
else
  npm install --omit=dev
fi

if command -v pm2 >/dev/null 2>&1; then
  echo "==> PM2"
  if pm2 describe dudu-bac >/dev/null 2>&1; then
    pm2 reload ecosystem.config.cjs --update-env
  else
    pm2 start ecosystem.config.cjs
  fi
  pm2 save
  echo "OK — processus « dudu-bac » rechargé."
else
  echo "PM2 non installé — redémarrez avec : NODE_ENV=production npm start"
fi
