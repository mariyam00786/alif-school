import { createClient } from '@supabase/supabase-js';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

import { config } from './config';

export const supabaseAdmin = createClient(config.supabaseUrl, config.supabaseServiceRoleKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
});

export function initFirebaseMessaging() {
  if (getApps().length === 0 && config.firebasePrivateKey) {
    try {
      initializeApp({
        credential: cert({
          projectId: config.firebaseProjectId,
          clientEmail: config.firebaseClientEmail,
          privateKey: config.firebasePrivateKey,
        }),
      });
    } catch (err) {
      console.warn('Firebase initialization skipped for local dev:', (err as Error).message);
    }
  }

  try {
    return getMessaging();
  } catch {
    return null as any;
  }
}
