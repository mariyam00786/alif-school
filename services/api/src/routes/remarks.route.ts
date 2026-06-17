import { Router } from 'express';

import {
  createDevTeacherRemark,
  listDevTeacherRemarks,
  shouldUseLocalData,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import { CreateRemarkSchema, ListRemarksQuerySchema } from '../schemas/remark.schema';

const router = Router();

router.get('/', async (req, res) => {
  const query = ListRemarksQuerySchema.parse(req.query);

  try {
    let request = supabaseAdmin
      .from('teacher_remarks')
      .select('id, teacher_id, student_id, remark, created_at')
      .order('created_at', { ascending: false })
      .limit(query.limit);

    if (query.teacher_id) {
      request = request.eq('teacher_id', query.teacher_id);
    }

    if (query.student_id) {
      request = request.eq('student_id', query.student_id);
    }

    const { data, error } = await request;

    if (error) {
      if (shouldUseLocalData(error)) {
        res.json(
          listDevTeacherRemarks({
            teacher_id: query.teacher_id,
            student_id: query.student_id,
            limit: query.limit,
          })
        );
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    const remarks = data || [];
    const teacherIds = Array.from(new Set(remarks.map((item) => item.teacher_id))).filter(Boolean);
    const studentIds = Array.from(new Set(remarks.map((item) => item.student_id))).filter(Boolean);

    const [teacherResult, studentResult] = await Promise.all([
      teacherIds.length > 0
        ? supabaseAdmin
            .from('teachers')
            .select('id, profiles!teachers_profile_id_fkey(full_name)')
            .in('id', teacherIds)
        : Promise.resolve({ data: [], error: null }),
      studentIds.length > 0
        ? supabaseAdmin
            .from('students')
            .select('id, father_name, mother_name, parent_phone')
            .in('id', studentIds)
        : Promise.resolve({ data: [], error: null }),
    ]);

    if (teacherResult.error || studentResult.error) {
      const msg = teacherResult.error?.message ?? studentResult.error?.message ?? 'Failed to fetch related data';
      res.status(400).json({ error: msg });
      return;
    }

    const teacherMap = new Map(
      (teacherResult.data || []).map((item: any) => [item.id, item.profiles?.full_name ?? null])
    );
    const studentMap = new Map(
      (studentResult.data || []).map((item: any) => [
        item.id,
        {
          student_name: [item.father_name, item.mother_name]
            .filter((part: unknown) => typeof part === 'string' && part.trim().length > 0)
            .join(' / '),
          parent_phone: item.parent_phone ?? null,
        },
      ])
    );

    res.json(
      remarks.map((item) => ({
        ...item,
        teacher_name: teacherMap.get(item.teacher_id) ?? null,
        student_name: studentMap.get(item.student_id)?.student_name ?? null,
        parent_phone: studentMap.get(item.student_id)?.parent_phone ?? null,
      }))
    );
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const query = ListRemarksQuerySchema.parse(req.query);
      res.json(
        listDevTeacherRemarks({
          teacher_id: query.teacher_id,
          student_id: query.student_id,
          limit: query.limit,
        })
      );
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to fetch remarks';
    res.status(500).json({ error: msg });
  }
});

router.post('/', async (req, res) => {
  try {
    const body = CreateRemarkSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('teacher_remarks')
      .insert([
        {
          teacher_id: body.teacher_id,
          student_id: body.student_id,
          remark: body.remark,
        },
      ])
      .select('id, teacher_id, student_id, remark, created_at')
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const created = createDevTeacherRemark(body);
        if (!created) {
          res.status(500).json({ error: 'Failed to create remark' });
          return;
        }

        res.status(201).json(created);
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json(data);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = CreateRemarkSchema.parse(req.body);
      const created = createDevTeacherRemark(body);
      if (!created) {
        res.status(500).json({ error: 'Failed to create remark' });
        return;
      }

      res.status(201).json(created);
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to create remark';
    res.status(400).json({ error: msg });
  }
});

export default router;
