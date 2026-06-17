"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const auth_schema_1 = require("../schemas/auth.schema");
const router = (0, express_1.Router)();
const DEV_OTP = '123456';
router.post('/send-otp', (req, res) => {
    try {
        const body = auth_schema_1.SendOtpSchema.parse(req.body);
        const user = (0, dev_data_1.getDevAuthUserByPhone)(body.phone);
        res.json({
            ok: true,
            message: 'OTP sent',
            dev_otp: DEV_OTP,
            user_exists: Boolean(user),
        });
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : 'Invalid request';
        res.status(400).json({ error: msg });
    }
});
router.post('/verify-otp', (req, res) => {
    try {
        const body = auth_schema_1.VerifyOtpSchema.parse(req.body);
        if (body.otp !== DEV_OTP) {
            res.status(401).json({ error: 'Invalid OTP' });
            return;
        }
        const user = (0, dev_data_1.getDevAuthUserByPhone)(body.phone);
        if (!user) {
            res.status(404).json({ error: 'User not found for this phone' });
            return;
        }
        res.json({
            access_token: `dev-${user.id}`,
            token_type: 'bearer',
            user,
        });
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : 'Invalid request';
        res.status(400).json({ error: msg });
    }
});
router.get('/me', (req, res) => {
    const authHeader = String(req.header('authorization') ?? '').trim();
    if (!authHeader.toLowerCase().startsWith('bearer dev-')) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
    }
    const token = authHeader.substring('Bearer '.length);
    const id = token.replace(/^dev-/, '');
    const candidates = ['9999999999', '8888888888', '9999999998', '9999999997'];
    const user = candidates
        .map((phone) => (0, dev_data_1.getDevAuthUserByPhone)(phone))
        .find((item) => item?.id === id);
    if (!user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
    }
    res.json({ user });
});
router.post('/logout', (_req, res) => {
    res.json({ ok: true });
});
exports.default = router;
