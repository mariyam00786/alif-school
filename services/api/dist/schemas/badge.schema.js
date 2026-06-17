"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListBadgesQuerySchema = exports.UpdateBadgeSchema = exports.CreateBadgeSchema = exports.BadgeSchema = void 0;
const zod_1 = require("zod");
const BadgeCriteriaSchema = zod_1.z.record(zod_1.z.string(), zod_1.z.unknown());
exports.BadgeSchema = zod_1.z.object({
    id: zod_1.z.string().uuid().optional(),
    name: zod_1.z.string().min(2, 'Badge name required'),
    name_ml: zod_1.z.string().optional().nullable(),
    description: zod_1.z.string().optional().nullable(),
    icon: zod_1.z.string().optional().nullable(),
    criteria: BadgeCriteriaSchema.optional().nullable(),
    bonus_points: zod_1.z.coerce.number().int().min(0).default(0),
    status: zod_1.z.enum(['active', 'inactive']).default('active'),
});
exports.CreateBadgeSchema = exports.BadgeSchema.omit({ id: true });
exports.UpdateBadgeSchema = exports.CreateBadgeSchema.partial();
exports.ListBadgesQuerySchema = zod_1.z.object({
    status: zod_1.z.enum(['active', 'inactive']).optional(),
});
