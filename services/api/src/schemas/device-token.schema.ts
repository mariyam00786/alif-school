import { z } from 'zod';

const PlatformSchema = z.enum([
  'android',
  'ios',
  'web',
  'macos',
  'windows',
  'linux',
  'unknown',
]);

const AppNameSchema = z.enum(['admin', 'student_teacher']);

export const RegisterDeviceTokenSchema = z.object({
  token: z.string().min(20, 'FCM token appears invalid').max(4096),
  platform: PlatformSchema.default('unknown'),
  app_name: AppNameSchema,
  notifications_enabled: z.boolean().optional(),
});

export const UnregisterDeviceTokenSchema = z.object({
  token: z.string().min(20).max(4096),
});

export type RegisterDeviceTokenInput = z.infer<typeof RegisterDeviceTokenSchema>;
