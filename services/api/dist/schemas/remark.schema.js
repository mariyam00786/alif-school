"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListRemarksQuerySchema = exports.CreateRemarkSchema = exports.RemarkSchema = void 0;
const zod_1 = require("zod");
exports.RemarkSchema = zod_1.z.object({
    id: zod_1.z.string().uuid().optional(),
    teacher_id: zod_1.z.string().uuid('Invalid teacher ID'),
    student_id: zod_1.z.string().uuid('Invalid student ID'),
    remark: zod_1.z.string().trim().min(2, 'Remark is required').max(1000, 'Remark too long'),
});
exports.CreateRemarkSchema = exports.RemarkSchema.omit({ id: true });
exports.ListRemarksQuerySchema = zod_1.z.object({
    teacher_id: zod_1.z.string().uuid().optional(),
    student_id: zod_1.z.string().uuid().optional(),
    limit: zod_1.z.coerce.number().int().min(1).max(200).default(50),
});
