#!/usr/bin/env bash
# Déploiement backend depuis la RACINE du repo (là où est .git/)
# Usage :
#   ./scripts/prod-update-backend.sh
#   ./scripts/prod-update-backend.sh main
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRANCH="${1:-main}"

cd "${ROOT}"
echo "==> Git pull (${ROOT})"
if git rev-parse --git-dir >/dev/null 2>&1; then
  git pull origin "${BRANCH}" || git pull
else
  echo "Avertissement : pas de dépôt git à la racine — exécutez backend/scripts/prod-update.sh depuis le dossier backend."
fi

export SKIP_GIT=1
exec bash "${ROOT}/backend/scripts/prod-update.sh" "${BRANCH}"
