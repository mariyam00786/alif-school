"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const badge_schema_1 = require("../schemas/badge.schema");
const router = (0, express_1.Router)();
const BADGE_SELECT = 'id, name, name_ml, description, icon, criteria, bonus_points, status, created_at';
router.get('/', async (req, res) => {
    const query = badge_schema_1.ListBadgesQuerySchema.parse(req.query);
    try {
        let request = integrations_1.supabaseAdmin.from('badges').select(BADGE_SELECT).order('created_at', {
            ascending: false,
        });
        if (query.status) {
            request = request.eq('status', query.status);
        }
        const { data, error } = await request;
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.json((0, dev_data_1.listDevBadges)(query.status));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json(data || []);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            res.json((0, dev_data_1.listDevBadges)(query.status));
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to fetch badges';
        res.status(500).json({ error: msg });
    }
});
router.post('/', async (req, res) => {
    try {
        const body = badge_schema_1.CreateBadgeSchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('badges')
            .insert([body])
            .select(BADGE_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.status(201).json((0, dev_data_1.createDevBadge)(body));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(201).json(data);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const body = badge_schema_1.CreateBadgeSchema.parse(req.body);
            res.status(201).json((0, dev_data_1.createDevBadge)(body));
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to create badge';
        res.status(400).json({ error: msg });
    }
});
router.put('/:id', async (req, res) => {
    try {
        const body = badge_schema_1.UpdateBadgeSchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('badges')
            .update(body)
            .eq('id', req.params.id)
            .select(BADGE_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const updated = (0, dev_data_1.updateDevBadge)(req.params.id, body);
                if (!updated) {
                    res.status(404).json({ error: 'Badge not found' });
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
            const body = badge_schema_1.UpdateBadgeSchema.parse(req.body);
            const updated = (0, dev_data_1.updateDevBadge)(req.params.id, body);
            if (!updated) {
                res.status(404).json({ error: 'Badge not found' });
                return;
            }
            res.json(updated);
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to update badge';
        res.status(400).json({ error: msg });
    }
});
router.delete('/:id', async (req, res) => {
    try {
        const { error } = await integrations_1.supabaseAdmin.from('badges').delete().eq('id', req.params.id);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const deleted = (0, dev_data_1.deleteDevBadge)(req.params.id);
                if (!deleted) {
                    res.status(404).json({ error: 'Badge not found' });
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
            const deleted = (0, dev_data_1.deleteDevBadge)(req.params.id);
            if (!deleted) {
                res.status(404).json({ error: 'Badge not found' });
                return;
            }
            res.status(204).send();
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to delete badge';
        res.status(500).json({ error: msg });
    }
});
exports.default = router;
