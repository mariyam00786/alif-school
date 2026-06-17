import { z } from 'zod';

export const TeacherSchema = z.object({
  id: z.string().uuid().optional(),
  profile_id: z.string().uuid().optional().nullable(),
  full_name: z.string().min(2, 'Teacher name required'),
  mobile_number: z.string().min(10, 'Mobile number must be at least 10 digits'),
  email: z.string().email('Invalid email').optional().nullable(),
  qualification: z.string().optional().nullable(),
  status: z.enum(['active', 'inactive']).default('active'),
  batch_ids: z.array(z.string().uuid('Invalid batch ID')).default([]),
});

export const CreateTeacherSchema = TeacherSchema.omit({
  id: true,
  profile_id: true,
  status: true,
}).extend({
  status: z.enum(['active', 'inactive']).optional(),
});

export const UpdateTeacherSchema = TeacherSchema.omit({
  id: true,
  profile_id: true,
}).partial();

export const ListTeachersQuerySchema = z.object({
  search: z.string().optional(),
  status: z.enum(['active', 'inactive']).optional(),
  batch_id: z.string().uuid().optional(),
});

export type CreateTeacher = z.infer<typeof CreateTeacherSchema>;
export type UpdateTeacher = z.infer<typeof UpdateTeacherSchema>;