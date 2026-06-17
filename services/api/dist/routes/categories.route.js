"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const category_schema_1 = require("../schemas/category.schema");
const router = (0, express_1.Router)();
const CATEGORY_SELECT = 'id, name, name_ml, icon, display_order, status';
router.get('/', async (req, res) => {
    const query = category_schema_1.ListCategoriesQuerySchema.parse(req.query);
    try {
        let request = integrations_1.supabaseAdmin
            .from('activity_categories')
            .select(CATEGORY_SELECT)
            .order('display_order');
        if (query.status) {
            request = request.eq('status', query.status);
        }
        const { data, error } = await request;
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.json((0, dev_data_1.listDevCategories)(query.status));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json(data || []);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            res.json((0, dev_data_1.listDevCategories)(query.status));
            return;
        }
        res.status(500).json({ error: 'Failed to fetch categories' });
    }
});
router.post('/', async (req, res) => {
    try {
        const body = category_schema_1.CreateCategorySchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activity_categories')
            .insert([body])
            .select(CATEGORY_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.status(201).json((0, dev_data_1.createDevCategory)(body));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(201).json(data);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const body = category_schema_1.CreateCategorySchema.parse(req.body);
            res.status(201).json((0, dev_data_1.createDevCategory)(body));
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to create category';
        res.status(400).json({ error: msg });
    }
});
router.put('/:id', async (req, res) => {
    try {
        const body = category_schema_1.UpdateCategorySchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activity_categories')
            .update(body)
            .eq('id', req.params.id)
            .select(CATEGORY_SELECT)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const updated = (0, dev_data_1.updateDevCategory)(req.params.id, body);
                if (!updated) {
                    res.status(404).json({ error: 'Category not found' });
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
            const body = category_schema_1.UpdateCategorySchema.parse(req.body);
            const updated = (0, dev_data_1.updateDevCategory)(req.params.id, body);
            if (!updated) {
                res.status(404).json({ error: 'Category not found' });
                return;
            }
            res.json(updated);
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to update category';
        res.status(400).json({ error: msg });
    }
});
router.delete('/:id', async (req, res) => {
    try {
        const { error } = await integrations_1.supabaseAdmin
            .from('activity_categories')
            .delete()
            .eq('id', req.params.id);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const deleted = (0, dev_data_1.deleteDevCategory)(req.params.id);
                if (!deleted) {
                    res.status(404).json({ error: 'Category not found' });
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
            const deleted = (0, dev_data_1.deleteDevCategory)(req.params.id);
            if (!deleted) {
                res.status(404).json({ error: 'Category not found' });
                return;
            }
            res.status(204).send();
            return;
        }
        res.status(500).json({ error: 'Failed to delete category' });
    }
});
exports.default = router;
