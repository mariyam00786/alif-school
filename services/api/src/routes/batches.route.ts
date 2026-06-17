import { Router } from 'express';

import {
  createDevBatch,
  deleteDevBatch,
  listDevBatches,
  shouldUseLocalData,
  updateDevBatch,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  CreateBatchSchema,
  ListBatchesQuerySchema,
  UpdateBatchSchema,
} from '../schemas/batch.schema';

const router = Router();
const BATCH_SELECT = 'id, name, name_ml, description, capacity, timing, status';

router.get('/', async (req, res) => {
  const query = ListBatchesQuerySchema.parse(req.query);

  try {
    let request = supabaseAdmin.from('batches').select(BATCH_SELECT).order('name');

    if (query.status) {
      request = request.eq('status', query.status);
    }

    const { data, error } = await request;

    if (error) {
      if (shouldUseLocalData(error)) {
        res.json(listDevBatches(query.status));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      res.json(listDevBatches(query.status));
      return;
    }

    res.status(500).json({ error: 'Failed to fetch batches' });
  }
});

router.post('/', async (req, res) => {
  try {
    const body = CreateBatchSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('batches')
      .insert([body])
      .select(BATCH_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        res.status(201).json(createDevBatch(body));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json(data);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = CreateBatchSchema.parse(req.body);
      res.status(201).json(createDevBatch(body));
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to create batch';
    res.status(400).json({ error: msg });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const body = UpdateBatchSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('batches')
      .update(body)
      .eq('id', req.params.id)
      .select(BATCH_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const updated = updateDevBatch(req.params.id, body);
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
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = UpdateBatchSchema.parse(req.body);
      const updated = updateDevBatch(req.params.id, body);
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
    const { error } = await supabaseAdmin.from('batches').delete().eq('id', req.params.id);

    if (error) {
      if (shouldUseLocalData(error)) {
        const deleted = deleteDevBatch(req.params.id);
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
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const deleted = deleteDevBatch(req.params.id);
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

export default router;