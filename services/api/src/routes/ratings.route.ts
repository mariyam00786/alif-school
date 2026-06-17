import { Router } from 'express';

import {
  createDevRating,
  deleteDevRating,
  listDevRatings,
  shouldUseLocalData,
  updateDevRating,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  CreateRatingSchema,
  ListRatingsQuerySchema,
  UpdateRatingSchema,
} from '../schemas/rating.schema';

const router = Router();
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
  const query = ListRatingsQuerySchema.parse(req.query);

  try {
    let request = supabaseAdmin
      .from('activity_ratings')
      .select(RATING_SELECT)
      .order('display_order');

    if (query.activity_id) {
      request = request.eq('activity_id', query.activity_id);
    }

    const { data, error } = await request;

    if (error) {
      if (shouldUseLocalData(error)) {
        res.json(listDevRatings(query.activity_id));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const query = ListRatingsQuerySchema.parse(req.query);
      res.json(listDevRatings(query.activity_id));
      return;
    }

    res.status(500).json({ error: 'Failed to fetch ratings' });
  }
});

router.post('/', async (req, res) => {
  try {
    const body = CreateRatingSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('activity_ratings')
      .insert([body])
      .select(RATING_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        res.status(201).json(createDevRating(body));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json(data);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = CreateRatingSchema.parse(req.body);
      res.status(201).json(createDevRating(body));
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to create rating';
    res.status(400).json({ error: msg });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const body = UpdateRatingSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('activity_ratings')
      .update(body)
      .eq('id', req.params.id)
      .select(RATING_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const updated = updateDevRating(req.params.id, body);
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
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = UpdateRatingSchema.parse(req.body);
      const updated = updateDevRating(req.params.id, body);
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
    const { error } = await supabaseAdmin.from('activity_ratings').delete().eq('id', req.params.id);

    if (error) {
      if (shouldUseLocalData(error)) {
        const deleted = deleteDevRating(req.params.id);
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
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const deleted = deleteDevRating(req.params.id);
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

export default router;