# Production Hardening Guide

## Environment Configuration

To enable production mode with strict security settings, configure the following environment variables:

### API Server (.env)

```env
# Force live database (disable dev fallback)
FORCE_LIVE_DB=true

# Disable dev authentication paths
NODE_ENV=production

# Require Supabase connectivity on boot
REQUIRE_SUPABASE_ON_BOOT=true

# Disable local data fallback
ALLOW_LOCAL_DATA_FALLBACK=false

# Real Firebase credentials
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-service-account@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"

# Real Supabase credentials
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## Security Checks

### Dev Authentication Paths
- ❌ `/api/auth/send-otp` - **DISABLED** when `NODE_ENV=production`
- ❌ `/api/auth/verify-otp` - **DISABLED** when `NODE_ENV=production`
- ❌ `/api/auth/me` with `Bearer dev-*` tokens - **DISABLED** when `NODE_ENV=production`

All dev auth paths return `403 Forbidden` with message: "Dev auth is disabled in production mode"

### Database Fallback
- ❌ Local fallback is disabled when `ALLOW_LOCAL_DATA_FALLBACK=false`
- ❌ API will fail fast if Supabase is unavailable when `REQUIRE_SUPABASE_ON_BOOT=true`

### Real Database Connection
- ✅ `FORCE_LIVE_DB=true` ensures all database queries use live Supabase
- ✅ No mock data is served even if Supabase is temporarily unavailable

## Deployment Checklist

Before deploying to production:

- [ ] Set `NODE_ENV=production`
- [ ] Set `FORCE_LIVE_DB=true`
- [ ] Set `REQUIRE_SUPABASE_ON_BOOT=true`
- [ ] Set `ALLOW_LOCAL_DATA_FALLBACK=false`
- [ ] Provide real Firebase credentials
- [ ] Provide real Supabase credentials
- [ ] Run health check: `GET /health`
- [ ] Verify all routes return 200 (not 400 with fallback message)
- [ ] Test that dev auth endpoints return 403
- [ ] Verify RLS policies are enforced
- [ ] Test with real user tokens (Supabase)

## Verification Commands

### Check that dev auth is disabled:
```bash
curl -X POST http://api:4000/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "9999999999"}'
# Should return 403
```

### Check that database is live:
```bash
curl http://api:4000/health
# Should return {"status": "ok", "supabase": "connected"}
```

### Check that RLS is enforced:
```bash
curl http://api:4000/api/students \
  -H "Authorization: Bearer invalid-token"
# Should return 401 (unauthenticated)
```
