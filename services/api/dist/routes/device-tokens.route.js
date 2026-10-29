"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const device_token_schema_1 = require("../schemas/device-token.schema");
const auth_context_1 = require("../utils/auth-context");
const router = (0, express_1.Router)();
router.post('/register', async (req, res) => {
    const user = await (0, auth_context_1.resolveRequestUser)(req);
    if (!user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
    }
    try {
        const body = device_token_schema_1.RegisterDeviceTokenSchema.parse(req.body);
        const payload = {
            profile_id: user.id,
            role: user.role,
            app_name: body.app_name,
            platform: body.platform,
            device_token: body.token,
            notifications_enabled: body.notifications_enabled ?? true,
            last_seen_at: new Date().toISOString(),
        };
        const { error } = await integrations_1.supabaseAdmin.from('notification_devices').upsert([payload], {
            onConflict: 'device_token',
            ignoreDuplicates: false,
        });
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                (0, dev_data_1.upsertDevDeviceToken)(payload);
                res.status(201).json({ ok: true, source: 'dev-fallback' });
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(201).json({ ok: true });
    }
    catch (error) {
        const message = error instanceof Error ? error.message : 'Failed to register device token';
        res.status(400).json({ error: message });
    }
});
router.post('/unregister', async (req, res) => {
    const user = await (0, auth_context_1.resolveRequestUser)(req);
    if (!user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
    }
    try {
        const body = device_token_schema_1.UnregisterDeviceTokenSchema.parse(req.body);
        const { error } = await integrations_1.supabaseAdmin
            .from('notification_devices')
            .delete()
            .eq('profile_id', user.id)
            .eq('device_token', body.token);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                (0, dev_data_1.deleteDevDeviceToken)(user.id, body.token);
                res.json({ ok: true, source: 'dev-fallback' });
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json({ ok: true });
    }
    catch (error) {
        const message = error instanceof Error ? error.message : 'Failed to unregister device token';
        res.status(400).json({ error: message });
    }
});
exports.default = router;
