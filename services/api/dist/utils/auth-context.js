"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.tokenFromAuthorizationHeader = tokenFromAuthorizationHeader;
exports.resolveRequestUser = resolveRequestUser;
const dev_data_1 = require("../dev-data");
const integrations_1 = require("../integrations");
function tokenFromAuthorizationHeader(value) {
    const authHeader = String(value ?? '').trim();
    if (!authHeader.toLowerCase().startsWith('bearer ')) {
        return null;
    }
    const token = authHeader.substring('Bearer '.length).trim();
    return token.length > 0 ? token : null;
}
async function resolveRequestUser(req) {
    const token = tokenFromAuthorizationHeader(req.header('authorization'));
    if (!token) {
        return null;
    }
    if (token.startsWith('dev-')) {
        const user = (0, dev_data_1.getDevAuthUserById)(token.replace(/^dev-/, ''));
        if (!user) {
            return null;
        }
        return {
            id: user.id,
            role: user.role,
        };
    }
    const { data, error } = await integrations_1.supabaseAdmin.auth.getUser(token);
    if (error || !data.user) {
        return null;
    }
    const { data: profile, error: profileError } = await integrations_1.supabaseAdmin
        .from('profiles')
        .select('id, role')
        .eq('id', data.user.id)
        .maybeSingle();
    if (profileError || !profile) {
        return null;
    }
    return {
        id: profile.id,
        role: profile.role,
    };
}
