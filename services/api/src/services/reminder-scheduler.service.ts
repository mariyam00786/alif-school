import cron from 'node-cron';
import { supabaseAdmin } from '../integrations';
import { sendNotificationPush } from './push-delivery.service';

type ReminderFrequency = 'daily' | 'weekly' | 'monthly' | 'once';

interface ScheduledReminder {
  id: string;
  title: string;
  body?: string | null;
  target_type: 'all' | 'batch' | 'class' | 'student';
  target_id?: string | null;
  frequency: ReminderFrequency;
  scheduled_at: string; // ISO timestamp
  cron_expression?: string | null;
  is_active: boolean;
  last_sent_at?: string | null;
}

class ReminderScheduler {
  private activeJobs: Map<string, cron.ScheduledTask> = new Map();

  async initialize(): Promise<void> {
    console.log('[Reminder Scheduler] Initializing...');
    try {
      const reminders = await this.fetchActiveReminders();
      for (const reminder of reminders) {
        this.scheduleReminder(reminder);
      }
      console.log(`[Reminder Scheduler] Initialized ${reminders.length} reminders`);
    } catch (error) {
      console.error('[Reminder Scheduler] Initialization error:', error);
    }
  }

  async fetchActiveReminders(): Promise<ScheduledReminder[]> {
    const { data, error } = await supabaseAdmin
      .from('notifications')
      .select('id, title, body, target_type, target_id, frequency, scheduled_at, cron_expression, is_active, last_sent_at')
      .eq('is_active', true)
      .not('frequency', 'is', null);

    if (error) {
      throw new Error(error.message);
    }

    return (data ?? []) as ScheduledReminder[];
  }

  scheduleReminder(reminder: ScheduledReminder): void {
    const jobId = reminder.id;

    // Unschedule if already scheduled
    if (this.activeJobs.has(jobId)) {
      const existing = this.activeJobs.get(jobId);
      if (existing) {
        existing.stop();
        this.activeJobs.delete(jobId);
      }
    }

    let cronExpression: string;

    if (reminder.cron_expression) {
      // Use custom cron expression if provided
      cronExpression = reminder.cron_expression;
    } else {
      // Generate cron expression based on frequency
      const scheduledTime = new Date(reminder.scheduled_at);
      const hour = scheduledTime.getUTCHours();
      const minute = scheduledTime.getUTCMinutes();

      switch (reminder.frequency) {
        case 'daily':
          cronExpression = `${minute} ${hour} * * *`; // Every day at HH:MM
          break;
        case 'weekly':
          const dayOfWeek = scheduledTime.getUTCDay();
          cronExpression = `${minute} ${hour} * * ${dayOfWeek}`; // Weekly on same day
          break;
        case 'monthly':
          const dayOfMonth = scheduledTime.getUTCDate();
          cronExpression = `${minute} ${hour} ${dayOfMonth} * *`; // Monthly on same date
          break;
        case 'once':
          // Don't schedule if it's in the past
          if (new Date(reminder.scheduled_at) < new Date()) {
            console.log(`[Reminder Scheduler] Skipping past reminder: ${jobId}`);
            return;
          }
          // For one-time reminders, we use a different approach (setTimeout)
          const delay = new Date(reminder.scheduled_at).getTime() - Date.now();
          setTimeout(() => this.sendReminder(reminder), delay);
          return;
        default:
          return;
      }
    }

    // Validate cron expression
    if (!cron.validate(cronExpression)) {
      console.error(`[Reminder Scheduler] Invalid cron expression for ${jobId}: ${cronExpression}`);
      return;
    }

    // Schedule the job
    try {
      const task = cron.schedule(cronExpression, () => {
        this.sendReminder(reminder);
      });

      this.activeJobs.set(jobId, task);
      console.log(`[Reminder Scheduler] Scheduled reminder ${jobId} with expression: ${cronExpression}`);
    } catch (error) {
      console.error(`[Reminder Scheduler] Failed to schedule reminder ${jobId}:`, error);
    }
  }

  private async sendReminder(reminder: ScheduledReminder): Promise<void> {
    try {
      console.log(`[Reminder Scheduler] Sending reminder: ${reminder.id}`);

      // Send push notification
      const result = await sendNotificationPush({
        notificationId: reminder.id,
        title: reminder.title,
        body: reminder.body,
        targetType: reminder.target_type,
        targetId: reminder.target_id,
      });

      // Update last_sent_at
      await supabaseAdmin
        .from('notifications')
        .update({ last_sent_at: new Date().toISOString() })
        .eq('id', reminder.id);

      console.log(`[Reminder Scheduler] Reminder sent: ${reminder.id}`, result);
    } catch (error) {
      console.error(`[Reminder Scheduler] Failed to send reminder ${reminder.id}:`, error);
    }
  }

  unscheduleReminder(reminderId: string): void {
    if (this.activeJobs.has(reminderId)) {
      const task = this.activeJobs.get(reminderId);
      if (task) {
        task.stop();
        this.activeJobs.delete(reminderId);
        console.log(`[Reminder Scheduler] Unscheduled reminder: ${reminderId}`);
      }
    }
  }

  rescheduleReminder(reminder: ScheduledReminder): void {
    this.scheduleReminder(reminder);
  }

  async updateReminder(
    reminderId: string,
    updates: Partial<ScheduledReminder>
  ): Promise<void> {
    // If frequency or scheduled_at changed, reschedule
    if (updates.frequency || updates.scheduled_at || updates.cron_expression || updates.is_active !== undefined) {
      if (updates.is_active === false) {
        this.unscheduleReminder(reminderId);
      } else {
        const reminder = await this.fetchReminder(reminderId);
        if (reminder) {
          this.rescheduleReminder(reminder);
        }
      }
    }
  }

  private async fetchReminder(reminderId: string): Promise<ScheduledReminder | null> {
    const { data, error } = await supabaseAdmin
      .from('notifications')
      .select('id, title, body, target_type, target_id, frequency, scheduled_at, cron_expression, is_active, last_sent_at')
      .eq('id', reminderId)
      .single();

    if (error || !data) {
      return null;
    }

    return data as ScheduledReminder;
  }

  getActiveJobs(): string[] {
    return Array.from(this.activeJobs.keys());
  }

  stopAll(): void {
    for (const [jobId, task] of this.activeJobs) {
      task.stop();
      console.log(`[Reminder Scheduler] Stopped reminder: ${jobId}`);
    }
    this.activeJobs.clear();
  }
}

export const reminderScheduler = new ReminderScheduler();
