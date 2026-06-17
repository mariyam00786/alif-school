"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const class_schema_1 = require("../schemas/class.schema");
const router = (0, express_1.Router)();
const CLASS_SELECT = `
  id,
  name,
  name_ml,
  level,
  batch_id,
  status,
  batches(id, name, name_ml)
`;
router.get('/', async (req, res) => {
    const query = class_schema_1.ListClassesQuerySchema.parse(req.query);
    try {
        let request = integrations_1.supabaseAdmin.from('classes').select(CLASS_SELECT).order('name');
        if (query.batch_id) {
            request = request.eq('batch_id', query.batch_id);
        }
        if (query.status) {
            request = request.eq('status', query.status);
        }
        const { data, error } = await request;
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.json((0, dev_data_1.listDevClasses)(query));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json(data || []);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            res.json((0, dev_data_1.listDevClasses)(query));
            return;
        }
        res.status(500).json({ error: 'Failed to fetch classes' });
    }
});
router.post('/', async (req, res) => {
    try {
        const body = class_schema_1.CreateClassSchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('classes')
            .insert([body])
            .select(CLASS_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.status(201).json((0, dev_data_1.createDevClass)(body));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(201).json(data);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const body = class_schema_1.CreateClassSchema.parse(req.body);
            res.status(201).json((0, dev_data_1.createDevClass)(body));
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to create class';
        res.status(400).json({ error: msg });
    }
});
router.put('/:id', async (req, res) => {
    try {
        const body = class_schema_1.UpdateClassSchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('classes')
            .update(body)
            .eq('id', req.params.id)
            .select(CLASS_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const updated = (0, dev_data_1.updateDevClass)(req.params.id, body);
                if (!updated) {
                    res.status(404).json({ error: 'Class not found' });
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
            const body = class_schema_1.UpdateClassSchema.parse(req.body);
            const updated = (0, dev_data_1.updateDevClass)(req.params.id, body);
            if (!updated) {
                res.status(404).json({ error: 'Class not found' });
                return;
            }
            res.json(updated);
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to update class';
        res.status(400).json({ error: msg });
    }
});
router.delete('/:id', async (req, res) => {
    try {
        const { error } = await integrations_1.supabaseAdmin.from('classes').delete().eq('id', req.params.id);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const deleted = (0, dev_data_1.deleteDevClass)(req.params.id);
                if (!deleted) {
                    res.status(404).json({ error: 'Class not found' });
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
            const deleted = (0, dev_data_1.deleteDevClass)(req.params.id);
            if (!deleted) {
                res.status(404).json({ error: 'Class not found' });
                return;
            }
            res.status(204).send();
            return;
        }
        res.status(500).json({ error: 'Failed to delete class' });
    }
});
exports.default = router;
