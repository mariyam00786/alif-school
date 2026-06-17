import { Router } from 'express';

import { getDevClasses, listDevBatches, shouldUseLocalData } from '../dev-data';
import { supabaseAdmin } from '../integrations';

const router = Router();

router.get('/', async (_req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('batches')
      .select('id, name, name_ml, description, capacity, timing, status')
      .eq('status', 'active');

    if (error) {
      if (shouldUseLocalData(error)) {
        res.json(listDevBatches('active'));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      res.json(listDevBatches('active'));
      return;
    }

    res.status(500).json({ error: 'Failed to fetch batches' });
  }
});

router.get('/batch/:batchId/classes', async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('classes')
      .select('id, name, name_ml, level')
      .eq('batch_id', req.params.batchId)
      .eq('status', 'active');

    if (error) {
      if (shouldUseLocalData(error)) {
        res.json(getDevClasses(req.params.batchId));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      res.json(getDevClasses(req.params.batchId));
      return;
    }

    res.status(500).json({ error: 'Failed to fetch classes' });
  }
});

export default router;
