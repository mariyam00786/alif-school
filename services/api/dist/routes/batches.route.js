"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const batch_schema_1 = require("../schemas/batch.schema");
const router = (0, express_1.Router)();
const BATCH_SELECT = 'id, name, name_ml, description, capacity, timing, status';
router.get('/', async (req, res) => {
    const query = batch_schema_1.ListBatchesQuerySchema.parse(req.query);
    try {
        let request = integrations_1.supabaseAdmin.from('batches').select(BATCH_SELECT).order('name');
        if (query.status) {
            request = request.eq('status', query.status);
        }
        const { data, error } = await request;
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.json((0, dev_data_1.listDevBatches)(query.status));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json(data || []);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            res.json((0, dev_data_1.listDevBatches)(query.status));
            return;
        }
        res.status(500).json({ error: 'Failed to fetch batches' });
    }
});
router.post('/', async (req, res) => {
    try {
        const body = batch_schema_1.CreateBatchSchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('batches')
            .insert([body])
            .select(BATCH_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.status(201).json((0, dev_data_1.createDevBatch)(body));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(201).json(data);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const body = batch_schema_1.CreateBatchSchema.parse(req.body);
            res.status(201).json((0, dev_data_1.createDevBatch)(body));
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to create batch';
        res.status(400).json({ error: msg });
    }
});
router.put('/:id', async (req, res) => {
    try {
        const body = batch_schema_1.UpdateBatchSchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('batches')
            .update(body)
            .eq('id', req.params.id)
            .select(BATCH_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const updated = (0, dev_data_1.updateDevBatch)(req.params.id, body);
                if (!updated) {
                    res.status(404).json({ error: 'Batch not found' });
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
            const body = batch_schema_1.UpdateBatchSchema.parse(req.body);
            const updated = (0, dev_data_1.updateDevBatch)(req.params.id, body);
            if (!updated) {
                res.status(404).json({ error: 'Batch not found' });
                return;
            }
            res.json(updated);
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to update batch';
        res.status(400).json({ error: msg });
    }
});
router.delete('/:id', async (req, res) => {
    try {
        const { error } = await integrations_1.supabaseAdmin.from('batches').delete().eq('id', req.params.id);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const deleted = (0, dev_data_1.deleteDevBatch)(req.params.id);
                if (!deleted) {
                    res.status(404).json({ error: 'Batch not found' });
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
            const deleted = (0, dev_data_1.deleteDevBatch)(req.params.id);
            if (!deleted) {
                res.status(404).json({ error: 'Batch not found' });
                return;
            }
            res.status(204).send();
            return;
        }
        res.status(500).json({ error: 'Failed to delete batch' });
    }
});
exports.default = router;
