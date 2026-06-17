import { z } from 'zod';

const IsoDateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Invalid date format, expected YYYY-MM-DD');

export const TeacherStudentsQuerySchema = z.object({
  batch_id: z.string().uuid().optional(),
});

export const TeacherStudentProgressQuerySchema = z.object({
  from_date: IsoDateSchema.optional(),
  to_date: IsoDateSchema.optional(),
});

export const TeacherBatchAnalyticsQuerySchema = z.object({
  from_date: IsoDateSchema.optional(),
  to_date: IsoDateSchema.optional(),
});
