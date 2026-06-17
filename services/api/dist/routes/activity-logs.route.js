"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const activity_log_schema_1 = require("../schemas/activity-log.schema");
const router = (0, express_1.Router)();
const ACTIVITY_LOG_SELECT = `
  id,
  student_id,
  activity_id,
  rating_id,
  log_date,
  quantity,
  marks_earned,
  parent_approved,
  notes,
  activities(id, name, name_ml, category_id),
  activity_ratings(id, rating_name, rating_name_ml, marks)
`;
router.get('/', async (req, res) => {
    const query = activity_log_schema_1.ListActivityLogsQuerySchema.parse(req.query);
    try {
        let request = integrations_1.supabaseAdmin
            .from('activity_logs')
            .select(ACTIVITY_LOG_SELECT)
            .order('log_date', { ascending: false });
        if (query.student_id) {
            request = request.eq('student_id', query.student_id);
        }
        if (query.log_date) {
            request = request.eq('log_date', query.log_date);
        }
        if (query.from_date) {
            request = request.gte('log_date', query.from_date);
        }
        if (query.to_date) {
            request = request.lte('log_date', query.to_date);
        }
        const { data, error } = await request;
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.json((0, dev_data_1.listDevActivityLogs)(query));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json(data || []);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const query = activity_log_schema_1.ListActivityLogsQuerySchema.parse(req.query);
            res.json((0, dev_data_1.listDevActivityLogs)(query));
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to fetch activity logs';
        res.status(400).json({ error: msg });
    }
});
router.post('/', async (req, res) => {
    try {
        const body = activity_log_schema_1.CreateActivityLogSchema.parse(req.body);
        const { data: rating, error: ratingError } = await integrations_1.supabaseAdmin
            .from('activity_ratings')
            .select('marks')
            .eq('id', body.rating_id)
            .single();
        if (ratingError || !rating) {
            if ((0, dev_data_1.shouldUseLocalData)(ratingError ?? new Error('rating missing'))) {
                res.status(201).json((0, dev_data_1.createDevActivityLog)(body));
                return;
            }
            res.status(400).json({ error: ratingError?.message ?? 'Rating not found' });
            return;
        }
        const payload = {
            student_id: body.student_id,
            activity_id: body.activity_id,
            rating_id: body.rating_id,
            log_date: body.log_date,
            quantity: body.quantity ?? null,
            parent_approved: body.parent_approved ?? false,
            notes: body.notes ?? null,
            marks_earned: rating.marks,
        };
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activity_logs')
            .upsert(payload, { onConflict: 'student_id,activity_id,log_date' })
            .select(ACTIVITY_LOG_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.status(201).json((0, dev_data_1.createDevActivityLog)(body));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(201).json(data);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const body = activity_log_schema_1.CreateActivityLogSchema.parse(req.body);
            res.status(201).json((0, dev_data_1.createDevActivityLog)(body));
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to create activity log';
        res.status(400).json({ error: msg });
    }
});
router.put('/:id', async (req, res) => {
    try {
        const body = activity_log_schema_1.UpdateActivityLogSchema.parse(req.body);
        let marksEarned;
        if (body.rating_id) {
            const { data: rating, error: ratingError } = await integrations_1.supabaseAdmin
                .from('activity_ratings')
                .select('marks')
                .eq('id', body.rating_id)
                .single();
            if (ratingError || !rating) {
                if ((0, dev_data_1.shouldUseLocalData)(ratingError ?? new Error('rating missing'))) {
                    const updated = (0, dev_data_1.updateDevActivityLog)(req.params.id, body);
                    if (!updated) {
                        res.status(404).json({ error: 'Activity log not found' });
                        return;
                    }
                    res.json(updated);
                    return;
                }
                res.status(400).json({ error: ratingError?.message ?? 'Rating not found' });
                return;
            }
            marksEarned = rating.marks;
        }
        const payload = {
            ...body,
            quantity: body.quantity ?? null,
            notes: body.notes ?? null,
            ...(marksEarned != null ? { marks_earned: marksEarned } : {}),
        };
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activity_logs')
            .update(payload)
            .eq('id', req.params.id)
            .select(ACTIVITY_LOG_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const updated = (0, dev_data_1.updateDevActivityLog)(req.params.id, body);
                if (!updated) {
                    res.status(404).json({ error: 'Activity log not found' });
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
            const body = activity_log_schema_1.UpdateActivityLogSchema.parse(req.body);
            const updated = (0, dev_data_1.updateDevActivityLog)(req.params.id, body);
            if (!updated) {
                res.status(404).json({ error: 'Activity log not found' });
                return;
            }
            res.json(updated);
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to update activity log';
        res.status(400).json({ error: msg });
    }
});
router.delete('/:id', async (req, res) => {
    try {
        const { error } = await integrations_1.supabaseAdmin.from('activity_logs').delete().eq('id', req.params.id);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const deleted = (0, dev_data_1.deleteDevActivityLog)(req.params.id);
                if (!deleted) {
                    res.status(404).json({ error: 'Activity log not found' });
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
            const deleted = (0, dev_data_1.deleteDevActivityLog)(req.params.id);
            if (!deleted) {
                res.status(404).json({ error: 'Activity log not found' });
                return;
            }
            res.status(204).send();
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to delete activity log';
        res.status(400).json({ error: msg });
    }
});
exports.default = router;
