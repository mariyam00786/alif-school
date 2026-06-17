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
import { createAuthGuard } from './middleware/auth-guard';

const app = express();

app.use(cors());
app.use(express.json());
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

function bootstrap() {
  try {
    assertEnv();

    app.listen(config.port, () => {
      console.log(`API listening on http://localhost:${config.port}`);
      console.log(`Health check: http://localhost:${config.port}/health`);
    });
  } catch (err) {
    console.error('Failed to start API:', err);
  }
}

bootstrap();
