"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListStudentsQuerySchema = exports.UpdateStudentSchema = exports.CreateStudentSchema = exports.StudentSchema = void 0;
const zod_1 = require("zod");
exports.StudentSchema = zod_1.z.object({
    id: zod_1.z.string().uuid().optional(),
    profile_id: zod_1.z.string().uuid().optional().nullable(),
    parent_phone: zod_1.z.string().min(10, 'Parent phone must be at least 10 digits'),
    father_name: zod_1.z.string().min(2, 'Father name required'),
    mother_name: zod_1.z.string().min(2, 'Mother name required'),
    date_of_birth: zod_1.z.string().date('Invalid date format'),
    gender: zod_1.z.enum(['male', 'female']),
    batch_id: zod_1.z.string().uuid('Invalid batch ID').optional().nullable(),
    class_id: zod_1.z.string().uuid('Invalid class ID').optional().nullable(),
    address: zod_1.z.string().optional(),
    enrollment_date: zod_1.z.string().date().optional(),
    status: zod_1.z.enum(['active', 'inactive']).default('active'),
    full_name: zod_1.z.string().min(2, 'Student name required').optional(),
    full_name_ml: zod_1.z.string().optional().nullable(),
});
exports.CreateStudentSchema = exports.StudentSchema.pick({
    parent_phone: true,
    father_name: true,
    mother_name: true,
    date_of_birth: true,
    gender: true,
    batch_id: true,
    class_id: true,
    address: true,
});
exports.UpdateStudentSchema = exports.StudentSchema.partial();
exports.ListStudentsQuerySchema = zod_1.z.object({
    search: zod_1.z.string().optional(),
    batch_id: zod_1.z.string().uuid().optional(),
    status: zod_1.z.enum(['active', 'inactive']).optional(),
    limit: zod_1.z.coerce.number().int().min(1).max(100).default(20),
    offset: zod_1.z.coerce.number().int().min(0).default(0),
});
