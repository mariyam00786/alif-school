"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const cors_1 = __importDefault(require("cors"));
const express_1 = __importDefault(require("express"));
const config_1 = require("./config");
const integrations_1 = require("./integrations");
const batches_route_1 = __importDefault(require("./routes/batches.route"));
const categories_route_1 = __importDefault(require("./routes/categories.route"));
const metadata_route_1 = __importDefault(require("./routes/metadata.route"));
const activities_route_1 = __importDefault(require("./routes/activities.route"));
const activity_logs_route_1 = __importDefault(require("./routes/activity-logs.route"));
const classes_route_1 = __importDefault(require("./routes/classes.route"));
const students_route_1 = __importDefault(require("./routes/students.route"));
const teachers_route_1 = __importDefault(require("./routes/teachers.route"));
const ratings_route_1 = __importDefault(require("./routes/ratings.route"));
const auth_route_1 = __importDefault(require("./routes/auth.route"));
const reports_route_1 = __importDefault(require("./routes/reports.route"));
const remarks_route_1 = __importDefault(require("./routes/remarks.route"));
const badges_route_1 = __importDefault(require("./routes/badges.route"));
const notifications_route_1 = __importDefault(require("./routes/notifications.route"));
const student_route_1 = __importDefault(require("./routes/student.route"));
const teacher_app_route_1 = __importDefault(require("./routes/teacher-app.route"));
const auth_guard_1 = require("./middleware/auth-guard");
const app = (0, express_1.default)();
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.use((0, auth_guard_1.createAuthGuard)(config_1.config.enforceDevAuth));
app.use('/api/auth', auth_route_1.default);
app.use('/api/students', students_route_1.default);
app.use('/api/teachers', teachers_route_1.default);
app.use('/api/batches', batches_route_1.default);
app.use('/api/classes', classes_route_1.default);
app.use('/api/categories', categories_route_1.default);
app.use('/api/activities', activities_route_1.default);
app.use('/api/activity-logs', activity_logs_route_1.default);
app.use('/api/ratings', ratings_route_1.default);
app.use('/api/metadata', metadata_route_1.default);
app.use('/api/reports', reports_route_1.default);
app.use('/api/remarks', remarks_route_1.default);
app.use('/api/badges', badges_route_1.default);
app.use('/api/notifications', notifications_route_1.default);
app.use('/api/student', student_route_1.default);
app.use('/api/teacher', teacher_app_route_1.default);
app.get('/health', async (_req, res) => {
    const { error } = await integrations_1.supabaseAdmin.from('activity_categories').select('id').limit(1);
    res.json({
        status: error ? 'degraded' : 'ok',
        supabase: error ? error.message : 'connected',
        authOtpProvider: 'supabase_auth',
        pushProvider: 'firebase_fcm',
    });
});
app.post('/notifications/test', async (req, res) => {
    const token = req.body?.token;
    if (!token) {
        res.status(400).json({ error: 'token is required' });
        return;
    }
    const messaging = (0, integrations_1.initFirebaseMessaging)();
    if (!messaging) {
        res.status(501).json({ error: 'Firebase messaging not configured for local dev' });
        return;
    }
    await messaging.send({
        token,
        notification: {
            title: 'Alif Notification Test',
            body: 'Firebase Cloud Messaging is configured.',
        },
    });
    res.json({ ok: true });
});
function bootstrap() {
    try {
        (0, config_1.assertEnv)();
        app.listen(config_1.config.port, () => {
            console.log(`API listening on http://localhost:${config_1.config.port}`);
            console.log(`Health check: http://localhost:${config_1.config.port}/health`);
        });
    }
    catch (err) {
        console.error('Failed to start API:', err);
    }
}
bootstrap();
