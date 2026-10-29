import 'dotenv/config';

export const config = {
  port: Number(process.env.PORT ?? 4000),
  enforceDevAuth: String(process.env.ENFORCE_DEV_AUTH ?? 'false').toLowerCase() === 'true',
  allowLocalDataFallback:
    String(process.env.ALLOW_LOCAL_DATA_FALLBACK ?? 'false').toLowerCase() === 'true',
  forceLiveDb:
    String(
      process.env.FORCE_LIVE_DB ?? (process.env.NODE_ENV === 'production' ? 'true' : 'false')
    ).toLowerCase() === 'true',
  requireSupabaseOnBoot:
    String(process.env.REQUIRE_SUPABASE_ON_BOOT ?? 'true').toLowerCase() === 'true',
  supabaseUrl: process.env.SUPABASE_URL ?? '',
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY ?? '',
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID ?? '',
  firebaseClientEmail: process.env.FIREBASE_CLIENT_EMAIL ?? '',
  firebasePrivateKey: (process.env.FIREBASE_PRIVATE_KEY ?? '').replace(/\\n/g, '\n'),
};

export function assertEnv(): void {
  const required = [
    ['SUPABASE_URL', config.supabaseUrl],
    ['SUPABASE_SERVICE_ROLE_KEY', config.supabaseServiceRoleKey],
    ['FIREBASE_PROJECT_ID', config.firebaseProjectId],
    ['FIREBASE_CLIENT_EMAIL', config.firebaseClientEmail],
    ['FIREBASE_PRIVATE_KEY', config.firebasePrivateKey],
  ];

  const missing = required.filter(([, value]) => !value).map(([name]) => name);
  if (missing.length > 0) {
    throw new Error(`Missing required env vars: ${missing.join(', ')}`);
  }
}
