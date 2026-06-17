import { Router } from 'express';

import {
  getDevBatch,
  getDevClass,
  getDevStudent,
  getDevTeacher,
  listDevActivityLogs,
  listDevBatches,
  listDevStudents,
  listDevTeachers,
  shouldUseLocalData,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  TeacherBatchAnalyticsQuerySchema,
  TeacherStudentsQuerySchema,
  TeacherStudentProgressQuerySchema,
} from '../schemas/teacher-app.schema';

const router = Router();

router.get('/batches', async (_req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('teacher_batches')
      .select('teacher_id, batch_id, batches(id, name, name_ml)');

    if (error) {
      if (shouldUseLocalData(error)) {
        const teachers = listDevTeachers({});
        const rows = teachers.map((teacher) => ({
          teacher_id: teacher.id,
          teacher_name: teacher.full_name,
          batches: teacher.teacher_batches.map((item) => item.batches),
        }));
        res.json(rows);
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    const map = new Map<string, { teacher_id: string; batches: unknown[] }>();
    for (const row of data || []) {
      const current =
        map.get(row.teacher_id) ??
        ({ teacher_id: row.teacher_id, batches: [] as unknown[] });
      const resolvedBatches = Array.isArray(row.batches) ? row.batches : [row.batches];
      current.batches.push(...resolvedBatches.filter((item) => item != null));
      map.set(row.teacher_id, current);
    }

    res.json(Array.from(map.values()));
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch teacher batches';
    res.status(500).json({ error: msg });
  }
});

router.get('/students', async (req, res) => {
  const query = TeacherStudentsQuerySchema.parse(req.query);

  try {
    let request = supabaseAdmin
      .from('students')
      .select('id, father_name, mother_name, parent_phone, batch_id, class_id, status')
      .order('enrollment_date', { ascending: false });

    if (query.batch_id) {
      request = request.eq('batch_id', query.batch_id);
    }

    const { data, error } = await request;

    if (error) {
      if (shouldUseLocalData(error)) {
        const rows = listDevStudents({
          limit: 500,
          offset: 0,
          batch_id: query.batch_id,
        }).data;
        res.json(rows);
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch teacher students';
    res.status(500).json({ error: msg });
  }
});

router.get('/student/:id/progress', async (req, res) => {
  const query = TeacherStudentProgressQuerySchema.parse(req.query);

  try {
    let request = supabaseAdmin
      .from('activity_logs')
      .select('id, student_id, activity_id, log_date, marks_earned')
      .eq('student_id', req.params.id)
      .order('log_date', { ascending: false });

    if (query.from_date) {
      request = request.gte('log_date', query.from_date);
    }
    if (query.to_date) {
      request = request.lte('log_date', query.to_date);
    }

    const { data, error } = await request;

    if (error) {
      if (shouldUseLocalData(error)) {
        const logs = listDevActivityLogs({
          student_id: req.params.id,
          from_date: query.from_date,
          to_date: query.to_date,
        });
        const total = logs.reduce((sum, item) => sum + item.marks_earned, 0);
        res.json({
          student: getDevStudent(req.params.id),
          summary: { total_marks: total, total_activities: logs.length },
          data: logs,
        });
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    const logs = data || [];
    const total = logs.reduce((sum, item) => sum + Number(item.marks_earned ?? 0), 0);
    res.json({
      summary: { total_marks: total, total_activities: logs.length },
      data: logs,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch student progress';
    res.status(500).json({ error: msg });
  }
});

router.get('/batch/:id/analytics', async (req, res) => {
  const query = TeacherBatchAnalyticsQuerySchema.parse(req.query);

  try {
    const { data: students, error: studentsError } = await supabaseAdmin
      .from('students')
      .select('id, father_name, mother_name, batch_id, class_id')
      .eq('batch_id', req.params.id);

    if (studentsError) {
      if (shouldUseLocalData(studentsError)) {
        const rows = listDevStudents({
          limit: 500,
          offset: 0,
          batch_id: req.params.id,
        }).data;
        const studentIds = rows.map((item) => item.id);
        const logs = listDevActivityLogs({
          from_date: query.from_date,
          to_date: query.to_date,
        }).filter((item) => studentIds.includes(item.student_id));
        const totalMarks = logs.reduce((sum, item) => sum + item.marks_earned, 0);

        res.json({
          batch: getDevBatch(req.params.id),
          summary: {
            students: rows.length,
            total_marks: totalMarks,
            total_activities: logs.length,
            completion_rate: rows.length === 0 ? 0 : Number((logs.length / rows.length).toFixed(2)),
          },
        });
        return;
      }

      res.status(400).json({ error: studentsError.message });
      return;
    }

    const studentIds = (students || []).map((item) => item.id);

    let logsRequest = supabaseAdmin
      .from('activity_logs')
      .select('student_id, marks_earned, log_date')
      .in('student_id', studentIds);

    if (query.from_date) {
      logsRequest = logsRequest.gte('log_date', query.from_date);
    }

    if (query.to_date) {
      logsRequest = logsRequest.lte('log_date', query.to_date);
    }

    const { data: logs, error: logsError } = await logsRequest;

    if (logsError) {
      throw logsError;
    }

    const totalMarks = (logs || []).reduce((sum, item) => sum + Number(item.marks_earned ?? 0), 0);

    res.json({
      batch: getDevBatch(req.params.id),
      summary: {
        students: studentIds.length,
        total_marks: totalMarks,
        total_activities: (logs || []).length,
        completion_rate:
          studentIds.length === 0
            ? 0
            : Number((((logs || []).length / studentIds.length) || 0).toFixed(2)),
      },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch batch analytics';
    res.status(500).json({ error: msg });
  }
});

export default router;
