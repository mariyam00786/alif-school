"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TeacherBatchAnalyticsQuerySchema = exports.TeacherStudentProgressQuerySchema = exports.TeacherStudentsQuerySchema = void 0;
const zod_1 = require("zod");
const IsoDateSchema = zod_1.z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Invalid date format, expected YYYY-MM-DD');
exports.TeacherStudentsQuerySchema = zod_1.z.object({
    batch_id: zod_1.z.string().uuid().optional(),
});
exports.TeacherStudentProgressQuerySchema = zod_1.z.object({
    from_date: IsoDateSchema.optional(),
    to_date: IsoDateSchema.optional(),
});
exports.TeacherBatchAnalyticsQuerySchema = zod_1.z.object({
    from_date: IsoDateSchema.optional(),
    to_date: IsoDateSchema.optional(),
});
