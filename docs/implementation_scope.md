# Phase 1 Deliverable Scope

This repository now includes:

- Monorepo scaffold for Flutter apps and Node API.
- Shared Flutter design system package (tokens, typography, spacing, reusable components).
- Supabase CLI project with FRD-aligned migration, RLS, report views, and seed data.
- Firebase FCM integration scaffold in backend and infra docs.

## FRD + Reference Chart Alignment Notes

- Category model mirrors paper chart structure: category -> sub-activity.
- Ratings map to marks using chart rules: excellent=10, satisfactory=5, needs improvement=2, not done=0.
- Quran recitation activities support quantity capture (`has_quantity=true`).
- OTP authentication split is preserved: Supabase Auth for OTP, Firebase for FCM only.

## Pending Input

- Brand logo palette extraction is pending until final logo asset is provided.
- Supabase cloud project link and push require user account auth and project ref.
