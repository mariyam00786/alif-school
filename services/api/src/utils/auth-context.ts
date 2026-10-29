import { type Request } from 'express';

import { getDevAuthUserById } from '../dev-data';
import { supabaseAdmin } from '../integrations';

export type RequestUserContext = {
  id: string;
  role: string;
};

export function tokenFromAuthorizationHeader(value: string | undefined): string | null {
  const authHeader = String(value ?? '').trim();
  if (!authHeader.toLowerCase().startsWith('bearer ')) {
    return null;
  }

  const token = authHeader.substring('Bearer '.length).trim();
  return token.length > 0 ? token : null;
}

export async function resolveRequestUser(req: Request): Promise<RequestUserContext | null> {
  const token = tokenFromAuthorizationHeader(req.header('authorization'));
  if (!token) {
    return null;
  }

  if (token.startsWith('dev-')) {
    const user = getDevAuthUserById(token.replace(/^dev-/, ''));
    if (!user) {
      return null;
    }

    return {
      id: user.id,
      role: user.role,
    };
  }

  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data.user) {
    return null;
  }

  const { data: profile, error: profileError } = await supabaseAdmin
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
