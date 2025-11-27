# 🔧 Исправление проблемы с Vercel

## Проблема
Vercel пытается собрать Flutter, но не может (нет Flutter в окружении).

## ✅ Решение

### Вариант 1: Отключить автоматический деплой в Vercel (рекомендуется)

1. Зайдите в Vercel Dashboard
2. Откройте ваш проект
3. Settings → Git
4. **Отключите автоматический деплой** (или удалите подключение к Git)
5. Используйте только GitHub Actions для деплоя

### Вариант 2: Обновить настройки проекта в Vercel

1. Зайдите в Vercel Dashboard → ваш проект
2. Settings → General
3. **Build & Development Settings:**
   - Build Command: оставьте **пустым**
   - Output Directory: `build/web`
   - Install Command: оставьте **пустым**
4. Сохраните

Но это не поможет, так как Vercel все равно попытается собрать.

---

## 🎯 Правильное решение: Использовать GitHub Actions

### Шаг 1: Получите Vercel токены

1. Vercel → Settings → Tokens
2. Создайте новый токен
3. Скопируйте его

### Шаг 2: Получите Project ID и Org ID

После создания проекта в Vercel:
- Project ID: Settings проекта → General → Project ID
- Org ID: Settings аккаунта → General → Team ID

### Шаг 3: Добавьте Secrets в GitHub

1. Репозиторий → Settings → Secrets and variables → Actions
2. Добавьте:
   ```
   VERCEL_TOKEN = ваш_токен
   VERCEL_ORG_ID = ваш_org_id
   VERCEL_PROJECT_ID = ваш_project_id
   API_BASE_URL = https://gnatgminiapp-production.up.railway.app
   ```

### Шаг 4: Отключите автоматический деплой в Vercel

1. Vercel → ваш проект → Settings → Git
2. **Отключите** автоматический деплой (или удалите подключение)

### Шаг 5: Запушьте код

```bash
cd /Users/nikolasgevorkan/GNA_tg_store/frontend
git add vercel.json .github/workflows/deploy.yml
git commit -m "Update Vercel config"
git push origin main
```

GitHub Actions автоматически соберет Flutter и задеплоит на Vercel!

---

## 🚀 Альтернатива: Деплой через Vercel CLI (для первого раза)

Если хотите задеплоить прямо сейчас:

```bash
# Установите Vercel CLI
npm i -g vercel

# Войдите в Vercel
vercel login

# Деплой из папки build/web
cd /Users/nikolasgevorkan/GNA_tg_store/frontend/build/web
vercel --prod
```

Но это задеплоит только один раз. Для автоматического деплоя используйте GitHub Actions.

