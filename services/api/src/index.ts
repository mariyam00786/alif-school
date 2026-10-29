import cors from 'cors';
import express from 'express';

import { assertEnv, config } from './config';
import { initFirebaseMessaging, supabaseAdmin } from './integrations';
import batchRoutes from './routes/batches.route';
import categoryRoutes from './routes/categories.route';
import metadataRoutes from './routes/metadata.route';
import activityRoutes from './routes/activities.route';
import activityLogRoutes from './routes/activity-logs.route';
import classRoutes from './routes/classes.route';
import studentRoutes from './routes/students.route';
import teacherRoutes from './routes/teachers.route';
import ratingRoutes from './routes/ratings.route';
import authRoutes from './routes/auth.route';
import reportRoutes from './routes/reports.route';
import remarkRoutes from './routes/remarks.route';
import badgeRoutes from './routes/badges.route';
import notificationRoutes from './routes/notifications.route';
import studentAppRoutes from './routes/student.route';
import teacherAppRoutes from './routes/teacher-app.route';
import deviceTokenRoutes from './routes/device-tokens.route';
import { createAuthGuard } from './middleware/auth-guard';
import { reminderScheduler } from './services/reminder-scheduler.service';

const app = express();

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(createAuthGuard(config.enforceDevAuth));

app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/teachers', teacherRoutes);
app.use('/api/batches', batchRoutes);
app.use('/api/classes', classRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/activities', activityRoutes);
app.use('/api/activity-logs', activityLogRoutes);
app.use('/api/ratings', ratingRoutes);
app.use('/api/metadata', metadataRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/remarks', remarkRoutes);
app.use('/api/badges', badgeRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/device-tokens', deviceTokenRoutes);
app.use('/api/student', studentAppRoutes);
app.use('/api/teacher', teacherAppRoutes);

app.get('/health', async (_req, res) => {
  const { error } = await supabaseAdmin.from('activity_categories').select('id').limit(1);

  res.json({
    status: error ? 'degraded' : 'ok',
    supabase: error ? error.message : 'connected',
    authOtpProvider: 'supabase_auth',
    pushProvider: 'firebase_fcm',
  });
});

app.post('/notifications/test', async (req, res) => {
  const token = req.body?.token as string | undefined;
  if (!token) {
    res.status(400).json({ error: 'token is required' });
    return;
  }

  const messaging = initFirebaseMessaging();
  if (!messaging) {
    res.status(501).json({ error: 'Firebase messaging not configured for local dev' });
    return;
  }

  await messaging.send({
    token,
    notification: {
      title: 'Alif Notification Test',
      body: 'Firebase Cloud Messaging is configured.',
    },
  });

  res.json({ ok: true });
});

async function verifySupabaseConnectivity() {
  const { error } = await supabaseAdmin.from('activity_categories').select('id').limit(1);
  if (error) {
    throw new Error(`Supabase connectivity check failed: ${error.message}`);
  }
}

async function bootstrap() {
  assertEnv();

  if (config.requireSupabaseOnBoot) {
    await verifySupabaseConnectivity();
  }

  // Initialize reminder scheduler after Supabase is ready
  try {
    await reminderScheduler.initialize();
  } catch (error) {
    console.error('Failed to initialize reminder scheduler:', error);
    // Continue anyway, reminders can be manually triggered
  }

  app.listen(config.port, () => {
    console.log(`API listening on http://localhost:${config.port}`);
    console.log(`Health check: http://localhost:${config.port}/health`);
    console.log(`Local data fallback: ${config.allowLocalDataFallback ? 'enabled' : 'disabled'}`);
    console.log(`Force live DB mode: ${config.forceLiveDb ? 'enabled' : 'disabled'}`);
    console.log(`Require Supabase on boot: ${config.requireSupabaseOnBoot ? 'enabled' : 'disabled'}`);
  });
}

bootstrap().catch((err) => {
  console.error('Failed to start API:', err);
  if (!config.allowLocalDataFallback) {
    console.error('Hint: set ALLOW_LOCAL_DATA_FALLBACK=true for temporary local fallback in non-production environments.');
  }
});
