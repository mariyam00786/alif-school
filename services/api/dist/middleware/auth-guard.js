"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createAuthGuard = createAuthGuard;
const WRITE_METHODS = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);
const ADMIN_ONLY_PREFIXES = [
    '/api/batches',
    '/api/categories',
    '/api/classes',
    '/api/activities',
    '/api/ratings',
    '/api/teachers',
    '/api/students',
    '/api/badges',
    '/api/notifications',
];
function roleFromHeader(req) {
    return String(req.header('x-alif-role') ?? '').trim().toLowerCase();
}
function createAuthGuard(enforce) {
    return (req, res, next) => {
        if (!enforce || !WRITE_METHODS.has(req.method.toUpperCase())) {
            next();
            return;
        }
        const role = roleFromHeader(req);
        if (!role) {
            res.status(401).json({
                error: 'Missing x-alif-role header. Supported roles: admin, teacher, student, parent.',
            });
            return;
        }
        const path = req.path;
        const isAdminOnly = ADMIN_ONLY_PREFIXES.some((prefix) => path.startsWith(prefix));
        if (isAdminOnly && role !== 'admin') {
            res.status(403).json({ error: 'Admin role required for this operation' });
            return;
        }
        if (path.startsWith('/api/activity-logs') && !['admin', 'student', 'parent'].includes(role)) {
            res.status(403).json({ error: 'Only admin/student/parent can write activity logs' });
            return;
        }
        if (path.startsWith('/api/remarks') && !['admin', 'teacher'].includes(role)) {
            res.status(403).json({ error: 'Only admin/teacher can write remarks' });
            return;
        }
        next();
    };
}
