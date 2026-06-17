"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListRatingsQuerySchema = exports.UpdateRatingSchema = exports.CreateRatingSchema = exports.RatingSchema = void 0;
const zod_1 = require("zod");
exports.RatingSchema = zod_1.z.object({
    id: zod_1.z.string().uuid().optional(),
    activity_id: zod_1.z.string().uuid('Invalid activity ID'),
    rating_name: zod_1.z.string().min(2, 'Rating name required'),
    rating_name_ml: zod_1.z.string().optional().nullable(),
    marks: zod_1.z.coerce.number().int().min(0),
    color: zod_1.z.string().min(3, 'Color required'),
    display_order: zod_1.z.coerce.number().int().min(0).default(0),
});
exports.CreateRatingSchema = exports.RatingSchema.omit({ id: true });
exports.UpdateRatingSchema = exports.CreateRatingSchema.partial();
exports.ListRatingsQuerySchema = zod_1.z.object({
    activity_id: zod_1.z.string().uuid().optional(),
});
