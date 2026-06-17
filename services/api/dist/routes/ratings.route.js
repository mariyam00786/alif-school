"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const rating_schema_1 = require("../schemas/rating.schema");
const router = (0, express_1.Router)();
const RATING_SELECT = `
  id,
  activity_id,
  rating_name,
  rating_name_ml,
  marks,
  color,
  display_order,
  activities(id, name, name_ml)
`;
router.get('/', async (req, res) => {
    const query = rating_schema_1.ListRatingsQuerySchema.parse(req.query);
    try {
        let request = integrations_1.supabaseAdmin
            .from('activity_ratings')
            .select(RATING_SELECT)
            .order('display_order');
        if (query.activity_id) {
            request = request.eq('activity_id', query.activity_id);
        }
        const { data, error } = await request;
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.json((0, dev_data_1.listDevRatings)(query.activity_id));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json(data || []);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const query = rating_schema_1.ListRatingsQuerySchema.parse(req.query);
            res.json((0, dev_data_1.listDevRatings)(query.activity_id));
            return;
        }
        res.status(500).json({ error: 'Failed to fetch ratings' });
    }
});
router.post('/', async (req, res) => {
    try {
        const body = rating_schema_1.CreateRatingSchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activity_ratings')
            .insert([body])
            .select(RATING_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.status(201).json((0, dev_data_1.createDevRating)(body));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(201).json(data);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const body = rating_schema_1.CreateRatingSchema.parse(req.body);
            res.status(201).json((0, dev_data_1.createDevRating)(body));
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to create rating';
        res.status(400).json({ error: msg });
    }
});
router.put('/:id', async (req, res) => {
    try {
        const body = rating_schema_1.UpdateRatingSchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activity_ratings')
            .update(body)
            .eq('id', req.params.id)
            .select(RATING_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const updated = (0, dev_data_1.updateDevRating)(req.params.id, body);
                if (!updated) {
                    res.status(404).json({ error: 'Rating not found' });
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
            const body = rating_schema_1.UpdateRatingSchema.parse(req.body);
            const updated = (0, dev_data_1.updateDevRating)(req.params.id, body);
            if (!updated) {
                res.status(404).json({ error: 'Rating not found' });
                return;
            }
            res.json(updated);
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to update rating';
        res.status(400).json({ error: msg });
    }
});
router.delete('/:id', async (req, res) => {
    try {
        const { error } = await integrations_1.supabaseAdmin.from('activity_ratings').delete().eq('id', req.params.id);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const deleted = (0, dev_data_1.deleteDevRating)(req.params.id);
                if (!deleted) {
                    res.status(404).json({ error: 'Rating not found' });
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
            const deleted = (0, dev_data_1.deleteDevRating)(req.params.id);
            if (!deleted) {
                res.status(404).json({ error: 'Rating not found' });
                return;
            }
            res.status(204).send();
            return;
        }
        res.status(500).json({ error: 'Failed to delete rating' });
    }
});
exports.default = router;
