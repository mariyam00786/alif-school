"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const notification_schema_1 = require("../schemas/notification.schema");
const router = (0, express_1.Router)();
const NOTIFICATION_SELECT = 'id, title, body, target_type, target_id, scheduled_at, sent_at, created_at';
router.get('/', async (req, res) => {
    const query = notification_schema_1.ListNotificationsQuerySchema.parse(req.query);
    try {
        let request = integrations_1.supabaseAdmin
            .from('notifications')
            .select(NOTIFICATION_SELECT)
            .order('created_at', { ascending: false });
        if (query.target_type) {
            request = request.eq('target_type', query.target_type);
        }
        if (query.target_id) {
            request = request.eq('target_id', query.target_id);
        }
        const { data, error } = await request;
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.json((0, dev_data_1.listDevNotifications)(query));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json(data || []);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            res.json((0, dev_data_1.listDevNotifications)(query));
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to fetch notifications';
        res.status(500).json({ error: msg });
    }
});
router.post('/', async (req, res) => {
    try {
        const body = notification_schema_1.CreateNotificationSchema.parse(req.body);
        const payload = {
            ...body,
            sent_at: body.scheduled_at ? null : new Date().toISOString(),
        };
        const { data, error } = await integrations_1.supabaseAdmin
            .from('notifications')
            .insert([payload])
            .select(NOTIFICATION_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.status(201).json((0, dev_data_1.createDevNotification)(body));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(201).json(data);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const body = notification_schema_1.CreateNotificationSchema.parse(req.body);
            res.status(201).json((0, dev_data_1.createDevNotification)(body));
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to create notification';
        res.status(400).json({ error: msg });
    }
});
router.put('/:id', async (req, res) => {
    try {
        const body = notification_schema_1.UpdateNotificationSchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('notifications')
            .update(body)
            .eq('id', req.params.id)
            .select(NOTIFICATION_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const updated = (0, dev_data_1.updateDevNotification)(req.params.id, body);
                if (!updated) {
                    res.status(404).json({ error: 'Notification not found' });
                    return;
                }
                res.json(updated);
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json(data);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const body = notification_schema_1.UpdateNotificationSchema.parse(req.body);
            const updated = (0, dev_data_1.updateDevNotification)(req.params.id, body);
            if (!updated) {
                res.status(404).json({ error: 'Notification not found' });
                return;
            }
            res.json(updated);
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to update notification';
        res.status(400).json({ error: msg });
    }
});
router.delete('/:id', async (req, res) => {
    try {
        const { error } = await integrations_1.supabaseAdmin
            .from('notifications')
            .delete()
            .eq('id', req.params.id);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const deleted = (0, dev_data_1.deleteDevNotification)(req.params.id);
                if (!deleted) {
                    res.status(404).json({ error: 'Notification not found' });
                    return;
                }
                res.status(204).send();
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(204).send();
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const deleted = (0, dev_data_1.deleteDevNotification)(req.params.id);
            if (!deleted) {
                res.status(404).json({ error: 'Notification not found' });
                return;
            }
            res.status(204).send();
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to delete notification';
        res.status(500).json({ error: msg });
    }
});
exports.default = router;
