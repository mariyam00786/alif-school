import { z } from 'zod';

export const StudentSchema = z.object({
  id: z.string().uuid().optional(),
  profile_id: z.string().uuid().optional().nullable(),
  parent_phone: z.string().min(10, 'Parent phone must be at least 10 digits'),
  father_name: z.string().min(2, 'Father name required'),
  mother_name: z.string().min(2, 'Mother name required'),
  date_of_birth: z.string().date('Invalid date format'),
  gender: z.enum(['male', 'female']),
  batch_id: z.string().uuid('Invalid batch ID').optional().nullable(),
  class_id: z.string().uuid('Invalid class ID').optional().nullable(),
  address: z.string().optional(),
  enrollment_date: z.string().date().optional(),
  status: z.enum(['active', 'inactive']).default('active'),
  full_name: z.string().min(2, 'Student name required').optional(),
  full_name_ml: z.string().optional().nullable(),
});

export type Student = z.infer<typeof StudentSchema>;

export const CreateStudentSchema = StudentSchema.pick({
  parent_phone: true,
  father_name: true,
  mother_name: true,
  date_of_birth: true,
  gender: true,
  batch_id: true,
  class_id: true,
  address: true,
});

export const UpdateStudentSchema = StudentSchema.partial();

export const ListStudentsQuerySchema = z.object({
  search: z.string().optional(),
  batch_id: z.string().uuid().optional(),
  status: z.enum(['active', 'inactive']).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

export type CreateStudent = z.infer<typeof CreateStudentSchema>;
export type UpdateStudent = z.infer<typeof UpdateStudentSchema>;
export type ListStudentsQuery = z.infer<typeof ListStudentsQuerySchema>;
