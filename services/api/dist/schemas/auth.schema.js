"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.VerifyOtpSchema = exports.SendOtpSchema = void 0;
const zod_1 = require("zod");
const PhoneSchema = zod_1.z
    .string()
    .trim()
    .regex(/^\+?[0-9]{10,15}$/, 'Invalid phone number');
exports.SendOtpSchema = zod_1.z.object({
    phone: PhoneSchema,
});
exports.VerifyOtpSchema = zod_1.z.object({
    phone: PhoneSchema,
    otp: zod_1.z.string().trim().regex(/^[0-9]{6}$/, 'OTP must be 6 digits'),
});
