import { Router } from 'express';

import {
  createDevNotification,
  deleteDevNotification,
  listDevNotifications,
  shouldUseLocalData,
  updateDevNotification,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  CreateNotificationSchema,
  ListNotificationsQuerySchema,
  UpdateNotificationSchema,
} from '../schemas/notification.schema';

const router = Router();
const NOTIFICATION_SELECT =
  'id, title, body, target_type, target_id, scheduled_at, sent_at, created_at';

router.get('/', async (req, res) => {
  const query = ListNotificationsQuerySchema.parse(req.query);

  try {
    let request = supabaseAdmin
      .from('notifications')
      .select(NOTIFICATION_SELECT)
      .order('created_at', { ascending: false });

    if (query.target_type) {
      request = request.eq('target_type', query.target_type);
    }

    if (query.target_id) {
      request = request.eq('target_id', query.target_id);
    }

    const { data, error } = await request;

    if (error) {
      if (shouldUseLocalData(error)) {
        res.json(listDevNotifications(query));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      res.json(listDevNotifications(query));
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to fetch notifications';
    res.status(500).json({ error: msg });
  }
});

router.post('/', async (req, res) => {
  try {
    const body = CreateNotificationSchema.parse(req.body);

    const payload = {
      ...body,
      sent_at: body.scheduled_at ? null : new Date().toISOString(),
    };

    const { data, error } = await supabaseAdmin
      .from('notifications')
      .insert([payload])
      .select(NOTIFICATION_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        res.status(201).json(createDevNotification(body));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json(data);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = CreateNotificationSchema.parse(req.body);
      res.status(201).json(createDevNotification(body));
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to create notification';
    res.status(400).json({ error: msg });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const body = UpdateNotificationSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('notifications')
      .update(body)
      .eq('id', req.params.id)
      .select(NOTIFICATION_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const updated = updateDevNotification(req.params.id, body);
        if (!updated) {
          res.status(404).json({ error: 'Notification not found' });
          return;
        }

        res.json(updated);
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = UpdateNotificationSchema.parse(req.body);
      const updated = updateDevNotification(req.params.id, body);
      if (!updated) {
        res.status(404).json({ error: 'Notification not found' });
        return;
      }

      res.json(updated);
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to update notification';
    res.status(400).json({ error: msg });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const { error } = await supabaseAdmin
      .from('notifications')
      .delete()
      .eq('id', req.params.id);

    if (error) {
      if (shouldUseLocalData(error)) {
        const deleted = deleteDevNotification(req.params.id);
        if (!deleted) {
          res.status(404).json({ error: 'Notification not found' });
          return;
        }

        res.status(204).send();
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(204).send();
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const deleted = deleteDevNotification(req.params.id);
      if (!deleted) {
        res.status(404).json({ error: 'Notification not found' });
        return;
      }

      res.status(204).send();
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to delete notification';
    res.status(500).json({ error: msg });
  }
});

export default router;
