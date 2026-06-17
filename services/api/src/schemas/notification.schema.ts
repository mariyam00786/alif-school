import { z } from 'zod';

const IsoDateTimeSchema = z
  .string()
  .datetime({ offset: true })
  .or(z.string().datetime({ offset: false }));

export const NotificationSchema = z.object({
  id: z.string().uuid().optional(),
  title: z.string().min(2, 'Title is required'),
  body: z.string().optional().nullable(),
  target_type: z.enum(['all', 'batch', 'class', 'student']),
  target_id: z.string().uuid().optional().nullable(),
  scheduled_at: IsoDateTimeSchema.optional().nullable(),
  sent_at: IsoDateTimeSchema.optional().nullable(),
});

export const CreateNotificationSchema = NotificationSchema.omit({
  id: true,
  sent_at: true,
});
export const UpdateNotificationSchema = CreateNotificationSchema.partial();
export const ListNotificationsQuerySchema = z.object({
  target_type: z.enum(['all', 'batch', 'class', 'student']).optional(),
  target_id: z.string().uuid().optional(),
});

export type CreateNotification = z.infer<typeof CreateNotificationSchema>;
export type UpdateNotification = z.infer<typeof UpdateNotificationSchema>;
