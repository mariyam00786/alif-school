"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListBatchesQuerySchema = exports.UpdateBatchSchema = exports.CreateBatchSchema = exports.BatchSchema = void 0;
const zod_1 = require("zod");
exports.BatchSchema = zod_1.z.object({
    id: zod_1.z.string().uuid().optional(),
    name: zod_1.z.string().min(2, 'Batch name required'),
    name_ml: zod_1.z.string().optional().nullable(),
    description: zod_1.z.string().optional().nullable(),
    capacity: zod_1.z.coerce.number().int().min(1).optional().nullable(),
    timing: zod_1.z.string().optional().nullable(),
    status: zod_1.z.enum(['active', 'inactive']).default('active'),
});
exports.CreateBatchSchema = exports.BatchSchema.omit({ id: true });
exports.UpdateBatchSchema = exports.CreateBatchSchema.partial();
exports.ListBatchesQuerySchema = zod_1.z.object({
    status: zod_1.z.enum(['active', 'inactive']).optional(),
});
