"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpdateStudentProfileSchema = exports.StudentApprovalHistoryQuerySchema = exports.StudentChildrenQuerySchema = exports.StudentProfileQuerySchema = exports.StudentBadgesQuerySchema = exports.StudentProgressQuerySchema = exports.StudentLeaderboardQuerySchema = void 0;
const zod_1 = require("zod");
const IsoDateSchema = zod_1.z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Invalid date format, expected YYYY-MM-DD');
exports.StudentLeaderboardQuerySchema = zod_1.z.object({
    period: zod_1.z.enum(['daily', 'weekly', 'monthly', 'all_time']).default('weekly'),
    date: IsoDateSchema.optional(),
    batch_id: zod_1.z.string().uuid().optional(),
});
exports.StudentProgressQuerySchema = zod_1.z.object({
    student_id: zod_1.z.string().uuid(),
    week_start: IsoDateSchema.optional(),
    month_start: IsoDateSchema.optional(),
});
exports.StudentBadgesQuerySchema = zod_1.z.object({
    student_id: zod_1.z.string().uuid(),
});
exports.StudentProfileQuerySchema = zod_1.z.object({
    student_id: zod_1.z.string().uuid(),
});
exports.StudentChildrenQuerySchema = zod_1.z.object({
    parent_phone: zod_1.z
        .string()
        .regex(/^\d{10,15}$/, 'Invalid parent phone format'),
});
exports.StudentApprovalHistoryQuerySchema = zod_1.z.object({
    student_id: zod_1.z.string().uuid(),
    limit: zod_1.z.coerce.number().int().min(1).max(200).default(30),
});
exports.UpdateStudentProfileSchema = zod_1.z.object({
    address: zod_1.z.string().min(2).optional(),
});
