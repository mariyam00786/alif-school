import { Router } from 'express';

import {
  getDevBatch,
  getDevStudent,
  listDevActivityLogs,
  shouldUseLocalData,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  DailyReportQuerySchema,
  MonthlyReportQuerySchema,
  WeeklyReportQuerySchema,
} from '../schemas/report.schema';

const router = Router();

type StudentMeta = {
  id: string;
  father_name: string | null;
  mother_name: string | null;
  parent_phone: string | null;
  batch_id: string | null;
};

type AggregationRow = {
  student_id: string;
  total_marks: number;
  activities_completed: number;
};

type ReportSummary = {
  students: number;
  total_marks: number;
  total_activities: number;
};

type ReportResult = {
  summary: ReportSummary;
  data: Array<{
    student_id: string;
    student_name: string;
    parent_phone: string | null;
    batch_id: string | null;
    batch_name: string | null;
    total_marks: number;
    activities_completed: number;
  }>;
};

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

function addDays(date: Date, days: number) {
  const output = new Date(date);
  output.setUTCDate(output.getUTCDate() + days);
  return output;
}

function firstDayOfMonth(date: Date) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1));
}

function lastDayOfMonth(date: Date) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 0));
}

function aggregate(logs: Array<{ student_id: string; marks_earned: number }>) {
  const map = new Map<string, AggregationRow>();
  for (const log of logs) {
    const current = map.get(log.student_id) ?? {
      student_id: log.student_id,
      total_marks: 0,
      activities_completed: 0,
    };

    current.total_marks += Number(log.marks_earned ?? 0);
    current.activities_completed += 1;
    map.set(log.student_id, current);
  }

  return Array.from(map.values()).sort((left, right) => right.total_marks - left.total_marks);
}

async function loadStudentMeta(studentIds: string[]) {
  if (studentIds.length === 0) {
    return [] as StudentMeta[];
  }

  const { data, error } = await supabaseAdmin
    .from('students')
    .select('id, father_name, mother_name, parent_phone, batch_id')
    .in('id', studentIds);

  if (error) {
    throw error;
  }

  return (data || []) as StudentMeta[];
}

function buildReportRows(
  aggregated: AggregationRow[],
  students: StudentMeta[],
  batchId?: string
) {
  const studentMap = new Map(students.map((student) => [student.id, student]));

  const rows = aggregated
    .map((row) => {
      const student = studentMap.get(row.student_id);
      if (!student) {
        return null;
      }

      const batch = student.batch_id ? getDevBatch(student.batch_id) : null;
      return {
        student_id: row.student_id,
        student_name: [student.father_name, student.mother_name]
          .filter((item) => item && item.trim().length > 0)
          .join(' / '),
        parent_phone: student.parent_phone,
        batch_id: student.batch_id,
        batch_name: batch?.name ?? null,
        total_marks: row.total_marks,
        activities_completed: row.activities_completed,
      };
    })
    .filter((item): item is NonNullable<typeof item> => item != null);

  if (!batchId) {
    return rows;
  }

  return rows.filter((row) => row.batch_id === batchId);
}

function buildLocalStudentMeta(studentIds: string[]) {
  return studentIds
    .map((studentId) => getDevStudent(studentId))
    .filter((student): student is NonNullable<typeof student> => student != null)
    .map((student) => ({
      id: student.id,
      father_name: student.father_name,
      mother_name: student.mother_name,
      parent_phone: student.parent_phone,
      batch_id: student.batch_id ?? null,
    }));
}

async function buildRangeReport(fromDate: string, toDate: string, batchId?: string): Promise<ReportResult> {
  const fetchSupabaseRows = async () => {
    const { data, error } = await supabaseAdmin
      .from('activity_logs')
      .select('student_id, marks_earned')
      .gte('log_date', fromDate)
      .lte('log_date', toDate);

    if (error) {
      throw error;
    }

    return (data || []) as Array<{ student_id: string; marks_earned: number }>;
  };

  const buildFromLogs = async (logs: Array<{ student_id: string; marks_earned: number }>, isLocal: boolean) => {
    const aggregated = aggregate(logs);
    const students = isLocal
      ? buildLocalStudentMeta(aggregated.map((row) => row.student_id))
      : await loadStudentMeta(aggregated.map((row) => row.student_id));
    const rows = buildReportRows(aggregated, students, batchId);

    return {
      summary: {
        students: rows.length,
        total_marks: rows.reduce((sum, row) => sum + row.total_marks, 0),
        total_activities: rows.reduce((sum, row) => sum + row.activities_completed, 0),
      },
      data: rows,
    };
  };

  try {
    const logs = await fetchSupabaseRows();
    return await buildFromLogs(logs, false);
  } catch (err) {
    if (!shouldUseLocalData(err)) {
      throw err;
    }

    const localLogs = listDevActivityLogs({
      from_date: fromDate,
      to_date: toDate,
    }).map((item) => ({
      student_id: item.student_id,
      marks_earned: item.marks_earned,
    }));

    return await buildFromLogs(localLogs, true);
  }
}

function csvEscape(value: string | number | null | undefined) {
  if (value == null) {
    return '';
  }

  const text = String(value);
  if (/[",\n]/.test(text)) {
    return '"' + text.replace(/"/g, '""') + '"';
  }

  return text;
}

function toCsv(result: ReportResult) {
  const lines: string[] = [];
  lines.push('students,total_marks,total_activities');
  lines.push(
    [result.summary.students, result.summary.total_marks, result.summary.total_activities]
      .map((item) => csvEscape(item))
      .join(',')
  );
  lines.push('');
  lines.push('student_id,student_name,parent_phone,batch_id,batch_name,total_marks,activities_completed');

  for (const row of result.data) {
    lines.push(
      [
        row.student_id,
        row.student_name,
        row.parent_phone,
        row.batch_id,
        row.batch_name,
        row.total_marks,
        row.activities_completed,
      ]
        .map((item) => csvEscape(item))
        .join(',')
    );
  }

  return lines.join('\n');
}

function toExcelTsv(result: ReportResult) {
  const lines: string[] = [];
  lines.push('students\ttotal_marks\ttotal_activities');
  lines.push(`${result.summary.students}\t${result.summary.total_marks}\t${result.summary.total_activities}`);
  lines.push('');
  lines.push('student_id\tstudent_name\tparent_phone\tbatch_id\tbatch_name\ttotal_marks\tactivities_completed');

  for (const row of result.data) {
    lines.push(
      [
        row.student_id,
        row.student_name,
        row.parent_phone ?? '',
        row.batch_id ?? '',
        row.batch_name ?? '',
        row.total_marks,
        row.activities_completed,
      ]
        .map((value) => String(value).replace(/\t/g, ' '))
        .join('\t')
    );
  }

  return lines.join('\n');
}

function toPrintHtml(result: ReportResult, title: string, subtitle: string) {
  const rows = result.data
    .map(
      (row) => `
      <tr>
        <td>${row.student_name}</td>
        <td>${row.parent_phone ?? '-'}</td>
        <td>${row.batch_name ?? '-'}</td>
        <td style="text-align:right">${row.total_marks}</td>
        <td style="text-align:right">${row.activities_completed}</td>
      </tr>`
    )
    .join('');

  return `<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>${title}</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 24px; color: #111827; }
      h1 { margin: 0 0 8px; font-size: 22px; }
      .meta { margin: 0 0 16px; color: #4b5563; }
      .summary { display: flex; gap: 12px; margin-bottom: 16px; }
      .chip { border: 1px solid #d1d5db; border-radius: 8px; padding: 8px 10px; font-size: 13px; }
      table { width: 100%; border-collapse: collapse; }
      th, td { border: 1px solid #e5e7eb; padding: 8px; font-size: 13px; }
      th { text-align: left; background: #f9fafb; }
    </style>
  </head>
  <body>
    <h1>${title}</h1>
    <p class="meta">${subtitle}</p>
    <div class="summary">
      <div class="chip">Students: ${result.summary.students}</div>
      <div class="chip">Total Marks: ${result.summary.total_marks}</div>
      <div class="chip">Activities: ${result.summary.total_activities}</div>
    </div>
    <table>
      <thead>
        <tr>
          <th>Student</th>
          <th>Parent Phone</th>
          <th>Batch</th>
          <th>Total Marks</th>
          <th>Activities</th>
        </tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>
  </body>
</html>`;
}

router.get('/daily', async (req, res) => {
  const query = DailyReportQuerySchema.parse(req.query);
  const date = query.date ?? toIsoDate(new Date());

  try {
    const { data, error } = await supabaseAdmin
      .from('activity_logs')
      .select('student_id, marks_earned')
      .eq('log_date', date);

    if (error) {
      if (shouldUseLocalData(error)) {
        const logs = listDevActivityLogs({ log_date: date }).map((item) => ({
          student_id: item.student_id,
          marks_earned: item.marks_earned,
        }));
        const aggregated = aggregate(logs);
        const students = buildLocalStudentMeta(aggregated.map((row) => row.student_id));
        const rows = buildReportRows(aggregated, students, query.batch_id);

        res.json({
          period: { type: 'daily', date },
          summary: {
            students: rows.length,
            total_marks: rows.reduce((sum, row) => sum + row.total_marks, 0),
            total_activities: rows.reduce((sum, row) => sum + row.activities_completed, 0),
          },
          data: rows,
        });
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    const aggregated = aggregate((data || []) as Array<{ student_id: string; marks_earned: number }>);
    const students = await loadStudentMeta(aggregated.map((row) => row.student_id));
    const rows = buildReportRows(aggregated, students, query.batch_id);

    res.json({
      period: { type: 'daily', date },
      summary: {
        students: rows.length,
        total_marks: rows.reduce((sum, row) => sum + row.total_marks, 0),
        total_activities: rows.reduce((sum, row) => sum + row.activities_completed, 0),
      },
      data: rows,
    });
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const logs = listDevActivityLogs({ log_date: date }).map((item) => ({
        student_id: item.student_id,
        marks_earned: item.marks_earned,
      }));
      const aggregated = aggregate(logs);
      const students = buildLocalStudentMeta(aggregated.map((row) => row.student_id));
      const rows = buildReportRows(aggregated, students, query.batch_id);

      res.json({
        period: { type: 'daily', date },
        summary: {
          students: rows.length,
          total_marks: rows.reduce((sum, row) => sum + row.total_marks, 0),
          total_activities: rows.reduce((sum, row) => sum + row.activities_completed, 0),
        },
        data: rows,
      });
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to fetch daily report';
    res.status(500).json({ error: msg });
  }
});

router.get('/weekly', async (req, res) => {
  const query = WeeklyReportQuerySchema.parse(req.query);
  const weekStartDate = query.week_start
    ? mondayOfWeek(new Date(`${query.week_start}T00:00:00.000Z`))
    : mondayOfWeek(new Date());
  const fromDate = toIsoDate(weekStartDate);
  const toDate = toIsoDate(addDays(weekStartDate, 6));

  try {
    const { data, error } = await supabaseAdmin
      .from('activity_logs')
      .select('student_id, marks_earned')
      .gte('log_date', fromDate)
      .lte('log_date', toDate);

    if (error) {
      if (shouldUseLocalData(error)) {
        const logs = listDevActivityLogs({
          from_date: fromDate,
          to_date: toDate,
        }).map((item) => ({
          student_id: item.student_id,
          marks_earned: item.marks_earned,
        }));
        const aggregated = aggregate(logs);
        const students = buildLocalStudentMeta(aggregated.map((row) => row.student_id));
        const rows = buildReportRows(aggregated, students, query.batch_id);

        res.json({
          period: { type: 'weekly', week_start: fromDate, week_end: toDate },
          summary: {
            students: rows.length,
            total_marks: rows.reduce((sum, row) => sum + row.total_marks, 0),
            total_activities: rows.reduce((sum, row) => sum + row.activities_completed, 0),
          },
          data: rows,
        });
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    const aggregated = aggregate((data || []) as Array<{ student_id: string; marks_earned: number }>);
    const students = await loadStudentMeta(aggregated.map((row) => row.student_id));
    const rows = buildReportRows(aggregated, students, query.batch_id);

    res.json({
      period: { type: 'weekly', week_start: fromDate, week_end: toDate },
      summary: {
        students: rows.length,
        total_marks: rows.reduce((sum, row) => sum + row.total_marks, 0),
        total_activities: rows.reduce((sum, row) => sum + row.activities_completed, 0),
      },
      data: rows,
    });
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const logs = listDevActivityLogs({
        from_date: fromDate,
        to_date: toDate,
      }).map((item) => ({
        student_id: item.student_id,
        marks_earned: item.marks_earned,
      }));
      const aggregated = aggregate(logs);
      const students = buildLocalStudentMeta(aggregated.map((row) => row.student_id));
      const rows = buildReportRows(aggregated, students, query.batch_id);

      res.json({
        period: { type: 'weekly', week_start: fromDate, week_end: toDate },
        summary: {
          students: rows.length,
          total_marks: rows.reduce((sum, row) => sum + row.total_marks, 0),
          total_activities: rows.reduce((sum, row) => sum + row.activities_completed, 0),
        },
        data: rows,
      });
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to fetch weekly report';
    res.status(500).json({ error: msg });
  }
});

router.get('/monthly', async (req, res) => {
  const query = MonthlyReportQuerySchema.parse(req.query);
  const monthStartDate = query.month_start
    ? firstDayOfMonth(new Date(`${query.month_start}T00:00:00.000Z`))
    : firstDayOfMonth(new Date());
  const fromDate = toIsoDate(monthStartDate);
  const toDate = toIsoDate(lastDayOfMonth(monthStartDate));

  try {
    const { data, error } = await supabaseAdmin
      .from('activity_logs')
      .select('student_id, marks_earned')
      .gte('log_date', fromDate)
      .lte('log_date', toDate);

    if (error) {
      if (shouldUseLocalData(error)) {
        const logs = listDevActivityLogs({
          from_date: fromDate,
          to_date: toDate,
        }).map((item) => ({
          student_id: item.student_id,
          marks_earned: item.marks_earned,
        }));
        const aggregated = aggregate(logs);
        const students = buildLocalStudentMeta(aggregated.map((row) => row.student_id));
        const rows = buildReportRows(aggregated, students, query.batch_id);

        res.json({
          period: { type: 'monthly', month_start: fromDate, month_end: toDate },
          summary: {
            students: rows.length,
            total_marks: rows.reduce((sum, row) => sum + row.total_marks, 0),
            total_activities: rows.reduce((sum, row) => sum + row.activities_completed, 0),
          },
          data: rows,
        });
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    const aggregated = aggregate((data || []) as Array<{ student_id: string; marks_earned: number }>);
    const students = await loadStudentMeta(aggregated.map((row) => row.student_id));
    const rows = buildReportRows(aggregated, students, query.batch_id);

    res.json({
      period: { type: 'monthly', month_start: fromDate, month_end: toDate },
      summary: {
        students: rows.length,
        total_marks: rows.reduce((sum, row) => sum + row.total_marks, 0),
        total_activities: rows.reduce((sum, row) => sum + row.activities_completed, 0),
      },
      data: rows,
    });
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const logs = listDevActivityLogs({
        from_date: fromDate,
        to_date: toDate,
      }).map((item) => ({
        student_id: item.student_id,
        marks_earned: item.marks_earned,
      }));
      const aggregated = aggregate(logs);
      const students = buildLocalStudentMeta(aggregated.map((row) => row.student_id));
      const rows = buildReportRows(aggregated, students, query.batch_id);

      res.json({
        period: { type: 'monthly', month_start: fromDate, month_end: toDate },
        summary: {
          students: rows.length,
          total_marks: rows.reduce((sum, row) => sum + row.total_marks, 0),
          total_activities: rows.reduce((sum, row) => sum + row.activities_completed, 0),
        },
        data: rows,
      });
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to fetch monthly report';
    res.status(500).json({ error: msg });
  }
});

router.get('/daily/export', async (req, res) => {
  const query = DailyReportQuerySchema.parse(req.query);
  const date = query.date ?? toIsoDate(new Date());

  try {
    const result = await buildRangeReport(date, date, query.batch_id);
    const csv = toCsv(result);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="daily-report-${date}.csv"`);
    res.status(200).send(csv);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to export daily report';
    res.status(500).json({ error: msg });
  }
});

router.get('/daily/export/excel', async (req, res) => {
  const query = DailyReportQuerySchema.parse(req.query);
  const date = query.date ?? toIsoDate(new Date());

  try {
    const result = await buildRangeReport(date, date, query.batch_id);
    const tsv = toExcelTsv(result);
    res.setHeader('Content-Type', 'application/vnd.ms-excel; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="daily-report-${date}.xls"`);
    res.status(200).send(tsv);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to export daily Excel report';
    res.status(500).json({ error: msg });
  }
});

router.get('/daily/print', async (req, res) => {
  const query = DailyReportQuerySchema.parse(req.query);
  const date = query.date ?? toIsoDate(new Date());

  try {
    const result = await buildRangeReport(date, date, query.batch_id);
    const html = toPrintHtml(result, 'Daily Report', `Date: ${date}`);
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(html);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to render daily print report';
    res.status(500).json({ error: msg });
  }
});

router.get('/weekly/export', async (req, res) => {
  const query = WeeklyReportQuerySchema.parse(req.query);
  const weekStartDate = query.week_start
    ? mondayOfWeek(new Date(`${query.week_start}T00:00:00.000Z`))
    : mondayOfWeek(new Date());
  const fromDate = toIsoDate(weekStartDate);
  const toDate = toIsoDate(addDays(weekStartDate, 6));

  try {
    const result = await buildRangeReport(fromDate, toDate, query.batch_id);
    const csv = toCsv(result);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="weekly-report-${fromDate}-to-${toDate}.csv"`);
    res.status(200).send(csv);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to export weekly report';
    res.status(500).json({ error: msg });
  }
});

router.get('/weekly/export/excel', async (req, res) => {
  const query = WeeklyReportQuerySchema.parse(req.query);
  const weekStartDate = query.week_start
    ? mondayOfWeek(new Date(`${query.week_start}T00:00:00.000Z`))
    : mondayOfWeek(new Date());
  const fromDate = toIsoDate(weekStartDate);
  const toDate = toIsoDate(addDays(weekStartDate, 6));

  try {
    const result = await buildRangeReport(fromDate, toDate, query.batch_id);
    const tsv = toExcelTsv(result);
    res.setHeader('Content-Type', 'application/vnd.ms-excel; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="weekly-report-${fromDate}-to-${toDate}.xls"`);
    res.status(200).send(tsv);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to export weekly Excel report';
    res.status(500).json({ error: msg });
  }
});

router.get('/weekly/print', async (req, res) => {
  const query = WeeklyReportQuerySchema.parse(req.query);
  const weekStartDate = query.week_start
    ? mondayOfWeek(new Date(`${query.week_start}T00:00:00.000Z`))
    : mondayOfWeek(new Date());
  const fromDate = toIsoDate(weekStartDate);
  const toDate = toIsoDate(addDays(weekStartDate, 6));

  try {
    const result = await buildRangeReport(fromDate, toDate, query.batch_id);
    const html = toPrintHtml(result, 'Weekly Report', `Week: ${fromDate} to ${toDate}`);
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(html);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to render weekly print report';
    res.status(500).json({ error: msg });
  }
});

router.get('/monthly/export', async (req, res) => {
  const query = MonthlyReportQuerySchema.parse(req.query);
  const monthStartDate = query.month_start
    ? firstDayOfMonth(new Date(`${query.month_start}T00:00:00.000Z`))
    : firstDayOfMonth(new Date());
  const fromDate = toIsoDate(monthStartDate);
  const toDate = toIsoDate(lastDayOfMonth(monthStartDate));

  try {
    const result = await buildRangeReport(fromDate, toDate, query.batch_id);
    const csv = toCsv(result);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="monthly-report-${fromDate}-to-${toDate}.csv"`);
    res.status(200).send(csv);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to export monthly report';
    res.status(500).json({ error: msg });
  }
});

router.get('/monthly/export/excel', async (req, res) => {
  const query = MonthlyReportQuerySchema.parse(req.query);
  const monthStartDate = query.month_start
    ? firstDayOfMonth(new Date(`${query.month_start}T00:00:00.000Z`))
    : firstDayOfMonth(new Date());
  const fromDate = toIsoDate(monthStartDate);
  const toDate = toIsoDate(lastDayOfMonth(monthStartDate));

  try {
    const result = await buildRangeReport(fromDate, toDate, query.batch_id);
    const tsv = toExcelTsv(result);
    res.setHeader('Content-Type', 'application/vnd.ms-excel; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="monthly-report-${fromDate}-to-${toDate}.xls"`);
    res.status(200).send(tsv);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to export monthly Excel report';
    res.status(500).json({ error: msg });
  }
});

router.get('/monthly/print', async (req, res) => {
  const query = MonthlyReportQuerySchema.parse(req.query);
  const monthStartDate = query.month_start
    ? firstDayOfMonth(new Date(`${query.month_start}T00:00:00.000Z`))
    : firstDayOfMonth(new Date());
  const fromDate = toIsoDate(monthStartDate);
  const toDate = toIsoDate(lastDayOfMonth(monthStartDate));

  try {
    const result = await buildRangeReport(fromDate, toDate, query.batch_id);
    const html = toPrintHtml(result, 'Monthly Report', `Month: ${fromDate} to ${toDate}`);
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(html);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to render monthly print report';
    res.status(500).json({ error: msg });
  }
});

export default router;
