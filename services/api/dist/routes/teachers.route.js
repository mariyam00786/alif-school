"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
const teacher_schema_1 = require("../schemas/teacher.schema");
const router = (0, express_1.Router)();
const TEACHER_SELECT = `
  id,
  profile_id,
  email,
  qualification,
  status,
  profiles!teachers_profile_id_fkey(full_name, phone),
  teacher_batches(batch_id, batches(id, name, name_ml))
`;
function mapTeacherRow(row) {
    return {
        id: row.id,
        profile_id: row.profile_id,
        full_name: row.profiles?.full_name ?? '',
        mobile_number: row.profiles?.phone ?? '',
        email: row.email,
        qualification: row.qualification,
        status: row.status ?? 'active',
        batch_ids: (row.teacher_batches ?? []).map((item) => item.batch_id),
        teacher_batches: row.teacher_batches ?? [],
    };
}
router.get('/', async (req, res) => {
    const query = teacher_schema_1.ListTeachersQuerySchema.parse(req.query);
    try {
        let request = integrations_1.supabaseAdmin.from('teachers').select(TEACHER_SELECT).order('created_at', { ascending: false });
        if (query.status) {
            request = request.eq('status', query.status);
        }
        const { data, error } = await request;
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.json((0, dev_data_1.listDevTeachers)(query));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        let mapped = (data ?? []).map(mapTeacherRow);
        if (query.search) {
            const search = query.search.toLowerCase();
            mapped = mapped.filter((teacher) => teacher.full_name.toLowerCase().includes(search) ||
                teacher.mobile_number.toLowerCase().includes(search) ||
                (teacher.email ?? '').toLowerCase().includes(search));
        }
        if (query.batch_id) {
            mapped = mapped.filter((teacher) => teacher.batch_ids.includes(query.batch_id));
        }
        res.json(mapped);
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            res.json((0, dev_data_1.listDevTeachers)(query));
            return;
        }
        res.status(500).json({ error: 'Failed to fetch teachers' });
    }
});
router.get('/:id', async (req, res) => {
    try {
        const { data, error } = await integrations_1.supabaseAdmin
            .from('teachers')
            .select(TEACHER_SELECT)
            .eq('id', req.params.id)
            .single();
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const teacher = (0, dev_data_1.getDevTeacher)(req.params.id);
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
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const teacher = (0, dev_data_1.getDevTeacher)(req.params.id);
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
        const body = teacher_schema_1.CreateTeacherSchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
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
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                res.status(201).json((0, dev_data_1.createDevTeacher)({
                    full_name: body.full_name,
                    mobile_number: body.mobile_number,
                    email: body.email,
                    qualification: body.qualification,
                    status: body.status ?? 'active',
                    batch_ids: body.batch_ids,
                }));
                return;
            }
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(201).json(mapTeacherRow(data));
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const body = teacher_schema_1.CreateTeacherSchema.parse(req.body);
            res.status(201).json((0, dev_data_1.createDevTeacher)({
                full_name: body.full_name,
                mobile_number: body.mobile_number,
                email: body.email,
                qualification: body.qualification,
                status: body.status ?? 'active',
                batch_ids: body.batch_ids,
            }));
            return;
        }
        const msg = err instanceof Error ? err.message : 'Failed to create teacher';
        res.status(400).json({ error: msg });
    }
});
router.put('/:id', async (req, res) => {
    try {
        const body = teacher_schema_1.UpdateTeacherSchema.parse(req.body);
        const { data, error } = await integrations_1.supabaseAdmin
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
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const updated = (0, dev_data_1.updateDevTeacher)(req.params.id, body);
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
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const body = teacher_schema_1.UpdateTeacherSchema.parse(req.body);
            const updated = (0, dev_data_1.updateDevTeacher)(req.params.id, body);
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
        const { error } = await integrations_1.supabaseAdmin.from('teachers').delete().eq('id', req.params.id);
        if (error) {
            if ((0, dev_data_1.shouldUseLocalData)(error)) {
                const deleted = (0, dev_data_1.deleteDevTeacher)(req.params.id);
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
    }
    catch (err) {
        if ((0, dev_data_1.shouldUseLocalData)(err)) {
            const deleted = (0, dev_data_1.deleteDevTeacher)(req.params.id);
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
exports.default = router;
