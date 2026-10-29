"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const student_app_schema_1 = require("../schemas/student-app.schema");
const router = (0, express_1.Router)();
const PROFILE_PHOTOS_BUCKET = 'profile-photos';
let profilePhotoBucketEnsured = false;
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
function firstDayOfMonth(date) {
    return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1));
}
function lastDayOfMonth(date) {
    return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 0));
}
function dateRange(period, date) {
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
    return { from: undefined, to: undefined };
}
function aggregateMarks(logs) {
    const map = new Map();
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
function getDevUserFromRequest(authHeader) {
    const value = String(authHeader ?? '').trim();
    if (!value.toLowerCase().startsWith('bearer dev-')) {
        return null;
    }
    const id = value.substring('Bearer '.length).replace(/^dev-/, '');
    return (0, dev_data_1.getDevAuthUserById)(id);
}
async function getSupabaseUserFromRequest(authHeader) {
    const value = String(authHeader ?? '').trim();
    if (!value.toLowerCase().startsWith('bearer ')) {
        return null;
    }
    const token = value.substring('Bearer '.length).trim();
    if (!token || token.startsWith('dev-')) {
        return null;
    }
    const { data, error } = await integrations_1.supabaseAdmin.auth.getUser(token);
    if (error || !data.user) {
        return null;
    }
    return data.user;
}
function toStudentName(student) {
    return [student.father_name, student.mother_name]
        .filter((name) => Boolean(name && name.trim().length > 0))
        .join(' / ');
}
function toChildSummary(student) {
    return {
        id: student.id,
        student_name: toStudentName(student),
        batch_name: student.batch_id ? (0, dev_data_1.getDevBatch)(student.batch_id)?.name ?? 'Unassigned' : 'Unassigned',
    };
}
async function ensureProfilePhotoBucket() {
    if (profilePhotoBucketEnsured) {
        return;
    }
    const { data, error } = await integrations_1.supabaseAdmin.storage.listBuckets();
    if (error) {
        throw error;
    }
    const exists = (data || []).some((bucket) => bucket.id === PROFILE_PHOTOS_BUCKET);
    if (!exists) {
        const { error: createError } = await integrations_1.supabaseAdmin.storage.createBucket(PROFILE_PHOTOS_BUCKET, {
            public: false,
            fileSizeLimit: '5MB',
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
        });
        if (createError && !createError.message.toLowerCase().includes('already exists')) {
            throw createError;
        }
    }
    profilePhotoBucketEnsured = true;
}
async function toProfileResponse(student) {
    const photoPath = student?.profiles?.profile_photo ?? null;
    let photoUrl = null;
    if (photoPath) {
        const { data } = await integrations_1.supabaseAdmin.storage
            .from(PROFILE_PHOTOS_BUCKET)
            .createSignedUrl(photoPath, 60 * 60);
        photoUrl = data?.signedUrl ?? null;
    }
    return {
        id: student.id,
        father_name: student.father_name ?? 'Unknown',
        mother_name: student.mother_name ?? 'Unknown',
        date_of_birth: student.date_of_birth ?? '',
        gender: student.gender ?? '',
        address: student.address ?? '',
        batch_name: student.batches?.name ?? 'Unassigned',
        class_name: student.classes?.name ?? 'Unassigned',
        profile_photo_path: photoPath,
        profile_photo_url: photoUrl,
    };
}
router.get('/leaderboard', async (req, res) => {
    const query = student_app_schema_1.StudentLeaderboardQuerySchema.parse(req.query);
    const range = dateRange(query.period, query.date);
    try {
        let request = integrations_1.supabaseAdmin.from('activity_logs').select('student_id, marks_earned');
        if (range.from) {
            request = request.gte('log_date', range.from);
        }
        if (range.to) {
            request = request.lte('log_date', range.to);
        }
        const { data, error } = await request;
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const logs = (0, dev_data_1.listDevActivityLogs)({
                    from_date: range.from,
                    to_date: range.to,
                }).map((item) => ({
                    student_id: item.student_id,
                    marks_earned: item.marks_earned,
                }));
                const rows = aggregateMarks(logs)
                    .map((item) => {
                    const student = (0, dev_data_1.getDevStudent)(item.student_id);
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
                        batch_name: student.batch_id ? (0, dev_data_1.getDevBatch)(student.batch_id)?.name ?? null : null,
                        total_marks: item.total_marks,
                        activities_completed: item.activities_completed,
                    };
                })
                    .filter((item) => item != null)
                    .map((item, index) => ({ ...item, rank: index + 1 }));
                res.json({ period: query.period, range, data: rows });
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        const aggregated = aggregateMarks((data || []));
        const studentIds = aggregated.map((item) => item.student_id);
        const { data: students, error: studentsError } = await integrations_1.supabaseAdmin
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
            const batch = student.batch_id ? (0, dev_data_1.getDevBatch)(student.batch_id) : null;
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
            .filter((item) => item != null)
            .map((item, index) => ({ ...item, rank: index + 1 }));
        res.json({ period: query.period, range, data: rows });
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : 'Failed to fetch leaderboard';
        res.status(500).json({ error: msg });
    }
});
router.get('/progress/weekly', async (req, res) => {
    const query = student_app_schema_1.StudentProgressQuerySchema.parse(req.query);
    const seed = query.week_start ? new Date(`${query.week_start}T00:00:00.000Z`) : new Date();
    const start = mondayOfWeek(seed);
    const end = new Date(start);
    end.setUTCDate(start.getUTCDate() + 6);
    const fromDate = toIsoDate(start);
    const toDate = toIsoDate(end);
    try {
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activity_logs')
            .select('log_date, marks_earned')
            .eq('student_id', query.student_id)
            .gte('log_date', fromDate)
            .lte('log_date', toDate)
            .order('log_date', { ascending: true });
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const logs = (0, dev_data_1.listDevActivityLogs)({
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
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : 'Failed to fetch weekly progress';
        res.status(500).json({ error: msg });
    }
});
router.get('/progress/monthly', async (req, res) => {
    const query = student_app_schema_1.StudentProgressQuerySchema.parse(req.query);
    const seed = query.month_start ? new Date(`${query.month_start}T00:00:00.000Z`) : new Date();
    const start = firstDayOfMonth(seed);
    const end = lastDayOfMonth(seed);
    const fromDate = toIsoDate(start);
    const toDate = toIsoDate(end);
    try {
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activity_logs')
            .select('log_date, marks_earned')
            .eq('student_id', query.student_id)
            .gte('log_date', fromDate)
            .lte('log_date', toDate)
            .order('log_date', { ascending: true });
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const logs = (0, dev_data_1.listDevActivityLogs)({
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
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : 'Failed to fetch monthly progress';
        res.status(500).json({ error: msg });
    }
});
router.get('/badges', async (req, res) => {
    const query = student_app_schema_1.StudentBadgesQuerySchema.parse(req.query);
    try {
        const { data, error } = await integrations_1.supabaseAdmin
            .from('student_badges')
            .select('id, student_id, badge_id, earned_at, badges(id, name, name_ml, description, icon, bonus_points, status)')
            .eq('student_id', query.student_id)
            .order('earned_at', { ascending: false });
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.json((0, dev_data_1.listDevStudentBadges)(query.student_id).map((item) => ({
                    id: item.id,
                    badge_name: item.name ?? item.badge_name ?? 'Badge',
                    badge_icon: item.icon ?? item.badge_icon ?? null,
                    description: item.description ?? null,
                    awarded_at: item.earned_at ?? item.awarded_at ?? null,
                    earned: true,
                })));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json((data || []).map((item) => ({
            id: item.id,
            badge_name: item.badges?.name ?? 'Badge',
            badge_icon: item.badges?.icon ?? null,
            description: item.badges?.description ?? null,
            awarded_at: item.earned_at ?? null,
            earned: true,
        })));
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : 'Failed to fetch student badges';
        res.status(500).json({ error: msg });
    }
});
router.get('/profile', async (req, res) => {
    const query = student_app_schema_1.StudentProfileQuerySchema.parse(req.query);
    try {
        const { data, error } = await integrations_1.supabaseAdmin
            .from('students')
            .select('id, parent_phone, father_name, mother_name, date_of_birth, gender, batch_id, class_id, address, enrollment_date, status, batches(id, name), classes(id, name, level), profiles(profile_photo)')
            .eq('id', query.student_id)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const student = (0, dev_data_1.getDevStudent)(query.student_id);
                if (!student) {
                    res.status(404).json({ error: 'Student not found' });
                    return;
                }
                res.json({
                    id: student.id,
                    father_name: student.father_name,
                    mother_name: student.mother_name,
                    date_of_birth: student.date_of_birth,
                    gender: student.gender,
                    address: student.address ?? '',
                    batch_name: student.batch_name ?? 'Unassigned',
                    class_name: student.class_name ?? 'Unassigned',
                    profile_photo_path: (0, dev_data_1.getDevStudentProfilePhoto)(student.id),
                    profile_photo_url: (0, dev_data_1.getDevStudentProfilePhoto)(student.id),
                });
                return;
            }
            res.status(404).json({ error: 'Student not found' });
            return;
        }
        res.json(await toProfileResponse(data));
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : 'Failed to fetch student profile';
        res.status(500).json({ error: msg });
    }
});
router.get('/children', async (req, res) => {
    const query = student_app_schema_1.StudentChildrenQuerySchema.parse(req.query);
    try {
        const { data, error } = await integrations_1.supabaseAdmin
            .from('students')
            .select('id, father_name, mother_name, parent_phone, batch_id, class_id, status')
            .eq('parent_phone', query.parent_phone)
            .order('enrollment_date', { ascending: false });
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const fallback = (0, dev_data_1.listDevStudents)({
                    limit: 500,
                    offset: 0,
                }).data.filter((item) => item.parent_phone === query.parent_phone);
                res.json(fallback.map((item) => toChildSummary(item)));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json((data || []).map((item) => toChildSummary(item)));
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : 'Failed to fetch linked children';
        res.status(500).json({ error: msg });
    }
});
router.get('/approval-history', async (req, res) => {
    const query = student_app_schema_1.StudentApprovalHistoryQuerySchema.parse(req.query);
    try {
        const { data, error } = await integrations_1.supabaseAdmin
            .from('activity_logs')
            .select('id, student_id, activity_id, rating_id, log_date, marks_earned, parent_approved, notes, activities(id, name, name_ml), activity_ratings(id, rating_name, rating_name_ml, marks)')
            .eq('student_id', query.student_id)
            .order('log_date', { ascending: false })
            .limit(query.limit);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const logs = (0, dev_data_1.listDevActivityLogs)({
                    student_id: query.student_id,
                }).slice(0, query.limit);
                res.json(logs);
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.json(data || []);
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : 'Failed to fetch approval history';
        res.status(500).json({ error: msg });
    }
});
router.post('/profile-photo', async (req, res) => {
    const authUser = getDevUserFromRequest(req.header('authorization'));
    const supabaseUser = await getSupabaseUserFromRequest(req.header('authorization'));
    if (!authUser && !supabaseUser) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
    }
    try {
        const body = student_app_schema_1.UploadStudentProfilePhotoSchema.parse(req.body);
        const { data: student, error: studentError } = await integrations_1.supabaseAdmin
            .from('students')
            .select('id, profile_id')
            .eq('id', body.student_id)
            .single();
        if (studentError) {
            if ((0, dev_data_1.shouldUseLocalData)(studentError)) {
                const url = `data:${body.content_type};base64,${body.data_base64}`;
                (0, dev_data_1.setDevStudentProfilePhoto)(body.student_id, url);
                res.status(201).json({ profile_photo_path: url, profile_photo_url: url });
                return;
            }
            res.status(400).json({ error: studentError.message });
            return;
        }
        if (!student?.profile_id) {
            res.status(409).json({ error: 'Student is not linked to a profile record' });
            return;
        }
        if (supabaseUser) {
            const { data: profile, error: profileError } = await integrations_1.supabaseAdmin
                .from('profiles')
                .select('id, role')
                .eq('id', supabaseUser.id)
                .single();
            if (profileError || !profile) {
                res.status(403).json({ error: 'Authenticated profile not found' });
                return;
            }
            if (profile.role !== 'admin' && student.profile_id !== supabaseUser.id) {
                const { data: parentLink, error: parentLinkError } = await integrations_1.supabaseAdmin
                    .from('parent_students')
                    .select('id')
                    .eq('parent_profile_id', supabaseUser.id)
                    .eq('student_id', body.student_id)
                    .maybeSingle();
                if (parentLinkError || !parentLink) {
                    res.status(403).json({ error: 'Not allowed to update this student profile photo' });
                    return;
                }
            }
        }
        await ensureProfilePhotoBucket();
        const sanitizedFileName = body.file_name.replace(/[^a-zA-Z0-9._-]/g, '_');
        const objectPath = `${body.student_id}/${Date.now()}-${sanitizedFileName}`;
        const bytes = Buffer.from(body.data_base64, 'base64');
        const { error: uploadError } = await integrations_1.supabaseAdmin.storage
            .from(PROFILE_PHOTOS_BUCKET)
            .upload(objectPath, bytes, {
            contentType: body.content_type,
            upsert: true,
        });
        if (uploadError) {
            throw uploadError;
        }
        const { error: updateError } = await integrations_1.supabaseAdmin
            .from('profiles')
            .update({ profile_photo: objectPath })
            .eq('id', student.profile_id);
        if (updateError) {
            throw updateError;
        }
        const { data: signedUrlData } = await integrations_1.supabaseAdmin.storage
            .from(PROFILE_PHOTOS_BUCKET)
            .createSignedUrl(objectPath, 60 * 60);
        res.status(201).json({
            profile_photo_path: objectPath,
            profile_photo_url: signedUrlData?.signedUrl ?? null,
        });
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const body = student_app_schema_1.UploadStudentProfilePhotoSchema.parse(req.body);
            const url = `data:${body.content_type};base64,${body.data_base64}`;
            (0, dev_data_1.setDevStudentProfilePhoto)(body.student_id, url);
            res.status(201).json({ profile_photo_path: url, profile_photo_url: url });
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to upload profile photo';
        res.status(400).json({ error: msg });
    }
});
router.put('/profile', async (req, res) => {
    const query = student_app_schema_1.StudentProfileQuerySchema.parse(req.query);
    try {
        const body = student_app_schema_1.UpdateStudentProfileSchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
            .from('students')
            .update(body)
            .eq('id', query.student_id)
            .select('id, parent_phone, father_name, mother_name, date_of_birth, gender, batch_id, class_id, address, enrollment_date, status')
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const updated = (0, dev_data_1.updateDevStudent)(query.student_id, body);
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
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : 'Failed to update student profile';
        res.status(400).json({ error: msg });
    }
});
router.get('/index-student', (_req, res) => {
    const list = (0, dev_data_1.listDevStudents)({ limit: 1, offset: 0, status: 'active' });
    res.json(list.data[0] ?? null);
});
exports.default = router;
