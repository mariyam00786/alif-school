"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const report_schema_1 = require("../schemas/report.schema");
const router = (0, express_1.Router)();
function toIsoDate(value) {
    return value.toISOString().split('T')[0];
}
function mondayOfWeek(date) {
    const normalized = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
    const day = normalized.getUTCDay();
    const diff = day === 0 ? -6 : 1 - day;
    normalized.setUTCDate(normalized.getUTCDate() + diff);
    return normalized;
}
function addDays(date, days) {
    const output = new Date(date);
    output.setUTCDate(output.getUTCDate() + days);
    return output;
}
function firstDayOfMonth(date) {
    return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1));
}
function lastDayOfMonth(date) {
    return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 0));
}
function aggregate(logs) {
    const map = new Map();
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
async function loadStudentMeta(studentIds) {
    if (studentIds.length === 0) {
        return [];
    }
    const { data, error } = await integrations_1.supabaseAdmin
        .from('students')
        .select('id, father_name, mother_name, parent_phone, batch_id')
        .in('id', studentIds);
    if (error) {
        throw error;
    }
    return (data || []);
}
function buildReportRows(aggregated, students, batchId) {
    const studentMap = new Map(students.map((student) => [student.id, student]));
    const rows = aggregated
        .map((row) => {
        const student = studentMap.get(row.student_id);
        if (!student) {
            return null;
        }
        const batch = student.batch_id ? (0, dev_data_1.getDevBatch)(student.batch_id) : null;
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
        .filter((item) => item != null);
    if (!batchId) {
        return rows;
    }
    return rows.filter((row) => row.batch_id === batchId);
}
function buildLocalStudentMeta(studentIds) {
    return studentIds
        .map((studentId) => (0, dev_data_1.getDevStudent)(studentId))
        .filter((student) => student != null)
        .map((student) => ({
        id: student.id,
        father_name: student.father_name,
        mother_name: student.mother_name,
        parent_phone: student.parent_phone,
        batch_id: student.batch_id ?? null,
    }));
}
router.get('/daily', async (req, res) => {
    const query = report_schema_1.DailyReportQuerySchema.parse(req.query);
    const date = query.date ?? toIsoDate(new Date());
    try {
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activity_logs')
            .select('student_id, marks_earned')
            .eq('log_date', date);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const logs = (0, dev_data_1.listDevActivityLogs)({ log_date: date }).map((item) => ({
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
        const aggregated = aggregate((data || []));
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
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const logs = (0, dev_data_1.listDevActivityLogs)({ log_date: date }).map((item) => ({
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
    const query = report_schema_1.WeeklyReportQuerySchema.parse(req.query);
    const weekStartDate = query.week_start
        ? mondayOfWeek(new Date(`${query.week_start}T00:00:00.000Z`))
        : mondayOfWeek(new Date());
    const fromDate = toIsoDate(weekStartDate);
    const toDate = toIsoDate(addDays(weekStartDate, 6));
    try {
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activity_logs')
            .select('student_id, marks_earned')
            .gte('log_date', fromDate)
            .lte('log_date', toDate);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const logs = (0, dev_data_1.listDevActivityLogs)({
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
        const aggregated = aggregate((data || []));
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
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const logs = (0, dev_data_1.listDevActivityLogs)({
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
    const query = report_schema_1.MonthlyReportQuerySchema.parse(req.query);
    const monthStartDate = query.month_start
        ? firstDayOfMonth(new Date(`${query.month_start}T00:00:00.000Z`))
        : firstDayOfMonth(new Date());
    const fromDate = toIsoDate(monthStartDate);
    const toDate = toIsoDate(lastDayOfMonth(monthStartDate));
    try {
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activity_logs')
            .select('student_id, marks_earned')
            .gte('log_date', fromDate)
            .lte('log_date', toDate);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const logs = (0, dev_data_1.listDevActivityLogs)({
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
        const aggregated = aggregate((data || []));
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
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const logs = (0, dev_data_1.listDevActivityLogs)({
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
exports.default = router;
