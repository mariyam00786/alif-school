
# Alif Online Moral School

Scaffold for the Alif Online Moral School Activity Tracking System, based on the FRD and the paper Ihthisab chart.

## What is included in this phase

- Flutter app scaffold for Student/Parent + Teacher module.
- Flutter app scaffold for Admin module (web-first, mobile-capable).
- Shared Flutter design system package (tokens + reusable components).
- Node/Express backend scaffold with Supabase and Firebase integrations.
- Supabase migration + seed based on FRD section 5 and chart scoring rules.
- Firebase setup scaffold for FCM only.

## Architecture split (confirmed)

- OTP authentication: Supabase Auth (phone OTP).
- Push notifications: Firebase Cloud Messaging.

## Repo structure

- `apps/alif_student_teacher`: Mobile-first app for Student/Parent and Teacher.
- `apps/alif_admin`: Admin app scaffold for web and mobile access.
- `packages/alif_design_system`: Shared style system and UI primitives.
- `services/api`: Node backend scaffold.
- `supabase`: Supabase CLI config, migrations, seeds.
- `infra/firebase`: Firebase CLI config templates and setup notes.
- `docs`: FRD copy, PDF reference, and implementation notes.

## Local prerequisites

- Flutter SDK
- Node.js + npm
- Docker Desktop (required for local Supabase runtime)

## Setup

1. Install npm dependencies at repo root:
   - `npm install`
2. Install Flutter packages:
   - `cd packages/alif_design_system && flutter pub get`
   - `cd ../../apps/alif_student_teacher && flutter pub get`
   - `cd ../alif_admin && flutter pub get`
3. API env setup:
   - Copy `services/api/.env.example` to `.env` and fill values.
4. Admin app env setup:
   - Copy `apps/alif_admin/env/dev.example.json` to `apps/alif_admin/env/dev.json`.
   - Set `ALIF_API_BASE_URL` inside `dev.json`.

## Supabase workflow

- Start local stack: `npm run supabase:start`
- Apply migrations and seed locally: `npm run supabase:reset`
- Link remote cloud project: `npm run supabase:link -- --project-ref <your_project_ref>`
- Push migrations to remote: `npm run supabase:push`

## Firebase workflow

- Login: `npm run firebase:login`
- Follow setup in `infra/firebase/README.md`

## Run apps

- Student/Teacher app: `npm run app:student`
- Admin app: `npm run app:admin` (reads from `apps/alif_admin/env/dev.json`)
- API dev server: `npm run api:dev`

## FRD/source references stored in repo

- `docs/Alif_Moral_School_FRD.md`
- `docs/alif_ihthisab_chart_reference.pdf`

## Notes

- Design system palette currently uses FRD-compatible defaults and includes a clear TODO to replace token colors from the final logo palette once provided.
- This phase is complete for scaffold + style system + schema/seed setup. Feature-by-feature implementation can proceed according to FRD section 13 timeline.
