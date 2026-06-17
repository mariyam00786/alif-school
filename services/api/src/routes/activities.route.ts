import { Router } from 'express';

import {
  createDevActivity,
  deleteDevActivity,
  listDevActivities,
  shouldUseLocalData,
  updateDevActivity,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  CreateActivitySchema,
  ListActivitiesQuerySchema,
  UpdateActivitySchema,
} from '../schemas/activity.schema';

const router = Router();
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
  const query = ListActivitiesQuerySchema.parse(req.query);

  try {
    let request = supabaseAdmin
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
      if (shouldUseLocalData(error)) {
        res.json(listDevActivities(query));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      res.json(listDevActivities(query));
      return;
    }

    res.status(500).json({ error: 'Failed to fetch activities' });
  }
});

router.post('/', async (req, res) => {
  try {
    const body = CreateActivitySchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('activities')
      .insert([body])
      .select(ACTIVITY_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        res.status(201).json(createDevActivity(body));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json(data);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = CreateActivitySchema.parse(req.body);
      res.status(201).json(createDevActivity(body));
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to create activity';
    res.status(400).json({ error: msg });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const body = UpdateActivitySchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('activities')
      .update(body)
      .eq('id', req.params.id)
      .select(ACTIVITY_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const updated = updateDevActivity(req.params.id, body);
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
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = UpdateActivitySchema.parse(req.body);
      const updated = updateDevActivity(req.params.id, body);
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
    const { error } = await supabaseAdmin.from('activities').delete().eq('id', req.params.id);

    if (error) {
      if (shouldUseLocalData(error)) {
        const deleted = deleteDevActivity(req.params.id);
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
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const deleted = deleteDevActivity(req.params.id);
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

export default router;