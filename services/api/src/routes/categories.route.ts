import { Router } from 'express';

import {
  createDevCategory,
  deleteDevCategory,
  listDevCategories,
  shouldUseLocalData,
  updateDevCategory,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  CreateCategorySchema,
  ListCategoriesQuerySchema,
  UpdateCategorySchema,
} from '../schemas/category.schema';

const router = Router();
const CATEGORY_SELECT = 'id, name, name_ml, icon, display_order, status';

router.get('/', async (req, res) => {
  const query = ListCategoriesQuerySchema.parse(req.query);

  try {
    let request = supabaseAdmin
      .from('activity_categories')
      .select(CATEGORY_SELECT)
      .order('display_order');

    if (query.status) {
      request = request.eq('status', query.status);
    }

    const { data, error } = await request;

    if (error) {
      if (shouldUseLocalData(error)) {
        res.json(listDevCategories(query.status));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      res.json(listDevCategories(query.status));
      return;
    }

    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

router.post('/', async (req, res) => {
  try {
    const body = CreateCategorySchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('activity_categories')
      .insert([body])
      .select(CATEGORY_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        res.status(201).json(createDevCategory(body));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json(data);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = CreateCategorySchema.parse(req.body);
      res.status(201).json(createDevCategory(body));
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to create category';
    res.status(400).json({ error: msg });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const body = UpdateCategorySchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('activity_categories')
      .update(body)
      .eq('id', req.params.id)
      .select(CATEGORY_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const updated = updateDevCategory(req.params.id, body);
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
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = UpdateCategorySchema.parse(req.body);
      const updated = updateDevCategory(req.params.id, body);
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
    const { error } = await supabaseAdmin
      .from('activity_categories')
      .delete()
      .eq('id', req.params.id);

    if (error) {
      if (shouldUseLocalData(error)) {
        const deleted = deleteDevCategory(req.params.id);
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
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const deleted = deleteDevCategory(req.params.id);
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

export default router;