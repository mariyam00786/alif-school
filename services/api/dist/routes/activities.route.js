"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const activity_schema_1 = require("../schemas/activity.schema");
const router = (0, express_1.Router)();
const ACTIVITY_SELECT = `
  id,
  category_id,
  name,
  name_ml,
  display_order,
  has_quantity,
  status,
  activity_categories(id, name, name_ml)
`;
router.get('/', async (req, res) => {
    const query = activity_schema_1.ListActivitiesQuerySchema.parse(req.query);
    try {
        let request = integrations_1.supabaseAdmin
            .from('activities')
            .select(ACTIVITY_SELECT)
            .order('display_order');
        if (query.category_id) {
            request = request.eq('category_id', query.category_id);
        }
        if (query.status) {
            request = request.eq('status', query.status);
        }
        const { data, error } = await request;
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.json((0, dev_data_1.listDevActivities)(query));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json(data || []);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            res.json((0, dev_data_1.listDevActivities)(query));
            return;
        }
        res.status(500).json({ error: 'Failed to fetch activities' });
    }
});
router.post('/', async (req, res) => {
    try {
        const body = activity_schema_1.CreateActivitySchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activities')
            .insert([body])
            .select(ACTIVITY_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.status(201).json((0, dev_data_1.createDevActivity)(body));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(201).json(data);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const body = activity_schema_1.CreateActivitySchema.parse(req.body);
            res.status(201).json((0, dev_data_1.createDevActivity)(body));
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to create activity';
        res.status(400).json({ error: msg });
    }
});
router.put('/:id', async (req, res) => {
    try {
        const body = activity_schema_1.UpdateActivitySchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activities')
            .update(body)
            .eq('id', req.params.id)
            .select(ACTIVITY_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const updated = (0, dev_data_1.updateDevActivity)(req.params.id, body);
                if (!updated) {
                    res.status(404).json({ error: 'Activity not found' });
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
            const body = activity_schema_1.UpdateActivitySchema.parse(req.body);
            const updated = (0, dev_data_1.updateDevActivity)(req.params.id, body);
            if (!updated) {
                res.status(404).json({ error: 'Activity not found' });
                return;
            }
            res.json(updated);
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to update activity';
        res.status(400).json({ error: msg });
    }
});
router.delete('/:id', async (req, res) => {
    try {
        const { error } = await integrations_1.supabaseAdmin.from('activities').delete().eq('id', req.params.id);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const deleted = (0, dev_data_1.deleteDevActivity)(req.params.id);
                if (!deleted) {
                    res.status(404).json({ error: 'Activity not found' });
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
            const deleted = (0, dev_data_1.deleteDevActivity)(req.params.id);
            if (!deleted) {
                res.status(404).json({ error: 'Activity not found' });
                return;
            }
            res.status(204).send();
            return;
        }
        res.status(500).json({ error: 'Failed to delete activity' });
    }
});
exports.default = router;
