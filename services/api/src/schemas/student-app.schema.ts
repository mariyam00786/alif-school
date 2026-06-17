import { z } from 'zod';

const IsoDateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Invalid date format, expected YYYY-MM-DD');

export const StudentLeaderboardQuerySchema = z.object({
  period: z.enum(['daily', 'weekly', 'monthly', 'all_time']).default('weekly'),
  date: IsoDateSchema.optional(),
  batch_id: z.string().uuid().optional(),
});

export const StudentProgressQuerySchema = z.object({
  student_id: z.string().uuid(),
  week_start: IsoDateSchema.optional(),
  month_start: IsoDateSchema.optional(),
});

export const StudentBadgesQuerySchema = z.object({
  student_id: z.string().uuid(),
});

export const StudentProfileQuerySchema = z.object({
  student_id: z.string().uuid(),
});

export const StudentChildrenQuerySchema = z.object({
  parent_phone: z
    .string()
    .regex(/^\d{10,15}$/, 'Invalid parent phone format'),
});

export const UpdateStudentProfileSchema = z.object({
  address: z.string().min(2).optional(),
});
