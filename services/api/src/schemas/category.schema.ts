import { z } from 'zod';

export const CategorySchema = z.object({
  id: z.string().uuid().optional(),
  name: z.string().min(2, 'Category name required'),
  name_ml: z.string().optional().nullable(),
  icon: z.string().optional().nullable(),
  display_order: z.coerce.number().int().min(0).default(0),
  status: z.enum(['active', 'inactive']).default('active'),
});

export const CreateCategorySchema = CategorySchema.omit({ id: true });
export const UpdateCategorySchema = CreateCategorySchema.partial();
export const ListCategoriesQuerySchema = z.object({
  status: z.enum(['active', 'inactive']).optional(),
});

export type CreateCategory = z.infer<typeof CreateCategorySchema>;
export type UpdateCategory = z.infer<typeof UpdateCategorySchema>;