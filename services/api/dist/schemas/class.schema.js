"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListClassesQuerySchema = exports.UpdateClassSchema = exports.CreateClassSchema = exports.ClassSchema = void 0;
const zod_1 = require("zod");
exports.ClassSchema = zod_1.z.object({
    id: zod_1.z.string().uuid().optional(),
    name: zod_1.z.string().min(2, 'Class name required'),
    name_ml: zod_1.z.string().optional().nullable(),
    level: zod_1.z.string().optional().nullable(),
    batch_id: zod_1.z.string().uuid('Invalid batch ID'),
    status: zod_1.z.enum(['active', 'inactive']).default('active'),
});
exports.CreateClassSchema = exports.ClassSchema.omit({ id: true });
exports.UpdateClassSchema = exports.CreateClassSchema.partial();
exports.ListClassesQuerySchema = zod_1.z.object({
    batch_id: zod_1.z.string().uuid().optional(),
    status: zod_1.z.enum(['active', 'inactive']).optional(),
});
