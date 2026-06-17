"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const router = (0, express_1.Router)();
router.get('/', async (_req, res) => {
    try {
        const { data, error } = await integrations_1.supabaseAdmin
            .from('batches')
            .select('id, name, name_ml, description, capacity, timing, status')
            .eq('status', 'active');
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.json((0, dev_data_1.listDevBatches)('active'));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json(data || []);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            res.json((0, dev_data_1.listDevBatches)('active'));
            return;
        }
        res.status(500).json({ error: 'Failed to fetch batches' });
    }
});
router.get('/batch/:batchId/classes', async (req, res) => {
    try {
        const { data, error } = await integrations_1.supabaseAdmin
            .from('classes')
            .select('id, name, name_ml, level')
            .eq('batch_id', req.params.batchId)
            .eq('status', 'active');
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.json((0, dev_data_1.getDevClasses)(req.params.batchId));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json(data || []);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            res.json((0, dev_data_1.getDevClasses)(req.params.batchId));
            return;
        }
        res.status(500).json({ error: 'Failed to fetch classes' });
    }
});
exports.default = router;
