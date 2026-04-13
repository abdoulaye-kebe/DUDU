#!/usr/bin/env sh
# POST candidature livreur (drivers/apply)
# Usage:
#   API=https://www.dudugroup.sn/api/v1 ./creer-livreur-curl.sh
#   PAYLOAD=payload-livreur-apply-nouveau.json API=https://www.dudugroup.sn/api/v1 ./creer-livreur-curl.sh

DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
API="${API:-http://127.0.0.1:3000/api/v1}"
PAYLOAD="${PAYLOAD:-payload-livreur-apply.json}"

curl -sS -w "\nHTTP_CODE:%{http_code}\n" -X POST "${API}/drivers/apply" \
  -H "Content-Type: application/json" \
  --data-binary @"${DIR}/${PAYLOAD}"
