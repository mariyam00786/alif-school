import { Router } from 'express';

import {
  deleteDevDeviceToken,
  shouldUseLocalData,
  upsertDevDeviceToken,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  RegisterDeviceTokenSchema,
  UnregisterDeviceTokenSchema,
} from '../schemas/device-token.schema';
import { resolveRequestUser } from '../utils/auth-context';

const router = Router();

router.post('/register', async (req, res) => {
  const user = await resolveRequestUser(req);
  if (!user) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  try {
    const body = RegisterDeviceTokenSchema.parse(req.body);
    const payload = {
      profile_id: user.id,
      role: user.role,
      app_name: body.app_name,
      platform: body.platform,
      device_token: body.token,
      notifications_enabled: body.notifications_enabled ?? true,
      last_seen_at: new Date().toISOString(),
    };

    const { error } = await supabaseAdmin.from('notification_devices').upsert([payload], {
      onConflict: 'device_token',
      ignoreDuplicates: false,
    });

    if (error) {
      if (shouldUseLocalData(error)) {
        upsertDevDeviceToken(payload);
        res.status(201).json({ ok: true, source: 'dev-fallback' });
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json({ ok: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to register device token';
    res.status(400).json({ error: message });
  }
});

router.post('/unregister', async (req, res) => {
  const user = await resolveRequestUser(req);
  if (!user) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  try {
    const body = UnregisterDeviceTokenSchema.parse(req.body);

    const { error } = await supabaseAdmin
      .from('notification_devices')
      .delete()
      .eq('profile_id', user.id)
      .eq('device_token', body.token);

    if (error) {
      if (shouldUseLocalData(error)) {
        deleteDevDeviceToken(user.id, body.token);
        res.json({ ok: true, source: 'dev-fallback' });
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json({ ok: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to unregister device token';
    res.status(400).json({ error: message });
  }
});

export default router;
