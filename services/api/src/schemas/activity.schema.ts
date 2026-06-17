import { z } from 'zod';

export const ActivitySchema = z.object({
  id: z.string().uuid().optional(),
  category_id: z.string().uuid('Invalid category ID'),
  name: z.string().min(2, 'Activity name required'),
  name_ml: z.string().optional().nullable(),
  display_order: z.coerce.number().int().min(0).default(0),
  has_quantity: z.boolean().default(false),
  status: z.enum(['active', 'inactive']).default('active'),
});

export const CreateActivitySchema = ActivitySchema.omit({ id: true });
export const UpdateActivitySchema = CreateActivitySchema.partial();
export const ListActivitiesQuerySchema = z.object({
  category_id: z.string().uuid().optional(),
  status: z.enum(['active', 'inactive']).optional(),
});

export type CreateActivity = z.infer<typeof CreateActivitySchema>;
export type UpdateActivity = z.infer<typeof UpdateActivitySchema>;