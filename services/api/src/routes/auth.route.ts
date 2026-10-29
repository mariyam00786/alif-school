import { Router } from 'express';

import { config } from '../config';
import { getDevAuthUserById, getDevAuthUserByPhone } from '../dev-data';
import { supabaseAdmin } from '../integrations';
import { SendOtpSchema, VerifyOtpSchema } from '../schemas/auth.schema';
import { tokenFromAuthorizationHeader } from '../utils/auth-context';

const router = Router();
const DEV_OTP = '123456';
// Disable dev auth in production or when explicitly forcing live DB
const isDevAuthEnabled = !config.forceLiveDb && process.env.NODE_ENV !== 'production';

router.post('/send-otp', (req, res) => {
  if (!isDevAuthEnabled) {
    res.status(403).json({ 
      error: 'OTP authentication is disabled in production mode',
      hint: 'Use real Supabase auth credentials'
    });
    return;
  }

  try {
    const body = SendOtpSchema.parse(req.body);
    const user = getDevAuthUserByPhone(body.phone);

    res.json({
      ok: true,
      message: 'OTP sent',
      dev_otp: DEV_OTP,
      user_exists: Boolean(user),
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Invalid request';
    res.status(400).json({ error: msg });
  }
});

router.post('/verify-otp', (req, res) => {
  if (!isDevAuthEnabled) {
    res.status(403).json({ 
      error: 'OTP authentication is disabled in production mode',
      hint: 'Use real Supabase auth credentials'
    });
    return;
  }

  try {
    const body = VerifyOtpSchema.parse(req.body);
    if (body.otp !== DEV_OTP) {
      res.status(401).json({ error: 'Invalid OTP' });
      return;
    }

    const user = getDevAuthUserByPhone(body.phone);
    if (!user) {
      res.status(404).json({ error: 'User not found for this phone' });
      return;
    }

    res.json({
      access_token: `dev-${user.id}`,
      token_type: 'bearer',
      user,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Invalid request';
    res.status(400).json({ error: msg });
  }
});

router.get('/me', (req, res) => {
  const token = tokenFromAuthorizationHeader(req.header('authorization'));
  if (!token) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  if (token.startsWith('dev-')) {
    if (!isDevAuthEnabled) {
      res.status(401).json({ 
        error: 'Dev auth tokens are not accepted in production mode',
        hint: 'Use Supabase auth tokens'
      });
      return;
    }

    const user = getDevAuthUserById(token.replace(/^dev-/, ''));
    if (!user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    res.json({ user });
    return;
  }

  supabaseAdmin.auth
    .getUser(token)
    .then(async ({ data, error }) => {
      if (error || !data.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { data: profile, error: profileError } = await supabaseAdmin
        .from('profiles')
        .select('id, phone, full_name, role')
        .eq('id', data.user.id)
        .maybeSingle();

      if (profileError || !profile) {
        res.status(401).json({ error: 'Profile not found for authenticated user' });
        return;
      }

      res.json({
        user: {
          id: profile.id,
          phone: profile.phone,
          full_name: profile.full_name,
          role: profile.role,
        },
      });
    })
    .catch(() => {
      res.status(401).json({ error: 'Unauthorized' });
    });
});

router.post('/logout', (_req, res) => {
  res.json({ ok: true });
});

export default router;
