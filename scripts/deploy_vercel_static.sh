#!/usr/bin/env bash
# Деплой уже собранного Mini App на Vercel без загрузки всего репозитория
# (папка build/ в .gitignore — vercel deploy из frontend/ почти ничего не шлёт).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
API="${API_BASE_URL:-https://gnatgminiapp-production.up.railway.app}"
flutter build web --release \
  --target lib/mini_app/main.dart \
  --dart-define=API_BASE_URL="$API" \
  --dart-define=ENVIRONMENT=production
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp -a "$ROOT/build/web/." "$TMP/"
mkdir -p "$TMP/.vercel"
cp "$ROOT/.vercel/project.json" "$TMP/.vercel/project.json"
cd "$TMP"
exec npx --yes vercel@latest deploy --prod --yes --scope team_ANfvyxYSZvof2GG7MTFlzsvx
