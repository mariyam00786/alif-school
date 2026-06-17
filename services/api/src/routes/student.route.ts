import { Router } from 'express';

import {
  getDevBatch,
  getDevStudent,
  listDevActivityLogs,
  listDevStudentBadges,
  listDevStudents,
  shouldUseLocalData,
  updateDevStudent,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  StudentApprovalHistoryQuerySchema,
  StudentBadgesQuerySchema,
  StudentChildrenQuerySchema,
  StudentLeaderboardQuerySchema,
  StudentProfileQuerySchema,
  StudentProgressQuerySchema,
  UpdateStudentProfileSchema,
} from '../schemas/student-app.schema';

const router = Router();

function toIsoDate(value: Date) {
  return value.toISOString().split('T')[0];
}

function mondayOfWeek(date: Date) {
  const normalized = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = normalized.getUTCDay();
  const diff = day === 0 ? -6 : 1 - day;
  normalized.setUTCDate(normalized.getUTCDate() + diff);
  return normalized;
}

function firstDayOfMonth(date: Date) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1));
}

function lastDayOfMonth(date: Date) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 0));
}

function dateRange(period: string, date?: string) {
  const seed = date ? new Date(`${date}T00:00:00.000Z`) : new Date();

  if (period === 'daily') {
    const d = toIsoDate(seed);
    return { from: d, to: d };
  }

  if (period === 'weekly') {
    const start = mondayOfWeek(seed);
    const end = new Date(start);
    end.setUTCDate(start.getUTCDate() + 6);
    return { from: toIsoDate(start), to: toIsoDate(end) };
  }

  if (period === 'monthly') {
    const start = firstDayOfMonth(seed);
    const end = lastDayOfMonth(seed);
    return { from: toIsoDate(start), to: toIsoDate(end) };
  }

  return { from: undefined as string | undefined, to: undefined as string | undefined };
}

function aggregateMarks(logs: Array<{ student_id: string; marks_earned: number }>) {
  const map = new Map<string, { student_id: string; total_marks: number; activities_completed: number }>();

  for (const log of logs) {
    const row = map.get(log.student_id) ?? {
      student_id: log.student_id,
      total_marks: 0,
      activities_completed: 0,
    };

    row.total_marks += Number(log.marks_earned ?? 0);
    row.activities_completed += 1;
    map.set(log.student_id, row);
  }

  return Array.from(map.values()).sort((left, right) => right.total_marks - left.total_marks);
}

router.get('/leaderboard', async (req, res) => {
  const query = StudentLeaderboardQuerySchema.parse(req.query);
  const range = dateRange(query.period, query.date);

  try {
    let request = supabaseAdmin.from('activity_logs').select('student_id, marks_earned');

    if (range.from) {
      request = request.gte('log_date', range.from);
    }
    if (range.to) {
      request = request.lte('log_date', range.to);
    }

    const { data, error } = await request;

    if (error) {
      if (shouldUseLocalData(error)) {
        const logs = listDevActivityLogs({
          from_date: range.from,
          to_date: range.to,
        }).map((item) => ({
          student_id: item.student_id,
          marks_earned: item.marks_earned,
        }));

        const rows = aggregateMarks(logs)
          .map((item) => {
            const student = getDevStudent(item.student_id);
            if (!student) {
              return null;
            }

            if (query.batch_id && student.batch_id !== query.batch_id) {
              return null;
            }

            return {
              student_id: item.student_id,
              student_name: [student.father_name, student.mother_name]
                .filter((name) => name && name.trim().length > 0)
                .join(' / '),
              batch_id: student.batch_id,
              batch_name: student.batch_id ? getDevBatch(student.batch_id)?.name ?? null : null,
              total_marks: item.total_marks,
              activities_completed: item.activities_completed,
            };
          })
          .filter((item): item is NonNullable<typeof item> => item != null)
          .map((item, index) => ({ ...item, rank: index + 1 }));

        res.json({ period: query.period, range, data: rows });
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    const aggregated = aggregateMarks((data || []) as Array<{ student_id: string; marks_earned: number }>);
    const studentIds = aggregated.map((item) => item.student_id);

    const { data: students, error: studentsError } = await supabaseAdmin
      .from('students')
      .select('id, father_name, mother_name, batch_id')
      .in('id', studentIds);

    if (studentsError) {
      throw studentsError;
    }

    const studentMap = new Map((students || []).map((item) => [item.id, item]));

    const rows = aggregated
      .map((item) => {
        const student = studentMap.get(item.student_id);
        if (!student) {
          return null;
        }

        if (query.batch_id && student.batch_id !== query.batch_id) {
          return null;
        }

        const batch = student.batch_id ? getDevBatch(student.batch_id) : null;
        return {
          student_id: item.student_id,
          student_name: [student.father_name, student.mother_name]
            .filter((name) => name && name.trim().length > 0)
            .join(' / '),
          batch_id: student.batch_id,
          batch_name: batch?.name ?? null,
          total_marks: item.total_marks,
          activities_completed: item.activities_completed,
        };
      })
      .filter((item): item is NonNullable<typeof item> => item != null)
      .map((item, index) => ({ ...item, rank: index + 1 }));

    res.json({ period: query.period, range, data: rows });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch leaderboard';
    res.status(500).json({ error: msg });
  }
});

router.get('/progress/weekly', async (req, res) => {
  const query = StudentProgressQuerySchema.parse(req.query);
  const seed = query.week_start ? new Date(`${query.week_start}T00:00:00.000Z`) : new Date();
  const start = mondayOfWeek(seed);
  const end = new Date(start);
  end.setUTCDate(start.getUTCDate() + 6);
  const fromDate = toIsoDate(start);
  const toDate = toIsoDate(end);

  try {
    const { data, error } = await supabaseAdmin
      .from('activity_logs')
      .select('log_date, marks_earned')
      .eq('student_id', query.student_id)
      .gte('log_date', fromDate)
      .lte('log_date', toDate)
      .order('log_date', { ascending: true });

    if (error) {
      if (shouldUseLocalData(error)) {
        const logs = listDevActivityLogs({
          student_id: query.student_id,
          from_date: fromDate,
          to_date: toDate,
        });
        const total = logs.reduce((sum, item) => sum + item.marks_earned, 0);
        res.json({
          period: { type: 'weekly', week_start: fromDate, week_end: toDate },
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
      period: { type: 'weekly', week_start: fromDate, week_end: toDate },
      summary: { total_marks: total, total_activities: logs.length },
      data: logs,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch weekly progress';
    res.status(500).json({ error: msg });
  }
});

router.get('/progress/monthly', async (req, res) => {
  const query = StudentProgressQuerySchema.parse(req.query);
  const seed = query.month_start ? new Date(`${query.month_start}T00:00:00.000Z`) : new Date();
  const start = firstDayOfMonth(seed);
  const end = lastDayOfMonth(seed);
  const fromDate = toIsoDate(start);
  const toDate = toIsoDate(end);

  try {
    const { data, error } = await supabaseAdmin
      .from('activity_logs')
      .select('log_date, marks_earned')
      .eq('student_id', query.student_id)
      .gte('log_date', fromDate)
      .lte('log_date', toDate)
      .order('log_date', { ascending: true });

    if (error) {
      if (shouldUseLocalData(error)) {
        const logs = listDevActivityLogs({
          student_id: query.student_id,
          from_date: fromDate,
          to_date: toDate,
        });
        const total = logs.reduce((sum, item) => sum + item.marks_earned, 0);
        res.json({
          period: { type: 'monthly', month_start: fromDate, month_end: toDate },
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
      period: { type: 'monthly', month_start: fromDate, month_end: toDate },
      summary: { total_marks: total, total_activities: logs.length },
      data: logs,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch monthly progress';
    res.status(500).json({ error: msg });
  }
});

router.get('/badges', async (req, res) => {
  const query = StudentBadgesQuerySchema.parse(req.query);

  try {
    const { data, error } = await supabaseAdmin
      .from('student_badges')
      .select(
        'id, student_id, badge_id, earned_at, badges(id, name, name_ml, description, icon, bonus_points, status)'
      )
      .eq('student_id', query.student_id)
      .order('earned_at', { ascending: false });

    if (error) {
      if (shouldUseLocalData(error)) {
        res.json(listDevStudentBadges(query.student_id));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch student badges';
    res.status(500).json({ error: msg });
  }
});

router.get('/profile', async (req, res) => {
  const query = StudentProfileQuerySchema.parse(req.query);

  try {
    const { data, error } = await supabaseAdmin
      .from('students')
      .select(
        'id, parent_phone, father_name, mother_name, date_of_birth, gender, batch_id, class_id, address, enrollment_date, status, batches(id, name), classes(id, name, level)'
      )
      .eq('id', query.student_id)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const student = getDevStudent(query.student_id);
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
    const msg = err instanceof Error ? err.message : 'Failed to fetch student profile';
    res.status(500).json({ error: msg });
  }
});

router.get('/children', async (req, res) => {
  const query = StudentChildrenQuerySchema.parse(req.query);

  try {
    const { data, error } = await supabaseAdmin
      .from('students')
      .select('id, father_name, mother_name, parent_phone, batch_id, class_id, status')
      .eq('parent_phone', query.parent_phone)
      .order('enrollment_date', { ascending: false });

    if (error) {
      if (shouldUseLocalData(error)) {
        const fallback = listDevStudents({
          limit: 500,
          offset: 0,
        }).data.filter((item) => item.parent_phone === query.parent_phone);
        res.json(fallback);
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch linked children';
    res.status(500).json({ error: msg });
  }
});

router.get('/approval-history', async (req, res) => {
  const query = StudentApprovalHistoryQuerySchema.parse(req.query);

  try {
    const { data, error } = await supabaseAdmin
      .from('activity_logs')
      .select(
        'id, student_id, activity_id, rating_id, log_date, marks_earned, parent_approved, notes, activities(id, name, name_ml), activity_ratings(id, rating_name, rating_name_ml, marks)'
      )
      .eq('student_id', query.student_id)
      .order('log_date', { ascending: false })
      .limit(query.limit);

    if (error) {
      if (shouldUseLocalData(error)) {
        const logs = listDevActivityLogs({
          student_id: query.student_id,
        }).slice(0, query.limit);
        res.json(logs);
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch approval history';
    res.status(500).json({ error: msg });
  }
});

router.put('/profile', async (req, res) => {
  const query = StudentProfileQuerySchema.parse(req.query);

  try {
    const body = UpdateStudentProfileSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('students')
      .update(body)
      .eq('id', query.student_id)
      .select(
        'id, parent_phone, father_name, mother_name, date_of_birth, gender, batch_id, class_id, address, enrollment_date, status'
      )
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const updated = updateDevStudent(query.student_id, body);
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
    const msg = err instanceof Error ? err.message : 'Failed to update student profile';
    res.status(400).json({ error: msg });
  }
});

router.get('/index-student', (_req, res) => {
  const list = listDevStudents({ limit: 1, offset: 0, status: 'active' });
  res.json(list.data[0] ?? null);
});

export default router;
