import { z } from 'zod';

const IsoDateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Invalid date format, expected YYYY-MM-DD');

export const DailyReportQuerySchema = z.object({
  date: IsoDateSchema.optional(),
  batch_id: z.string().uuid().optional(),
});

export const WeeklyReportQuerySchema = z.object({
  week_start: IsoDateSchema.optional(),
  batch_id: z.string().uuid().optional(),
});

export const MonthlyReportQuerySchema = z.object({
  month_start: IsoDateSchema.optional(),
  batch_id: z.string().uuid().optional(),
});

export type DailyReportQuery = z.infer<typeof DailyReportQuerySchema>;
export type WeeklyReportQuery = z.infer<typeof WeeklyReportQuerySchema>;
export type MonthlyReportQuery = z.infer<typeof MonthlyReportQuerySchema>;
