import { z } from 'zod';

const BadgeCriteriaSchema = z.record(z.string(), z.unknown());

export const BadgeSchema = z.object({
  id: z.string().uuid().optional(),
  name: z.string().min(2, 'Badge name required'),
  name_ml: z.string().optional().nullable(),
  description: z.string().optional().nullable(),
  icon: z.string().optional().nullable(),
  criteria: BadgeCriteriaSchema.optional().nullable(),
  bonus_points: z.coerce.number().int().min(0).default(0),
  status: z.enum(['active', 'inactive']).default('active'),
});

export const CreateBadgeSchema = BadgeSchema.omit({ id: true });
export const UpdateBadgeSchema = CreateBadgeSchema.partial();
export const ListBadgesQuerySchema = z.object({
  status: z.enum(['active', 'inactive']).optional(),
});

export type CreateBadge = z.infer<typeof CreateBadgeSchema>;
export type UpdateBadge = z.infer<typeof UpdateBadgeSchema>;
