import { z } from 'zod';

const IsoDateSchema = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Invalid date format, expected YYYY-MM-DD');

export const ActivityLogSchema = z.object({
  id: z.string().uuid().optional(),
  student_id: z.string().uuid('Invalid student ID'),
  activity_id: z.string().uuid('Invalid activity ID'),
  rating_id: z.string().uuid('Invalid rating ID'),
  log_date: IsoDateSchema,
  quantity: z.coerce.number().int().min(0).optional().nullable(),
  parent_approved: z.boolean().default(false),
  notes: z.string().max(500).optional().nullable(),
});

export const CreateActivityLogSchema = ActivityLogSchema.omit({ id: true });
export const UpdateActivityLogSchema = CreateActivityLogSchema.partial();

export const ListActivityLogsQuerySchema = z.object({
  student_id: z.string().uuid().optional(),
  log_date: IsoDateSchema.optional(),
  from_date: IsoDateSchema.optional(),
  to_date: IsoDateSchema.optional(),
});

export type CreateActivityLog = z.infer<typeof CreateActivityLogSchema>;
export type UpdateActivityLog = z.infer<typeof UpdateActivityLogSchema>;
