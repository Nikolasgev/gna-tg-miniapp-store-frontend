# 🚀 Деплой Flutter на Vercel

## Проблема
Vercel не поддерживает Flutter напрямую (нет Flutter в окружении сборки).

## ✅ Решение: GitHub Actions

### Шаг 1: Получите Vercel токены

1. Зайдите на [vercel.com](https://vercel.com)
2. Settings → Tokens
3. Создайте новый токен: "Create Token"
4. Скопируйте токен

### Шаг 2: Создайте проект в Vercel

1. В Vercel: "Add New Project"
2. Подключите репозиторий `tg-store-frontend`
3. **Не настраивайте Build Command** (будет через GitHub Actions)
4. После создания проекта скопируйте:
   - **Project ID** (из Settings проекта)
   - **Org ID** (из Settings аккаунта)

### Шаг 3: Добавьте Secrets в GitHub

1. Зайдите в репозиторий на GitHub
2. Settings → Secrets and variables → Actions
3. Добавьте следующие secrets:

```
VERCEL_TOKEN = ваш_vercel_токен
VERCEL_ORG_ID = ваш_org_id
VERCEL_PROJECT_ID = ваш_project_id
API_BASE_URL = https://your-backend.railway.app
```

### Шаг 4: Закоммитьте и запушьте

```bash
cd /Users/nikolasgevorkan/GNA_tg_store/frontend
git add .github/workflows/deploy.yml vercel.json
git commit -m "Add GitHub Actions for Vercel deployment"
git push origin main
```

### Шаг 5: Проверка

После push в `main`:
1. GitHub Actions автоматически запустится
2. Соберет Flutter Web
3. Задеплоит на Vercel

---

## 🔄 Альтернатива: Cloudflare Pages (проще!)

Cloudflare Pages поддерживает GitHub Actions напрямую:

1. Зайдите на [pages.cloudflare.com](https://pages.cloudflare.com)
2. "Create a project" → "Connect to Git"
3. Выберите репозиторий `tg-store-frontend`
4. Настройки:
   - **Build command**: `flutter build web --target lib/mini_app/main.dart --release --dart-define=API_BASE_URL=https://your-backend.railway.app`
   - **Build output directory**: `build/web`
   - **Root directory**: `/`
   - **Environment variables**: 
     - `FLUTTER_VERSION=3.24.0`
     - `API_BASE_URL=https://your-backend.railway.app`

Но Cloudflare тоже не имеет Flutter по умолчанию, поэтому лучше использовать GitHub Actions.

---

## 🎯 Самый простой вариант: Собрать локально и задеплоить

### Шаг 1: Соберите локально

```bash
cd /Users/nikolasgevorkan/GNA_tg_store/frontend

# Замените URL на ваш реальный backend URL
flutter build web --target lib/mini_app/main.dart --release \
  --dart-define=API_BASE_URL=https://your-backend.railway.app
```

### Шаг 2: Деплой на Vercel через CLI

```bash
# Установите Vercel CLI (если еще не установлен)
npm i -g vercel

# Войдите в Vercel
vercel login

# Деплой из папки build/web
cd build/web
vercel --prod
```

### Шаг 3: Настройка автоматического деплоя

После первого деплоя Vercel создаст проект. Затем:

1. В Vercel Dashboard → Settings → Git
2. Подключите репозиторий
3. **Отключите автоматический деплой** (Build Command оставьте пустым)
4. Используйте GitHub Actions для сборки и деплоя

---

## 📝 Рекомендация

**Используйте GitHub Actions** (уже настроено):
- ✅ Автоматический деплой при push
- ✅ Flutter собирается в правильном окружении
- ✅ Не нужно собирать локально

Просто добавьте secrets в GitHub и запушьте код!

