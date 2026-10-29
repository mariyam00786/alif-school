"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UnregisterDeviceTokenSchema = exports.RegisterDeviceTokenSchema = void 0;
const zod_1 = require("zod");
const PlatformSchema = zod_1.z.enum([
    'android',
    'ios',
    'web',
    'macos',
    'windows',
    'linux',
    'unknown',
]);
const AppNameSchema = zod_1.z.enum(['admin', 'student_teacher']);
exports.RegisterDeviceTokenSchema = zod_1.z.object({
    token: zod_1.z.string().min(20, 'FCM token appears invalid').max(4096),
    platform: PlatformSchema.default('unknown'),
    app_name: AppNameSchema,
    notifications_enabled: zod_1.z.boolean().optional(),
});
exports.UnregisterDeviceTokenSchema = zod_1.z.object({
    token: zod_1.z.string().min(20).max(4096),
});
