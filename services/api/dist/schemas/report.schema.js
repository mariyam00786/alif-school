"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MonthlyReportQuerySchema = exports.WeeklyReportQuerySchema = exports.DailyReportQuerySchema = void 0;
const zod_1 = require("zod");
const IsoDateSchema = zod_1.z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Invalid date format, expected YYYY-MM-DD');
exports.DailyReportQuerySchema = zod_1.z.object({
    date: IsoDateSchema.optional(),
    batch_id: zod_1.z.string().uuid().optional(),
});
exports.WeeklyReportQuerySchema = zod_1.z.object({
    week_start: IsoDateSchema.optional(),
    batch_id: zod_1.z.string().uuid().optional(),
});
exports.MonthlyReportQuerySchema = zod_1.z.object({
    month_start: IsoDateSchema.optional(),
    batch_id: zod_1.z.string().uuid().optional(),
});
