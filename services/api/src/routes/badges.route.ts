import { Router } from 'express';

import {
  createDevBadge,
  deleteDevBadge,
  listDevBadges,
  shouldUseLocalData,
  updateDevBadge,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  CreateBadgeSchema,
  ListBadgesQuerySchema,
  UpdateBadgeSchema,
} from '../schemas/badge.schema';

const router = Router();
const BADGE_SELECT =
  'id, name, name_ml, description, icon, criteria, bonus_points, status, created_at';

router.get('/', async (req, res) => {
  const query = ListBadgesQuerySchema.parse(req.query);

  try {
    let request = supabaseAdmin.from('badges').select(BADGE_SELECT).order('created_at', {
      ascending: false,
    });

    if (query.status) {
      request = request.eq('status', query.status);
    }

    const { data, error } = await request;

    if (error) {
      if (shouldUseLocalData(error)) {
        res.json(listDevBadges(query.status));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      res.json(listDevBadges(query.status));
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to fetch badges';
    res.status(500).json({ error: msg });
  }
});

router.post('/', async (req, res) => {
  try {
    const body = CreateBadgeSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('badges')
      .insert([body])
      .select(BADGE_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        res.status(201).json(createDevBadge(body));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json(data);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = CreateBadgeSchema.parse(req.body);
      res.status(201).json(createDevBadge(body));
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to create badge';
    res.status(400).json({ error: msg });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const body = UpdateBadgeSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('badges')
      .update(body)
      .eq('id', req.params.id)
      .select(BADGE_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const updated = updateDevBadge(req.params.id, body);
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
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = UpdateBadgeSchema.parse(req.body);
      const updated = updateDevBadge(req.params.id, body);
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
    const { error } = await supabaseAdmin.from('badges').delete().eq('id', req.params.id);

    if (error) {
      if (shouldUseLocalData(error)) {
        const deleted = deleteDevBadge(req.params.id);
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
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const deleted = deleteDevBadge(req.params.id);
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

export default router;
