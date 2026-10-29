"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const config_1 = require("../config");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const auth_schema_1 = require("../schemas/auth.schema");
const auth_context_1 = require("../utils/auth-context");
const router = (0, express_1.Router)();
const DEV_OTP = '123456';
const isDevAuthEnabled = !config_1.config.forceLiveDb;
router.post('/send-otp', (req, res) => {
    if (!isDevAuthEnabled) {
        res.status(403).json({ error: 'Dev OTP auth is disabled in live mode' });
        return;
    }
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
    if (!isDevAuthEnabled) {
        res.status(403).json({ error: 'Dev OTP auth is disabled in live mode' });
        return;
    }
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
    const token = (0, auth_context_1.tokenFromAuthorizationHeader)(req.header('authorization'));
    if (!token) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
    }
    if (token.startsWith('dev-')) {
        if (!isDevAuthEnabled) {
            res.status(401).json({ error: 'Unauthorized' });
            return;
        }
        const user = (0, dev_data_1.getDevAuthUserById)(token.replace(/^dev-/, ''));
        if (!user) {
            res.status(401).json({ error: 'Unauthorized' });
            return;
        }
        res.json({ user });
        return;
    }
    integrations_1.supabaseAdmin.auth
        .getUser(token)
        .then(async ({ data, error }) => {
        if (error || !data.user) {
            res.status(401).json({ error: 'Unauthorized' });
            return;
        }
        const { data: profile, error: profileError } = await integrations_1.supabaseAdmin
            .from('profiles')
            .select('id, phone, full_name, role')
            .eq('id', data.user.id)
            .maybeSingle();
        if (profileError || !profile) {
            res.status(401).json({ error: 'Profile not found for authenticated user' });
            return;
        }
        res.json({
            user: {
                id: profile.id,
                phone: profile.phone,
                full_name: profile.full_name,
                role: profile.role,
            },
        });
    })
        .catch(() => {
        res.status(401).json({ error: 'Unauthorized' });
    });
});
router.post('/logout', (_req, res) => {
    res.json({ ok: true });
});
exports.default = router;
