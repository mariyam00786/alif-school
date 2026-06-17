import { Router } from 'express';

import {
  createDevClass,
  deleteDevClass,
  listDevClasses,
  shouldUseLocalData,
  updateDevClass,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  CreateClassSchema,
  ListClassesQuerySchema,
  UpdateClassSchema,
} from '../schemas/class.schema';

const router = Router();
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
  const query = ListClassesQuerySchema.parse(req.query);

  try {
    let request = supabaseAdmin.from('classes').select(CLASS_SELECT).order('name');

    if (query.batch_id) {
      request = request.eq('batch_id', query.batch_id);
    }

    if (query.status) {
      request = request.eq('status', query.status);
    }

    const { data, error } = await request;

    if (error) {
      if (shouldUseLocalData(error)) {
        res.json(listDevClasses(query));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      res.json(listDevClasses(query));
      return;
    }

    res.status(500).json({ error: 'Failed to fetch classes' });
  }
});

router.post('/', async (req, res) => {
  try {
    const body = CreateClassSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('classes')
      .insert([body])
      .select(CLASS_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        res.status(201).json(createDevClass(body));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json(data);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = CreateClassSchema.parse(req.body);
      res.status(201).json(createDevClass(body));
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to create class';
    res.status(400).json({ error: msg });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const body = UpdateClassSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('classes')
      .update(body)
      .eq('id', req.params.id)
      .select(CLASS_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const updated = updateDevClass(req.params.id, body);
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
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = UpdateClassSchema.parse(req.body);
      const updated = updateDevClass(req.params.id, body);
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
    const { error } = await supabaseAdmin.from('classes').delete().eq('id', req.params.id);

    if (error) {
      if (shouldUseLocalData(error)) {
        const deleted = deleteDevClass(req.params.id);
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
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const deleted = deleteDevClass(req.params.id);
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

export default router;
