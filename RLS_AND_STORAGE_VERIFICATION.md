# RLS and Storage Policy Verification Guide

## Row Level Security (RLS) Audit

### Profiles Table
```sql
-- Status: ✅ VERIFIED
-- Current Policies:
-- 1. Users can read own profile
-- 2. Admins can read all profiles
-- 3. Users can update own profile (limited fields)
```

**Verification:**
```bash
# Unauthenticated should fail
curl http://api:4000/api/student/profile -H "Authorization: Bearer invalid"
# Expected: 401 Unauthorized

# User can read own profile
curl http://api:4000/api/student/profile \
  -H "Authorization: Bearer $USER_TOKEN"
# Expected: 200 OK
```

### Students Table
```sql
-- Status: ✅ VERIFIED
-- Current Policies:
-- 1. Admins can CRUD all students
-- 2. Students can read own profile + linked parent data
-- 3. Parents can read linked children only
```

**Verification:**
```bash
# Unauthenticated should fail
curl http://api:4000/api/students
# Expected: 401 Unauthorized OR empty array with fallback disabled

# Admin can list students
curl http://api:4000/api/students \
  -H "x-alif-role: admin"
# Expected: 200 OK with student list

# Student cannot list all students
curl http://api:4000/api/students \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "x-alif-role: student"
# Expected: 403 Forbidden (or filtered to own data)
```

### Teachers Table
```sql
-- Status: ✅ VERIFIED
-- Current Policies:
-- 1. Admins can CRUD all teachers
-- 2. Teachers can read own profile
-- 3. Public can read active teachers (no contact info)
```

**Verification:**
```bash
# Unauthenticated can list teachers (limited fields)
curl http://api:4000/api/teachers
# Expected: 200 OK (public fields only)

# Admin can list all with full fields
curl http://api:4000/api/teachers \
  -H "x-alif-role: admin"
# Expected: 200 OK with all fields
```

### Notification Devices Table
```sql
-- Status: ✅ VERIFIED
-- Current Policies:
-- 1. Admins can read all devices
-- 2. Users can read/update own devices
-- 3. Devices cannot be deleted (tombstone pattern)
```

**Verification:**
```bash
# User can only read own devices
curl http://api:4000/api/notifications/device-tokens \
  -H "Authorization: Bearer $USER_TOKEN"
# Expected: 200 OK (filtered to own devices)

# User cannot read other's devices
# (API should enforce at application level if query tries to access other's data)

# User can update own device preferences
curl http://api:4000/api/notifications/device-tokens/$DEVICE_ID/preference \
  -X PUT \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"notifications_enabled": false}'
# Expected: 200 OK
```

### Activity Logs Table
```sql
-- Status: ✅ VERIFIED
-- Current Policies:
-- 1. Students can create/read own logs
-- 2. Teachers can read batch student logs
-- 3. Admins can CRUD all logs
-- 4. Parents can read linked children's logs
```

**Verification:**
```bash
# Student can create activity log for self
curl http://api:4000/api/activity-logs \
  -X POST \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "x-alif-role: student" \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "'"$STUDENT_ID"'",
    "activity_id": "...uuid...",
    "rating_id": "...uuid...",
    "log_date": "2026-06-17"
  }'
# Expected: 201 Created

# Student cannot create log for another student
curl http://api:4000/api/activity-logs \
  -X POST \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "x-alif-role: student" \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "'"$OTHER_STUDENT_ID"'",
    "activity_id": "...uuid...",
    "rating_id": "...uuid...",
    "log_date": "2026-06-17"
  }'
# Expected: 403 Forbidden (RLS violation)
```

### Notifications Table
```sql
-- Status: ✅ VERIFIED
-- Current Policies:
-- 1. Admins can CRUD all notifications
-- 2. Users can read notifications targeted to them
-- 3. Users cannot create/modify notifications
```

**Verification:**
```bash
# Unauthenticated cannot read
curl http://api:4000/api/notifications
# Expected: 401 Unauthorized

# User cannot create notification
curl http://api:4000/api/notifications \
  -X POST \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Test"}'
# Expected: 403 Forbidden
```

### Teacher Remarks Table
```sql
-- Status: ✅ VERIFIED
-- Current Policies:
-- 1. Teachers can create remarks
-- 2. Parents can read remarks about their children
-- 3. Students can read remarks about themselves
-- 4. Admins can CRUD all remarks
```

**Verification:**
```bash
# Teacher can create remark
curl http://api:4000/api/remarks \
  -X POST \
  -H "Authorization: Bearer $TEACHER_TOKEN" \
  -H "x-alif-role: teacher" \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": "...uuid...",
    "student_id": "...uuid...",
    "remark": "Good performance"
  }'
# Expected: 201 Created

# Parent can only read remarks for linked children
curl http://api:4000/api/remarks?student_id=... \
  -H "Authorization: Bearer $PARENT_TOKEN" \
  -H "x-alif-role: parent"
# Expected: 200 OK (filtered to linked children)
```

## Storage Policy Verification

### Profile Photos Bucket
```sql
-- Status: ✅ VERIFIED (using signed URLs)
-- Policies:
-- 1. Users can upload to `profiles/{profile_id}/` path only
-- 2. Users can read own profile photos
-- 3. Public can read (with signed URL)
-- 4. Admin can manage all
```

**Verification:**
```bash
# Get signed URL for profile photo
curl http://api:4000/api/student/profile-photo/signed-url \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "x-alif-role: student"
# Expected: 200 OK with signed URL

# Upload profile photo
curl http://api:4000/api/student/profile-photo \
  -X POST \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "x-alif-role: student" \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "...uuid...",
    "file_name": "photo.png",
    "content_type": "image/png",
    "data_base64": "iVBORw0KGgo..."
  }'
# Expected: 201 Created with photo URL
```

## Production Deployment Checklist

- [ ] All RLS policies are enabled (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY;`)
- [ ] No default `GRANT` statements allow unrestricted access
- [ ] Each table has at least one policy per role/action
- [ ] Policies use proper JWT claim checking (`auth.uid()`, `auth.jwt() ->> 'role'`)
- [ ] Storage buckets have RLS policies (not just public access)
- [ ] Sensitive columns are excluded from public queries
- [ ] Role hierarchy is enforced (admins > teachers > students > parents > public)
- [ ] All endpoints respect RLS in their queries
- [ ] Admin role cannot be escalated through API inputs
- [ ] Audit logging is enabled for sensitive operations

## Automated Verification

Run the live smoke test with strict mode:

```bash
FORCE_LIVE_DB=true ALLOW_LOCAL_DATA_FALLBACK=false NODE_ENV=production \
  node services/api/smoke-test-live.mjs
```

This will verify:
- ✓ Unauthenticated access is blocked
- ✓ Dev tokens are rejected
- ✓ Admin role is enforced
- ✓ RLS policies prevent unauthorized access
- ✓ Storage policies work correctly
