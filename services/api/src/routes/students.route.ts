import { Router } from 'express';

import {
  createDevStudent,
  deleteDevStudent,
  getDevStudent,
  listDevStudents,
  shouldUseLocalData,
  updateDevStudent,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  CreateStudentSchema,
  ListStudentsQuerySchema,
  UpdateStudentSchema,
} from '../schemas/student.schema';

const router = Router();
const STUDENT_SELECT = `
  id,
  profile_id,
  parent_phone,
  father_name,
  mother_name,
  date_of_birth,
  gender,
  batch_id,
  class_id,
  address,
  enrollment_date,
  status,
  profiles!students_profile_id_fkey(full_name, full_name_ml, phone),
  batches!students_batch_id_fkey(id, name, name_ml, description, capacity, timing, status),
  classes!students_class_id_fkey(id, name, name_ml, level)
`;

router.get('/', async (req, res) => {
  try {
    const query = ListStudentsQuerySchema.parse(req.query);

    let q = supabaseAdmin
      .from('students')
      .select(STUDENT_SELECT, { count: 'exact' })
      .range(query.offset, query.offset + query.limit - 1);

    if (query.search) {
      q = q.or(
        `parent_phone.ilike.%${query.search}%,father_name.ilike.%${query.search}%,mother_name.ilike.%${query.search}%`
      );
    }

    if (query.batch_id) {
      q = q.eq('batch_id', query.batch_id);
    }

    if (query.status) {
      q = q.eq('status', query.status);
    }

    const { data, error, count } = await q.order('enrollment_date', { ascending: false });

    if (error) {
      if (shouldUseLocalData(error)) {
        const fallback = listDevStudents(query);
        res.json({
          data: fallback.data,
          pagination: {
            limit: query.limit,
            offset: query.offset,
            total: fallback.total,
          },
        });
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json({
      data: data || [],
      pagination: {
        limit: query.limit,
        offset: query.offset,
        total: count || 0,
      },
    });
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const query = ListStudentsQuerySchema.parse(req.query);
      const fallback = listDevStudents(query);
      res.json({
        data: fallback.data,
        pagination: {
          limit: query.limit,
          offset: query.offset,
          total: fallback.total,
        },
      });
      return;
    }

    const msg = err instanceof Error ? err.message : 'Invalid query';
    res.status(400).json({ error: msg });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('students')
      .select(STUDENT_SELECT)
      .eq('id', req.params.id)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const student = getDevStudent(req.params.id);
        if (!student) {
          res.status(404).json({ error: 'Student not found' });
          return;
        }

        res.json(student);
        return;
      }

      res.status(404).json({ error: 'Student not found' });
      return;
    }

    res.json(data);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const student = getDevStudent(req.params.id);
      if (!student) {
        res.status(404).json({ error: 'Student not found' });
        return;
      }

      res.json(student);
      return;
    }

    res.status(500).json({ error: 'Failed to fetch student' });
  }
});

router.post('/', async (req, res) => {
  try {
    const body = CreateStudentSchema.parse(req.body);

    const payload = {
      parent_phone: body.parent_phone,
      father_name: body.father_name,
      mother_name: body.mother_name,
      date_of_birth: body.date_of_birth,
      gender: body.gender,
      batch_id: body.batch_id,
      class_id: body.class_id,
      address: body.address,
      status: 'active' as const,
      enrollment_date: new Date().toISOString().split('T')[0],
    };

    const { data, error } = await supabaseAdmin
      .from('students')
      .insert([payload])
      .select(STUDENT_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        res.status(201).json(createDevStudent(payload));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json(data);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = CreateStudentSchema.parse(req.body);
      res.status(201).json(
        createDevStudent({
          parent_phone: body.parent_phone,
          father_name: body.father_name,
          mother_name: body.mother_name,
          date_of_birth: body.date_of_birth,
          gender: body.gender,
          batch_id: body.batch_id,
          class_id: body.class_id,
          address: body.address,
        })
      );
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to create student';
    res.status(400).json({ error: msg });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const body = UpdateStudentSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('students')
      .update(body)
      .eq('id', req.params.id)
      .select(STUDENT_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const updated = updateDevStudent(req.params.id, body);
        if (!updated) {
          res.status(404).json({ error: 'Student not found' });
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
      const body = UpdateStudentSchema.parse(req.body);
      const updated = updateDevStudent(req.params.id, body);
      if (!updated) {
        res.status(404).json({ error: 'Student not found' });
        return;
      }

      res.json(updated);
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to update student';
    res.status(400).json({ error: msg });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const { error } = await supabaseAdmin.from('students').delete().eq('id', req.params.id);

    if (error) {
      if (shouldUseLocalData(error)) {
        const deleted = deleteDevStudent(req.params.id);
        if (!deleted) {
          res.status(404).json({ error: 'Student not found' });
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
      const deleted = deleteDevStudent(req.params.id);
      if (!deleted) {
        res.status(404).json({ error: 'Student not found' });
        return;
      }

      res.status(204).send();
      return;
    }

    res.status(500).json({ error: 'Failed to delete student' });
  }
});

export default router;
