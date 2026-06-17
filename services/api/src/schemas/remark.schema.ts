import { z } from 'zod';

export const RemarkSchema = z.object({
  id: z.string().uuid().optional(),
  teacher_id: z.string().uuid('Invalid teacher ID'),
  student_id: z.string().uuid('Invalid student ID'),
  remark: z.string().trim().min(2, 'Remark is required').max(1000, 'Remark too long'),
});

export const CreateRemarkSchema = RemarkSchema.omit({ id: true });

export const ListRemarksQuerySchema = z.object({
  teacher_id: z.string().uuid().optional(),
  student_id: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});
