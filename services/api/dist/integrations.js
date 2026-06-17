"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.supabaseAdmin = void 0;
exports.initFirebaseMessaging = initFirebaseMessaging;
const supabase_js_1 = require("@supabase/supabase-js");
const app_1 = require("firebase-admin/app");
const messaging_1 = require("firebase-admin/messaging");
const config_1 = require("./config");
exports.supabaseAdmin = (0, supabase_js_1.createClient)(config_1.config.supabaseUrl, config_1.config.supabaseServiceRoleKey, {
    auth: {
        persistSession: false,
        autoRefreshToken: false,
    },
});
function initFirebaseMessaging() {
    if ((0, app_1.getApps)().length === 0 && config_1.config.firebasePrivateKey) {
        try {
            (0, app_1.initializeApp)({
                credential: (0, app_1.cert)({
                    projectId: config_1.config.firebaseProjectId,
                    clientEmail: config_1.config.firebaseClientEmail,
                    privateKey: config_1.config.firebasePrivateKey,
                }),
            });
        }
        catch (err) {
            console.warn('Firebase initialization skipped for local dev:', err.message);
        }
    }
    try {
        return (0, messaging_1.getMessaging)();
    }
    catch {
        return null;
    }
}
