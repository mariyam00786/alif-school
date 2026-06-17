"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListNotificationsQuerySchema = exports.UpdateNotificationSchema = exports.CreateNotificationSchema = exports.NotificationSchema = void 0;
const zod_1 = require("zod");
const IsoDateTimeSchema = zod_1.z
    .string()
    .datetime({ offset: true })
    .or(zod_1.z.string().datetime({ offset: false }));
exports.NotificationSchema = zod_1.z.object({
    id: zod_1.z.string().uuid().optional(),
    title: zod_1.z.string().min(2, 'Title is required'),
    body: zod_1.z.string().optional().nullable(),
    target_type: zod_1.z.enum(['all', 'batch', 'class', 'student']),
    target_id: zod_1.z.string().uuid().optional().nullable(),
    scheduled_at: IsoDateTimeSchema.optional().nullable(),
    sent_at: IsoDateTimeSchema.optional().nullable(),
});
exports.CreateNotificationSchema = exports.NotificationSchema.omit({
    id: true,
    sent_at: true,
});
exports.UpdateNotificationSchema = exports.CreateNotificationSchema.partial();
exports.ListNotificationsQuerySchema = zod_1.z.object({
    target_type: zod_1.z.enum(['all', 'batch', 'class', 'student']).optional(),
    target_id: zod_1.z.string().uuid().optional(),
});
