import { z } from 'zod';

export const RatingSchema = z.object({
  id: z.string().uuid().optional(),
  activity_id: z.string().uuid('Invalid activity ID'),
  rating_name: z.string().min(2, 'Rating name required'),
  rating_name_ml: z.string().optional().nullable(),
  marks: z.coerce.number().int().min(0),
  color: z.string().min(3, 'Color required'),
  display_order: z.coerce.number().int().min(0).default(0),
});

export const CreateRatingSchema = RatingSchema.omit({ id: true });
export const UpdateRatingSchema = CreateRatingSchema.partial();
export const ListRatingsQuerySchema = z.object({
  activity_id: z.string().uuid().optional(),
});

export type CreateRating = z.infer<typeof CreateRatingSchema>;
export type UpdateRating = z.infer<typeof UpdateRatingSchema>;