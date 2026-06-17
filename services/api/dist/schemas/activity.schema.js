"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListActivitiesQuerySchema = exports.UpdateActivitySchema = exports.CreateActivitySchema = exports.ActivitySchema = void 0;
const zod_1 = require("zod");
exports.ActivitySchema = zod_1.z.object({
    id: zod_1.z.string().uuid().optional(),
    category_id: zod_1.z.string().uuid('Invalid category ID'),
    name: zod_1.z.string().min(2, 'Activity name required'),
    name_ml: zod_1.z.string().optional().nullable(),
    display_order: zod_1.z.coerce.number().int().min(0).default(0),
    has_quantity: zod_1.z.boolean().default(false),
    status: zod_1.z.enum(['active', 'inactive']).default('active'),
});
exports.CreateActivitySchema = exports.ActivitySchema.omit({ id: true });
exports.UpdateActivitySchema = exports.CreateActivitySchema.partial();
exports.ListActivitiesQuerySchema = zod_1.z.object({
    category_id: zod_1.z.string().uuid().optional(),
    status: zod_1.z.enum(['active', 'inactive']).optional(),
});
