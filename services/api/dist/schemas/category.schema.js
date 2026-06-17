"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListCategoriesQuerySchema = exports.UpdateCategorySchema = exports.CreateCategorySchema = exports.CategorySchema = void 0;
const zod_1 = require("zod");
exports.CategorySchema = zod_1.z.object({
    id: zod_1.z.string().uuid().optional(),
    name: zod_1.z.string().min(2, 'Category name required'),
    name_ml: zod_1.z.string().optional().nullable(),
    icon: zod_1.z.string().optional().nullable(),
    display_order: zod_1.z.coerce.number().int().min(0).default(0),
    status: zod_1.z.enum(['active', 'inactive']).default('active'),
});
exports.CreateCategorySchema = exports.CategorySchema.omit({ id: true });
exports.UpdateCategorySchema = exports.CreateCategorySchema.partial();
exports.ListCategoriesQuerySchema = zod_1.z.object({
    status: zod_1.z.enum(['active', 'inactive']).optional(),
});
