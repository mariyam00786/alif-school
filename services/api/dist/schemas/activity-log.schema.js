"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListActivityLogsQuerySchema = exports.UpdateActivityLogSchema = exports.CreateActivityLogSchema = exports.ActivityLogSchema = void 0;
const zod_1 = require("zod");
const IsoDateSchema = zod_1.z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Invalid date format, expected YYYY-MM-DD');
exports.ActivityLogSchema = zod_1.z.object({
    id: zod_1.z.string().uuid().optional(),
    student_id: zod_1.z.string().uuid('Invalid student ID'),
    activity_id: zod_1.z.string().uuid('Invalid activity ID'),
    rating_id: zod_1.z.string().uuid('Invalid rating ID'),
    log_date: IsoDateSchema,
    quantity: zod_1.z.coerce.number().int().min(0).optional().nullable(),
    parent_approved: zod_1.z.boolean().default(false),
    notes: zod_1.z.string().max(500).optional().nullable(),
});
exports.CreateActivityLogSchema = exports.ActivityLogSchema.omit({ id: true });
exports.UpdateActivityLogSchema = exports.CreateActivityLogSchema.partial();
exports.ListActivityLogsQuerySchema = zod_1.z.object({
    student_id: zod_1.z.string().uuid().optional(),
    log_date: IsoDateSchema.optional(),
    from_date: IsoDateSchema.optional(),
    to_date: IsoDateSchema.optional(),
});
