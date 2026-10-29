import { Router } from 'express';
import { z } from 'zod';

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
import { sendNotificationPush } from '../services/push-delivery.service';
import { reminderScheduler } from '../services/reminder-scheduler.service';

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

    let pushDelivery: Awaited<ReturnType<typeof sendNotificationPush>> | null = null;
    if (!body.scheduled_at) {
      pushDelivery = await sendNotificationPush({
        notificationId: data.id,
        title: data.title,
        body: data.body,
        targetType: data.target_type,
        targetId: data.target_id,
      });
    }

    res.status(201).json(
      pushDelivery
        ? {
            ...data,
            push_delivery: pushDelivery,
          }
        : data
    );
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

// Device Token Management
const RegisterDeviceTokenSchema = z.object({
  device_token: z.string().min(1),
  platform: z.enum(['android', 'ios', 'web', 'macos', 'windows', 'linux', 'unknown']),
  app_name: z.enum(['admin', 'student_teacher']),
});

// Register or update device token
router.post('/device-tokens/register', async (req, res) => {
  try {
    const body = RegisterDeviceTokenSchema.parse(req.body);
    
    // Extract profile ID from JWT token
    const authHeader = req.header('authorization') ?? '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
    
    if (!token) {
      res.status(401).json({ error: 'Missing Bearer token' });
      return;
    }

    // Decode JWT to get user ID (profile_id)
    const { data, error: verifyError } = await supabaseAdmin.auth.getUser(token);
    if (verifyError || !data.user?.id) {
      res.status(401).json({ error: 'Invalid token' });
      return;
    }

    const profileId = data.user.id;
    const role = req.header('x-alif-role') || 'student';

    // Upsert device token
    const { data: deviceData, error } = await supabaseAdmin
      .from('notification_devices')
      .upsert(
        {
          profile_id: profileId,
          device_token: body.device_token,
          platform: body.platform,
          app_name: body.app_name,
          role: role,
          last_seen_at: new Date().toISOString(),
        },
        {
          onConflict: 'profile_id,app_name,device_token',
        }
      )
      .select()
      .single();

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    res.json({
      id: deviceData.id,
      device_token: deviceData.device_token,
      notifications_enabled: deviceData.notifications_enabled,
    });
  } catch (err) {
    if (err instanceof z.ZodError) {
      res.status(400).json({ error: 'Invalid request body', details: err.errors });
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to register device token';
    res.status(500).json({ error: msg });
  }
});

// Update notification preference
router.put('/device-tokens/:id/preference', async (req, res) => {
  try {
    const { notifications_enabled } = z
      .object({ notifications_enabled: z.boolean() })
      .parse(req.body);

    // Extract profile ID from JWT token
    const authHeader = req.header('authorization') ?? '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
    
    if (!token) {
      res.status(401).json({ error: 'Missing Bearer token' });
      return;
    }

    const { data: userData, error: verifyError } = await supabaseAdmin.auth.getUser(token);
    if (verifyError || !userData.user?.id) {
      res.status(401).json({ error: 'Invalid token' });
      return;
    }

    const profileId = userData.user.id;

    // Update only if the device belongs to the authenticated user
    const { data, error } = await supabaseAdmin
      .from('notification_devices')
      .update({ notifications_enabled })
      .eq('id', req.params.id)
      .eq('profile_id', profileId)
      .select()
      .single();

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    if (!data) {
      res.status(404).json({ error: 'Device token not found or not authorized' });
      return;
    }

    res.json({
      id: data.id,
      notifications_enabled: data.notifications_enabled,
    });
  } catch (err) {
    if (err instanceof z.ZodError) {
      res.status(400).json({ error: 'Invalid request body', details: err.errors });
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to update preference';
    res.status(500).json({ error: msg });
  }
});

// Reminder Management
const CreateReminderSchema = z.object({
  title: z.string().min(1),
  body: z.string().optional(),
  target_type: z.enum(['all', 'batch', 'class', 'student']),
  target_id: z.string().uuid().optional(),
  frequency: z.enum(['daily', 'weekly', 'monthly', 'once']),
  scheduled_at: z.string().datetime(),
  cron_expression: z.string().optional(),
});

const UpdateReminderSchema = CreateReminderSchema.partial();

// Create a scheduled reminder
router.post('/reminders', async (req, res) => {
  try {
    const body = CreateReminderSchema.parse(req.body);
    const role = req.header('x-alif-role') || 'admin';

    // Only admins can create reminders
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const payload = {
      ...body,
      target_id: body.target_id || null,
      created_by: null, // Will be set by auth context if available
      frequency: body.frequency,
      cron_expression: body.cron_expression || null,
      is_active: true,
    };

    const { data, error } = await supabaseAdmin
      .from('notifications')
      .insert([payload])
      .select()
      .single();

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    // Schedule the reminder
    reminderScheduler.scheduleReminder(data);

    res.status(201).json(data);
  } catch (err) {
    if (err instanceof z.ZodError) {
      res.status(400).json({ error: 'Invalid request body', details: err.errors });
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to create reminder';
    res.status(500).json({ error: msg });
  }
});

// Get all reminders
router.get('/reminders', async (req, res) => {
  try {
    const role = req.header('x-alif-role') || 'admin';

    // Only admins can view all reminders
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('notifications')
      .select('*')
      .not('frequency', 'is', null)
      .order('created_at', { ascending: false });

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch reminders';
    res.status(500).json({ error: msg });
  }
});

// Update a reminder
router.put('/reminders/:id', async (req, res) => {
  try {
    const body = UpdateReminderSchema.parse(req.body);
    const role = req.header('x-alif-role') || 'admin';

    // Only admins can update reminders
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('notifications')
      .update(body)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    // Reschedule the reminder if needed
    if (data && (body.frequency || body.scheduled_at || body.cron_expression || body.is_active !== undefined)) {
      await reminderScheduler.updateReminder(req.params.id, body);
    }

    res.json(data);
  } catch (err) {
    if (err instanceof z.ZodError) {
      res.status(400).json({ error: 'Invalid request body', details: err.errors });
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to update reminder';
    res.status(500).json({ error: msg });
  }
});

// Deactivate a reminder
router.post('/reminders/:id/deactivate', async (req, res) => {
  try {
    const role = req.header('x-alif-role') || 'admin';

    // Only admins can deactivate reminders
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('notifications')
      .update({ is_active: false })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    // Unschedule the reminder
    reminderScheduler.unscheduleReminder(req.params.id);

    res.json(data);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to deactivate reminder';
    res.status(500).json({ error: msg });
  }
});

// Get active reminders count
router.get('/reminders/stats', async (req, res) => {
  try {
    const role = req.header('x-alif-role') || 'admin';

    // Only admins can view stats
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const { count: activeCount, error: activeError } = await supabaseAdmin
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('is_active', true)
      .not('frequency', 'is', null);

    if (activeError) {
      res.status(400).json({ error: activeError.message });
      return;
    }

    const activeJobs = reminderScheduler.getActiveJobs();

    res.json({
      total_active: activeCount || 0,
      scheduled_in_memory: activeJobs.length,
      job_ids: activeJobs,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch stats';
    res.status(500).json({ error: msg });
  }
});

export default router;
