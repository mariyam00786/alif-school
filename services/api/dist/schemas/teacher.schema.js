"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListTeachersQuerySchema = exports.UpdateTeacherSchema = exports.CreateTeacherSchema = exports.TeacherSchema = void 0;
const zod_1 = require("zod");
exports.TeacherSchema = zod_1.z.object({
    id: zod_1.z.string().uuid().optional(),
    profile_id: zod_1.z.string().uuid().optional().nullable(),
    full_name: zod_1.z.string().min(2, 'Teacher name required'),
    mobile_number: zod_1.z.string().min(10, 'Mobile number must be at least 10 digits'),
    email: zod_1.z.string().email('Invalid email').optional().nullable(),
    qualification: zod_1.z.string().optional().nullable(),
    status: zod_1.z.enum(['active', 'inactive']).default('active'),
    batch_ids: zod_1.z.array(zod_1.z.string().uuid('Invalid batch ID')).default([]),
});
exports.CreateTeacherSchema = exports.TeacherSchema.omit({
    id: true,
    profile_id: true,
    status: true,
}).extend({
    status: zod_1.z.enum(['active', 'inactive']).optional(),
});
exports.UpdateTeacherSchema = exports.TeacherSchema.omit({
    id: true,
    profile_id: true,
}).partial();
exports.ListTeachersQuerySchema = zod_1.z.object({
    search: zod_1.z.string().optional(),
    status: zod_1.z.enum(['active', 'inactive']).optional(),
    batch_id: zod_1.z.string().uuid().optional(),
});
