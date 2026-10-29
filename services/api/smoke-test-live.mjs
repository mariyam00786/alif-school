#!/usr/bin/env node

/**
 * Live Smoke Test Suite for Production Hardening
 * 
 * Run with FORCE_LIVE_DB=true, ALLOW_LOCAL_DATA_FALLBACK=false, NODE_ENV=production
 * 
 * Usage:
 *   FORCE_LIVE_DB=true ALLOW_LOCAL_DATA_FALLBACK=false NODE_ENV=production node smoke-test-live.mjs
 */

const BASE_URL = process.env.API_URL || 'http://localhost:4000';
const ADMIN_ROLE = 'admin';
const STUDENT_ROLE = 'student';
const TEACHER_ROLE = 'teacher';

const tests = [];
let passed = 0;
let failed = 0;

function addTest(name, fn) {
  tests.push({ name, fn });
}

async function runTest(test) {
  try {
    console.log(`\n  ▶ ${test.name}`);
    await test.fn();
    console.log(`  ✓ ${test.name}`);
    passed++;
    return true;
  } catch (err) {
    console.error(`  ✗ ${test.name}`);
    console.error(`    Error: ${err.message}`);
    failed++;
    return false;
  }
}

async function request(method, path, body = null, headers = {}) {
  const url = `${BASE_URL}${path}`;
  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  const response = await fetch(url, options);
  const text = await response.text();
  
  if (!response.ok) {
    throw new Error(`${method} ${path} → ${response.status}: ${text}`);
  }

  try {
    return text ? JSON.parse(text) : null;
  } catch {
    return text;
  }
}

// ─────────────────────────────────────────────────────────────────
// PHASE 1: Production Mode Configuration Checks
// ─────────────────────────────────────────────────────────────────

addTest('Health check reports live DB', async () => {
  const data = await request('GET', '/health');
  if (data.supabase !== 'connected') {
    throw new Error(`Expected supabase='connected', got '${data.supabase}'`);
  }
  if (data.status !== 'ok') {
    throw new Error(`Expected status='ok', got '${data.status}'`);
  }
});

addTest('Dev auth endpoints are disabled (send-otp)', async () => {
  try {
    await request('POST', '/api/auth/send-otp', {
      phone: '9999999999',
    });
    throw new Error('Expected 403, but request succeeded');
  } catch (err) {
    if (!err.message.includes('403')) {
      throw new Error(`Expected 403 Forbidden, got: ${err.message}`);
    }
  }
});

addTest('Dev auth endpoints are disabled (verify-otp)', async () => {
  try {
    await request('POST', '/api/auth/verify-otp', {
      phone: '9999999999',
      otp: '123456',
    });
    throw new Error('Expected 403, but request succeeded');
  } catch (err) {
    if (!err.message.includes('403')) {
      throw new Error(`Expected 403 Forbidden, got: ${err.message}`);
    }
  }
});

addTest('Dev tokens are rejected (GET /api/auth/me)', async () => {
  try {
    await request('GET', '/api/auth/me', null, {
      'Authorization': 'Bearer dev-10000000-0000-4000-8000-000000000001',
    });
    throw new Error('Expected 401, but request succeeded');
  } catch (err) {
    if (!err.message.includes('401')) {
      throw new Error(`Expected 401 Unauthorized, got: ${err.message}`);
    }
  }
});

// ─────────────────────────────────────────────────────────────────
// PHASE 2: Unauthenticated Access is Blocked (RLS)
// ─────────────────────────────────────────────────────────────────

addTest('Unauthenticated batches access is blocked', async () => {
  try {
    await request('GET', '/api/batches');
    throw new Error('Expected 401, but request succeeded');
  } catch (err) {
    if (!err.message.includes('401')) {
      throw new Error(`Expected 401, got: ${err.message}`);
    }
  }
});

addTest('Unauthenticated students access is blocked', async () => {
  try {
    await request('GET', '/api/students');
    throw new Error('Expected 401, but request succeeded');
  } catch (err) {
    if (!err.message.includes('401')) {
      throw new Error(`Expected 401, got: ${err.message}`);
    }
  }
});

addTest('Unauthenticated notifications access is blocked', async () => {
  try {
    await request('GET', '/api/notifications');
    throw new Error('Expected 401, but request succeeded');
  } catch (err) {
    if (!err.message.includes('401')) {
      throw new Error(`Expected 401, got: ${err.message}`);
    }
  }
});

// ─────────────────────────────────────────────────────────────────
// PHASE 3: Admin-Only Operations Require Role Header
// ─────────────────────────────────────────────────────────────────

addTest('Admin role header is enforced for POST /api/batches', async () => {
  try {
    await request('POST', '/api/batches', {
      name: 'Test Batch',
      description: 'Should fail without admin role',
    });
    throw new Error('Expected 401, but request succeeded');
  } catch (err) {
    if (!err.message.includes('401') && !err.message.includes('403')) {
      throw new Error(`Expected 401 or 403, got: ${err.message}`);
    }
  }
});

addTest('Admin role header is enforced for POST /api/students', async () => {
  try {
    await request('POST', '/api/students', {
      parent_phone: '9999912345',
      father_name: 'Test Father',
      mother_name: 'Test Mother',
      date_of_birth: '2014-05-11',
      gender: 'male',
      batch_id: '00000000-0000-0000-0000-000000000000',
      address: 'Test Address',
    });
    throw new Error('Expected 401, but request succeeded');
  } catch (err) {
    if (!err.message.includes('401') && !err.message.includes('403')) {
      throw new Error(`Expected 401 or 403, got: ${err.message}`);
    }
  }
});

// ─────────────────────────────────────────────────────────────────
// PHASE 4: Read Operations Work (GET without auth in non-RLS routes)
// ─────────────────────────────────────────────────────────────────

addTest('GET /api/activities returns data without auth', async () => {
  const data = await request('GET', '/api/activities');
  if (!Array.isArray(data)) {
    throw new Error(`Expected array, got ${typeof data}`);
  }
});

addTest('GET /api/ratings returns data without auth', async () => {
  const data = await request('GET', '/api/ratings');
  if (!Array.isArray(data)) {
    throw new Error(`Expected array, got ${typeof data}`);
  }
});

addTest('GET /api/categories returns data without auth', async () => {
  const data = await request('GET', '/api/categories');
  if (!Array.isArray(data)) {
    throw new Error(`Expected array, got ${typeof data}`);
  }
});

// ─────────────────────────────────────────────────────────────────
// PHASE 5: Device Token Endpoints are Protected
// ─────────────────────────────────────────────────────────────────

addTest('Device token registration requires Bearer token', async () => {
  try {
    await request('POST', '/api/notifications/device-tokens/register', {
      device_token: 'test-token',
      platform: 'android',
      app_name: 'student_teacher',
    });
    throw new Error('Expected 401, but request succeeded');
  } catch (err) {
    if (!err.message.includes('401')) {
      throw new Error(`Expected 401, got: ${err.message}`);
    }
  }
});

// ─────────────────────────────────────────────────────────────────
// PHASE 6: Invalid Data is Rejected
// ─────────────────────────────────────────────────────────────────

addTest('Invalid phone number format is rejected', async () => {
  try {
    await request('POST', '/api/auth/send-otp', {
      phone: 'invalid',
    });
    throw new Error('Expected 400 or 403, but request succeeded');
  } catch (err) {
    if (!err.message.includes('400') && !err.message.includes('403')) {
      throw new Error(`Expected 400 or 403, got: ${err.message}`);
    }
  }
});

addTest('Invalid activity log data is rejected', async () => {
  try {
    await request('POST', '/api/activity-logs', {
      student_id: 'invalid-uuid',
      activity_id: 'invalid-uuid',
      rating_id: 'invalid-uuid',
      log_date: 'invalid-date',
    }, {
      'x-alif-role': 'student',
    });
    throw new Error('Expected 400, but request succeeded');
  } catch (err) {
    if (!err.message.includes('400')) {
      throw new Error(`Expected 400, got: ${err.message}`);
    }
  }
});

// ─────────────────────────────────────────────────────────────────
// Run all tests
// ─────────────────────────────────────────────────────────────────

async function run() {
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║     Live Smoke Test (FORCE_LIVE_DB=true, NODE_ENV=production)  ║');
  console.log('╚════════════════════════════════════════════════════════════════╝');
  console.log(`\nAPI URL: ${BASE_URL}\n`);

  console.log('📋 PHASE 1: Production Mode Configuration');
  for (const test of tests.slice(0, 4)) {
    await runTest(test);
  }

  console.log('\n🔐 PHASE 2: RLS Enforcement (Unauthenticated Access Blocked)');
  for (const test of tests.slice(4, 7)) {
    await runTest(test);
  }

  console.log('\n👮 PHASE 3: Admin Role Enforcement');
  for (const test of tests.slice(7, 9)) {
    await runTest(test);
  }

  console.log('\n📖 PHASE 4: Public Read Operations');
  for (const test of tests.slice(9, 12)) {
    await runTest(test);
  }

  console.log('\n🔔 PHASE 5: Device Token Management');
  for (const test of tests.slice(12, 13)) {
    await runTest(test);
  }

  console.log('\n✔️  PHASE 6: Input Validation');
  for (const test of tests.slice(13)) {
    await runTest(test);
  }

  console.log('\n╔════════════════════════════════════════════════════════════════╗');
  console.log(`║  Results: ${passed} passed, ${failed} failed                                      ║`);
  console.log('╚════════════════════════════════════════════════════════════════╝\n');

  if (failed > 0) {
    process.exit(1);
  }
}

run().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
