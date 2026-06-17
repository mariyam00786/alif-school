import { Router } from 'express';

import {
  createDevTeacher,
  deleteDevTeacher,
  getDevTeacher,
  listDevTeachers,
  shouldUseLocalData,
  updateDevTeacher,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  CreateTeacherSchema,
  ListTeachersQuerySchema,
  UpdateTeacherSchema,
} from '../schemas/teacher.schema';

const router = Router();
const TEACHER_SELECT = `
  id,
  profile_id,
  email,
  qualification,
  status,
  profiles!teachers_profile_id_fkey(full_name, phone),
  teacher_batches(batch_id, batches(id, name, name_ml))
`;

function mapTeacherRow(row: any) {
  return {
    id: row.id,
    profile_id: row.profile_id,
    full_name: row.profiles?.full_name ?? '',
    mobile_number: row.profiles?.phone ?? '',
    email: row.email,
    qualification: row.qualification,
    status: row.status ?? 'active',
    batch_ids: (row.teacher_batches ?? []).map((item: any) => item.batch_id),
    teacher_batches: row.teacher_batches ?? [],
  };
}

router.get('/', async (req, res) => {
  const query = ListTeachersQuerySchema.parse(req.query);

  try {
    let request = supabaseAdmin.from('teachers').select(TEACHER_SELECT).order('created_at', { ascending: false });

    if (query.status) {
      request = request.eq('status', query.status);
    }

    const { data, error } = await request;

    if (error) {
      if (shouldUseLocalData(error)) {
        res.json(listDevTeachers(query));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    let mapped = (data ?? []).map(mapTeacherRow);
    if (query.search) {
      const search = query.search.toLowerCase();
      mapped = mapped.filter(
        (teacher) =>
          teacher.full_name.toLowerCase().includes(search) ||
          teacher.mobile_number.toLowerCase().includes(search) ||
          (teacher.email ?? '').toLowerCase().includes(search)
      );
    }

    if (query.batch_id) {
      mapped = mapped.filter((teacher) => teacher.batch_ids.includes(query.batch_id));
    }

    res.json(mapped);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      res.json(listDevTeachers(query));
      return;
    }

    res.status(500).json({ error: 'Failed to fetch teachers' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('teachers')
      .select(TEACHER_SELECT)
      .eq('id', req.params.id)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const teacher = getDevTeacher(req.params.id);
        if (!teacher) {
          res.status(404).json({ error: 'Teacher not found' });
          return;
        }

        res.json(teacher);
        return;
      }

      res.status(404).json({ error: 'Teacher not found' });
      return;
    }

    res.json(mapTeacherRow(data));
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const teacher = getDevTeacher(req.params.id);
      if (!teacher) {
        res.status(404).json({ error: 'Teacher not found' });
        return;
      }

      res.json(teacher);
      return;
    }

    res.status(500).json({ error: 'Failed to fetch teacher' });
  }
});

router.post('/', async (req, res) => {
  try {
    const body = CreateTeacherSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('teachers')
      .insert([
        {
          email: body.email,
          qualification: body.qualification,
          status: body.status ?? 'active',
        },
      ])
      .select(TEACHER_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        res.status(201).json(
          createDevTeacher({
            full_name: body.full_name,
            mobile_number: body.mobile_number,
            email: body.email,
            qualification: body.qualification,
            status: body.status ?? 'active',
            batch_ids: body.batch_ids,
          })
        );
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json(mapTeacherRow(data));
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = CreateTeacherSchema.parse(req.body);
      res.status(201).json(
        createDevTeacher({
          full_name: body.full_name,
          mobile_number: body.mobile_number,
          email: body.email,
          qualification: body.qualification,
          status: body.status ?? 'active',
          batch_ids: body.batch_ids,
        })
      );
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to create teacher';
    res.status(400).json({ error: msg });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const body = UpdateTeacherSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('teachers')
      .update({
        email: body.email,
        qualification: body.qualification,
        status: body.status,
      })
      .eq('id', req.params.id)
      .select(TEACHER_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const updated = updateDevTeacher(req.params.id, body);
        if (!updated) {
          res.status(404).json({ error: 'Teacher not found' });
          return;
        }

        res.json(updated);
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(mapTeacherRow(data));
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = UpdateTeacherSchema.parse(req.body);
      const updated = updateDevTeacher(req.params.id, body);
      if (!updated) {
        res.status(404).json({ error: 'Teacher not found' });
        return;
      }

      res.json(updated);
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to update teacher';
    res.status(400).json({ error: msg });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const { error } = await supabaseAdmin.from('teachers').delete().eq('id', req.params.id);

    if (error) {
      if (shouldUseLocalData(error)) {
        const deleted = deleteDevTeacher(req.params.id);
        if (!deleted) {
          res.status(404).json({ error: 'Teacher not found' });
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
      const deleted = deleteDevTeacher(req.params.id);
      if (!deleted) {
        res.status(404).json({ error: 'Teacher not found' });
        return;
      }

      res.status(204).send();
      return;
    }

    res.status(500).json({ error: 'Failed to delete teacher' });
  }
});

export default router;