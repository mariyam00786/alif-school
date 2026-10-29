import { initFirebaseMessaging, supabaseAdmin } from '../integrations';

type NotificationTargetType = 'all' | 'batch' | 'class' | 'student';

type SendPushInput = {
  notificationId: string;
  title: string;
  body?: string | null;
  targetType: NotificationTargetType;
  targetId?: string | null;
};

export type PushDeliveryResult = {
  status:
    | 'scheduled'
    | 'sent'
    | 'no_recipients'
    | 'provider_unavailable'
    | 'failed';
  tokens_targeted: number;
  sent: number;
  failed: number;
  invalid_tokens_removed: number;
  error?: string;
};

function unique(values: string[]): string[] {
  return [...new Set(values.filter((value) => value.length > 0))];
}

async function getStudentProfileIdsByBatch(batchId: string): Promise<string[]> {
  const { data, error } = await supabaseAdmin
    .from('students')
    .select('profile_id')
    .eq('batch_id', batchId)
    .not('profile_id', 'is', null);

  if (error) {
    throw new Error(error.message);
  }

  return unique((data ?? []).map((row) => String(row.profile_id ?? '')));
}

async function getTeacherProfileIdsByBatch(batchId: string): Promise<string[]> {
  const { data: assignments, error: assignmentError } = await supabaseAdmin
    .from('teacher_batches')
    .select('teacher_id')
    .eq('batch_id', batchId);

  if (assignmentError) {
    throw new Error(assignmentError.message);
  }

  const teacherIds = unique((assignments ?? []).map((row) => String(row.teacher_id ?? '')));
  if (teacherIds.length === 0) {
    return [];
  }

  const { data: teachers, error: teacherError } = await supabaseAdmin
    .from('teachers')
    .select('profile_id')
    .in('id', teacherIds)
    .not('profile_id', 'is', null);

  if (teacherError) {
    throw new Error(teacherError.message);
  }

  return unique((teachers ?? []).map((row) => String(row.profile_id ?? '')));
}

async function resolveTargetProfileIds(
  targetType: NotificationTargetType,
  targetId?: string | null
): Promise<string[] | null> {
  if (targetType === 'all') {
    return null;
  }

  if (!targetId) {
    return [];
  }

  if (targetType === 'student') {
    const { data, error } = await supabaseAdmin
      .from('students')
      .select('profile_id')
      .eq('id', targetId)
      .maybeSingle();

    if (error) {
      throw new Error(error.message);
    }

    const profileId = String(data?.profile_id ?? '');
    return profileId ? [profileId] : [];
  }

  if (targetType === 'class') {
    const { data, error } = await supabaseAdmin
      .from('students')
      .select('profile_id')
      .eq('class_id', targetId)
      .not('profile_id', 'is', null);

    if (error) {
      throw new Error(error.message);
    }

    return unique((data ?? []).map((row) => String(row.profile_id ?? '')));
  }

  const [studentProfileIds, teacherProfileIds] = await Promise.all([
    getStudentProfileIdsByBatch(targetId),
    getTeacherProfileIdsByBatch(targetId),
  ]);

  return unique([...studentProfileIds, ...teacherProfileIds]);
}

async function getDeviceTokensForProfiles(profileIds: string[] | null): Promise<string[]> {
  let request = supabaseAdmin
    .from('notification_devices')
    .select('device_token')
    .eq('notifications_enabled', true);

  if (profileIds != null) {
    if (profileIds.length === 0) {
      return [];
    }

    request = request.in('profile_id', profileIds);
  }

  const { data, error } = await request;
  if (error) {
    throw new Error(error.message);
  }

  return unique((data ?? []).map((row) => String(row.device_token ?? '')));
}

function isInvalidRegistrationToken(errorCode?: string): boolean {
  return (
    errorCode === 'messaging/invalid-registration-token' ||
    errorCode === 'messaging/registration-token-not-registered'
  );
}

async function removeInvalidTokens(tokens: string[]) {
  if (tokens.length === 0) {
    return;
  }

  const { error } = await supabaseAdmin
    .from('notification_devices')
    .delete()
    .in('device_token', tokens);

  if (error) {
    console.warn('Failed to cleanup invalid FCM tokens:', error.message);
  }
}

export async function sendNotificationPush(input: SendPushInput): Promise<PushDeliveryResult> {
  try {
    const profileIds = await resolveTargetProfileIds(input.targetType, input.targetId);
    const tokens = await getDeviceTokensForProfiles(profileIds);

    if (tokens.length === 0) {
      return {
        status: 'no_recipients',
        tokens_targeted: 0,
        sent: 0,
        failed: 0,
        invalid_tokens_removed: 0,
      };
    }

    const messaging = initFirebaseMessaging();
    if (!messaging) {
      return {
        status: 'provider_unavailable',
        tokens_targeted: tokens.length,
        sent: 0,
        failed: tokens.length,
        invalid_tokens_removed: 0,
      };
    }

    let sent = 0;
    let failed = 0;
    const invalidTokens: string[] = [];
    const chunkSize = 500;

    for (let index = 0; index < tokens.length; index += chunkSize) {
      const chunk = tokens.slice(index, index + chunkSize);
      const response = await messaging.sendEachForMulticast({
        tokens: chunk,
        notification: {
          title: input.title,
          body: input.body ?? '',
        },
        data: {
          notification_id: input.notificationId,
          target_type: input.targetType,
          target_id: input.targetId ?? '',
        },
      });

      sent += response.successCount;
      failed += response.failureCount;

          response.responses.forEach(
            (
              item: { success: boolean; error?: { code?: string } },
              itemIndex: number
            ) => {
        if (item.success) {
          return;
        }

        const code = item.error?.code;
        if (isInvalidRegistrationToken(code)) {
          invalidTokens.push(chunk[itemIndex]);
        }
      });
    }

    const uniqueInvalidTokens = unique(invalidTokens);
    await removeInvalidTokens(uniqueInvalidTokens);

    return {
      status: sent > 0 ? 'sent' : 'failed',
      tokens_targeted: tokens.length,
      sent,
      failed,
      invalid_tokens_removed: uniqueInvalidTokens.length,
    };
  } catch (error) {
    return {
      status: 'failed',
      tokens_targeted: 0,
      sent: 0,
      failed: 0,
      invalid_tokens_removed: 0,
      error: error instanceof Error ? error.message : 'Unknown push delivery error',
    };
  }
}
