import { z } from 'zod';

export const ClassSchema = z.object({
  id: z.string().uuid().optional(),
  name: z.string().min(2, 'Class name required'),
  name_ml: z.string().optional().nullable(),
  level: z.string().optional().nullable(),
  batch_id: z.string().uuid('Invalid batch ID'),
  status: z.enum(['active', 'inactive']).default('active'),
});

export const CreateClassSchema = ClassSchema.omit({ id: true });
export const UpdateClassSchema = CreateClassSchema.partial();

export const ListClassesQuerySchema = z.object({
  batch_id: z.string().uuid().optional(),
  status: z.enum(['active', 'inactive']).optional(),
});

export type CreateClass = z.infer<typeof CreateClassSchema>;
export type UpdateClass = z.infer<typeof UpdateClassSchema>;
