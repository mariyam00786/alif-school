import { z } from 'zod';

export const BatchSchema = z.object({
  id: z.string().uuid().optional(),
  name: z.string().min(2, 'Batch name required'),
  name_ml: z.string().optional().nullable(),
  description: z.string().optional().nullable(),
  capacity: z.coerce.number().int().min(1).optional().nullable(),
  timing: z.string().optional().nullable(),
  status: z.enum(['active', 'inactive']).default('active'),
});

export const CreateBatchSchema = BatchSchema.omit({ id: true });
export const UpdateBatchSchema = CreateBatchSchema.partial();
export const ListBatchesQuerySchema = z.object({
  status: z.enum(['active', 'inactive']).optional(),
});

export type CreateBatch = z.infer<typeof CreateBatchSchema>;
export type UpdateBatch = z.infer<typeof UpdateBatchSchema>;