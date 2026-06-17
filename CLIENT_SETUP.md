# Alif Admin — Client Setup Guide

This guide walks you through setting up the project from scratch using a **Supabase cloud project** (no Docker required).

---

## Prerequisites

Install the following before starting:

| Tool | Download |
|------|----------|
| **Node.js 20+** | https://nodejs.org |
| **Flutter SDK 3.22+** | https://docs.flutter.dev/get-started/install |
| **Chrome browser** | https://www.google.com/chrome (for web app) |

> Supabase CLI is bundled with this project — no separate install needed.

---

## Step 1 — Install dependencies

```bash
npm install
```

Then install Flutter packages:

```bash
cd packages/alif_design_system && flutter pub get && cd ../..
cd apps/alif_admin && flutter pub get && cd ../..
cd apps/alif_student_teacher && flutter pub get && cd ../..
```

---

## Step 2 — Create a Supabase cloud project

1. Go to [https://supabase.com](https://supabase.com) and sign in (or create a free account).
2. Click **New project**.
3. Set a project name (e.g. `alif-school`), choose your region, and set a database password. **Save the password.**
4. Wait for the project to be provisioned (~1–2 minutes).

---

## Step 3 — Get your Supabase credentials

In the Supabase dashboard, go to your project → **Settings → API**.

Note down:
- **Project URL** — looks like `https://xxxxxxxxxxxx.supabase.co`
- **Project Ref** — the `xxxxxxxxxxxx` part of the URL (also shown in Settings → General)
- **service_role key** — under "Project API keys" (keep this secret!)
- **anon key** — under "Project API keys"

---

## Step 4 — Link the Supabase CLI to your cloud project

```bash
npx supabase login
```

This opens your browser to authenticate with Supabase. Then:

```bash
npm run supabase:link -- --project-ref YOUR_PROJECT_REF
```

Enter your **database password** when prompted.

---

## Step 5 — Push the database schema and seed data

This applies all migrations and loads the default seed data (activity categories, ratings, etc.):

```bash
npm run supabase:push
```

To also run the seed:

```bash
npx supabase db push && npx supabase db seed
```

---

## Step 6 — Configure the API environment

```bash
cd services/api
cp .env.example .env
```

Open `services/api/.env` and fill in the values:

```env
PORT=4000
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-from-step-3

# Firebase (for push notifications — fill in after Firebase setup)
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

> Firebase is only needed for push notifications. The app works without it for now — just leave those values as-is and the API will start in degraded mode.

---

## Step 7 — Configure the Admin Flutter app

```bash
cd apps/alif_admin/env
cp dev.example.json dev.json
```

Open `apps/alif_admin/env/dev.json` and set your API URL:

```json
{
  "ALIF_API_BASE_URL": "http://localhost:4000/api"
}
```

---

## Step 8 — Start the API server

```bash
cd services/api
npm run dev
```

Verify it's running:

```
GET http://localhost:4000/health
```

---

## Step 9 — Run the apps

Open separate terminals for each app:

```bash
# Admin web app
npm run app:admin

# Student / Teacher app
npm run app:student
```

Both will open in Chrome automatically.

---

## Quick reference — all scripts

| Command | Description |
|---------|-------------|
| `npm run app:admin` | Run Admin app in Chrome |
| `npm run app:student` | Run Student/Teacher app in Chrome |
| `npm run api:dev` | Start the Node.js API server |
| `npm run supabase:link -- --project-ref <ref>` | Link to a Supabase cloud project |
| `npm run supabase:push` | Push all migrations to the linked project |
| `npm run supabase:start` | Start local Supabase (requires Docker) |
| `npm run supabase:reset` | Reset local DB with migrations + seed |
| `npm run firebase:login` | Authenticate Firebase CLI |

---

## Troubleshooting

**`supabase: command not found`**  
Run `npm install` first. The CLI is installed locally — use `npx supabase ...` or the npm scripts.

**API fails to start with missing env vars**  
Check that `services/api/.env` exists and all `SUPABASE_*` values are filled.

**Flutter app shows "Connection refused"**  
Make sure the API server is running (`npm run api:dev`) before launching the Flutter apps.

**`supabase db push` fails with auth error**  
Re-run `npx supabase login` and `npm run supabase:link` with the correct project ref.

---

## Folder structure reference

```
alif/
├── apps/
│   ├── alif_admin/          ← Admin web app (Flutter)
│   └── alif_student_teacher/ ← Student/Teacher app (Flutter)
├── packages/
│   └── alif_design_system/  ← Shared UI components
├── services/
│   └── api/                 ← Node.js backend (.env goes here)
├── supabase/
│   ├── config.toml
│   ├── migrations/          ← All DB schema files
│   └── seed.sql             ← Default data
└── infra/firebase/          ← Firebase FCM setup notes
```
