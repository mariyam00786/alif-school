import { randomUUID } from 'crypto';

import { config } from './config';

export type DevBatch = {
  id: string;
  name: string;
  name_ml?: string | null;
  description?: string | null;
  capacity?: number | null;
  timing?: string | null;
  status: 'active' | 'inactive';
};

export type DevClass = {
  id: string;
  name: string;
  name_ml?: string | null;
  level?: string | null;
  batch_id: string;
  status: 'active' | 'inactive';
};

export type DevStudent = {
  id: string;
  profile_id?: string | null;
  parent_phone: string;
  father_name: string;
  mother_name: string;
  date_of_birth: string;
  gender: 'male' | 'female';
  batch_id?: string | null;
  class_id?: string | null;
  address?: string | null;
  enrollment_date: string;
  status: 'active' | 'inactive';
};

export type DevTeacher = {
  id: string;
  profile_id?: string | null;
  full_name: string;
  mobile_number: string;
  email?: string | null;
  qualification?: string | null;
  status: 'active' | 'inactive';
};

export type DevCategory = {
  id: string;
  name: string;
  name_ml?: string | null;
  icon?: string | null;
  display_order: number;
  status: 'active' | 'inactive';
};

export type DevActivity = {
  id: string;
  category_id: string;
  name: string;
  name_ml?: string | null;
  display_order: number;
  has_quantity: boolean;
  status: 'active' | 'inactive';
};

export type DevRating = {
  id: string;
  activity_id: string;
  rating_name: string;
  rating_name_ml?: string | null;
  marks: number;
  color: string;
  display_order: number;
};

export type DevActivityLog = {
  id: string;
  student_id: string;
  activity_id: string;
  rating_id: string;
  log_date: string;
  quantity?: number | null;
  marks_earned: number;
  parent_approved: boolean;
  notes?: string | null;
};

export type DevTeacherRemark = {
  id: string;
  teacher_id: string;
  student_id: string;
  remark: string;
  created_at: string;
};

export type DevBadge = {
  id: string;
  name: string;
  name_ml?: string | null;
  description?: string | null;
  icon?: string | null;
  criteria?: Record<string, unknown> | null;
  bonus_points: number;
  status: 'active' | 'inactive';
  created_at: string;
};

export type DevNotification = {
  id: string;
  title: string;
  body?: string | null;
  target_type: 'all' | 'batch' | 'class' | 'student';
  target_id?: string | null;
  scheduled_at?: string | null;
  sent_at?: string | null;
  created_at: string;
};

export type DevDeviceToken = {
  profile_id: string;
  role: string;
  app_name: 'admin' | 'student_teacher';
  platform: 'android' | 'ios' | 'web' | 'macos' | 'windows' | 'linux' | 'unknown';
  device_token: string;
  notifications_enabled: boolean;
  last_seen_at: string;
};

export type DevStudentBadge = {
  id: string;
  student_id: string;
  badge_id: string;
  earned_at: string;
};

export type DevAuthUser = {
  id: string;
  phone: string;
  full_name: string;
  role: 'admin' | 'teacher' | 'student' | 'parent';
};

const devStudentProfilePhotos = new Map<string, string>();

const batches: DevBatch[] = [
  {
    id: '11111111-1111-4111-8111-111111111111',
    name: 'Weekend Batch A',
    name_ml: 'വാരാന്ത്യ ബാച്ച് A',
    description: 'Saturday and Sunday morning batch',
    capacity: 30,
    timing: '08:00 - 10:00',
    status: 'active',
  },
  {
    id: '22222222-2222-4222-8222-222222222222',
    name: 'Evening Batch',
    name_ml: 'സായാഹ്ന ബാച്ച്',
    description: 'Weekday evening batch',
    capacity: 25,
    timing: '17:30 - 19:00',
    status: 'active',
  },
];

const classes: DevClass[] = [
  {
    id: '33333333-3333-4333-8333-333333333333',
    name: 'Beginner',
    name_ml: 'തുടക്കം',
    level: 'beginner',
    batch_id: '11111111-1111-4111-8111-111111111111',
    status: 'active',
  },
  {
    id: '44444444-4444-4444-8444-444444444444',
    name: 'Intermediate',
    name_ml: 'ഇടത്തരം',
    level: 'intermediate',
    batch_id: '22222222-2222-4222-8222-222222222222',
    status: 'active',
  },
];

const students: DevStudent[] = [
  {
    id: '55555555-5555-4555-8555-555555555555',
    profile_id: '10000000-0000-4000-8000-000000000003',
    parent_phone: '9999999999',
    father_name: 'Abdullah',
    mother_name: 'Amina',
    date_of_birth: '2014-05-11',
    gender: 'male',
    batch_id: '11111111-1111-4111-8111-111111111111',
    class_id: '33333333-3333-4333-8333-333333333333',
    address: 'Malappuram',
    enrollment_date: '2026-06-01',
    status: 'active',
  },
];

const authUsers: DevAuthUser[] = [
  {
    id: '10000000-0000-4000-8000-000000000001',
    phone: '9999999999',
    full_name: 'Admin User',
    role: 'admin',
  },
  {
    id: '10000000-0000-4000-8000-000000000002',
    phone: '8888888888',
    full_name: 'Usthad Rashid',
    role: 'teacher',
  },
  {
    id: '10000000-0000-4000-8000-000000000003',
    phone: '9999999998',
    full_name: 'Student User',
    role: 'student',
  },
  {
    id: '10000000-0000-4000-8000-000000000004',
    phone: '9999999997',
    full_name: 'Parent User',
    role: 'parent',
  },
];

const teachers: DevTeacher[] = [
  {
    id: '66666666-6666-4666-8666-666666666666',
    full_name: 'Usthad Rashid',
    mobile_number: '8888888888',
    email: 'rashid@example.com',
    qualification: 'B.A. Islamic Studies',
    status: 'active',
  },
  {
    id: '77777777-7777-4777-8777-777777777777',
    full_name: 'Teacher Sameera',
    mobile_number: '7777777777',
    email: 'sameera@example.com',
    qualification: 'M.A. Arabic',
    status: 'inactive',
  },
];

const teacherBatchAssignments: Array<{ teacher_id: string; batch_id: string }> = [
  {
    teacher_id: '66666666-6666-4666-8666-666666666666',
    batch_id: '11111111-1111-4111-8111-111111111111',
  },
  {
    teacher_id: '66666666-6666-4666-8666-666666666666',
    batch_id: '22222222-2222-4222-8222-222222222222',
  },
  {
    teacher_id: '77777777-7777-4777-8777-777777777777',
    batch_id: '22222222-2222-4222-8222-222222222222',
  },
];

const categories: DevCategory[] = [
  {
    id: '88888888-8888-4888-8888-888888888888',
    name: 'Prayer',
    name_ml: 'നമസ്കാരം',
    icon: 'mosque',
    display_order: 1,
    status: 'active',
  },
  {
    id: '99999999-9999-4999-8999-999999999999',
    name: 'Sunnah Prayers',
    name_ml: 'സുന്നത്ത് നമസ്കാരങ്ങൾ',
    icon: 'auto_awesome',
    display_order: 2,
    status: 'active',
  },
  {
    id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    name: 'Daily Routine',
    name_ml: 'ദിനചര്യ',
    icon: 'calendar_today',
    display_order: 3,
    status: 'active',
  },
];

const activities: DevActivity[] = [
  {
    id: 'abababab-abab-4bab-8bab-abababababab',
    category_id: '88888888-8888-4888-8888-888888888888',
    name: 'Subhi',
    name_ml: 'സുബ്ഹി',
    display_order: 1,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'bcbcbcbc-bcbc-4cbc-8cbc-bcbcbcbcbcbc',
    category_id: '88888888-8888-4888-8888-888888888888',
    name: 'Zuhr',
    name_ml: 'ളുഹ്ർ',
    display_order: 2,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'cdcdcdcd-cdcd-4dcd-8dcd-cdcdcdcdcdcd',
    category_id: '99999999-9999-4999-8999-999999999999',
    name: 'Before Subhi',
    name_ml: 'സുബ്ഹിക്ക് മുമ്പ്',
    display_order: 1,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'dededede-dede-4ede-8ede-dededededede',
    category_id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    name: 'Quran Recitation',
    name_ml: 'ഖുർആൻ പാരായണം',
    display_order: 1,
    has_quantity: true,
    status: 'active',
  },
  {
    id: 'efefefef-efef-4fef-8fef-efefefefefef',
    category_id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    name: 'Dhikr & Duas',
    name_ml: 'ദിക്ർ, ദുആകൾ',
    display_order: 4,
    has_quantity: false,
    status: 'active',
  },
];

const ratings: DevRating[] = [];
const activityLogs: DevActivityLog[] = [];
const teacherRemarks: DevTeacherRemark[] = [];
const badges: DevBadge[] = [
  {
    id: randomUUID(),
    name: '7-Day Streak',
    name_ml: '7 ദിവസത്തെ തുടർച്ച',
    description: 'Logged activities for 7 consecutive days',
    icon: 'military_tech',
    criteria: { type: 'streak', days: 7 },
    bonus_points: 25,
    status: 'active',
    created_at: new Date().toISOString(),
  },
  {
    id: randomUUID(),
    name: 'Perfect Prayer Week',
    name_ml: 'പൂർണ്ണ നമസ്കാര ആഴ്ച',
    description: 'Excellent in all mandatory prayers for 7 days',
    icon: 'workspace_premium',
    criteria: { type: 'perfect_prayer_week', days: 7 },
    bonus_points: 75,
    status: 'active',
    created_at: new Date().toISOString(),
  },
];
const notifications: DevNotification[] = [];
const deviceTokens: DevDeviceToken[] = [];
const studentBadges: DevStudentBadge[] = [
  {
    id: randomUUID(),
    student_id: '55555555-5555-4555-8555-555555555555',
    badge_id: '',
    earned_at: new Date().toISOString(),
  },
];

for (const activity of activities) {
  ratings.push(
    {
      id: randomUUID(),
      activity_id: activity.id,
      rating_name: 'excellent',
      rating_name_ml: 'മികച്ചത്',
      marks: 10,
      color: '#3FA34D',
      display_order: 1,
    },
    {
      id: randomUUID(),
      activity_id: activity.id,
      rating_name: 'satisfactory',
      rating_name_ml: 'തൃപ്തികരം',
      marks: 5,
      color: '#F1B500',
      display_order: 2,
    },
    {
      id: randomUUID(),
      activity_id: activity.id,
      rating_name: 'needs_improvement',
      rating_name_ml: 'തൃപ്തികരമല്ല',
      marks: 2,
      color: '#E07A11',
      display_order: 3,
    },
    {
      id: randomUUID(),
      activity_id: activity.id,
      rating_name: 'not_done',
      rating_name_ml: 'ചെയ്തില്ല',
      marks: 0,
      color: '#9CA3AF',
      display_order: 4,
    }
  );
}

function decorateStudent(student: DevStudent) {
  const batch = batches.find((item) => item.id === student.batch_id) ?? null;
  const classInfo = classes.find((item) => item.id === student.class_id) ?? null;

  return {
    ...student,
    profiles: null,
    batches: batch
      ? {
          id: batch.id,
          name: batch.name,
          name_ml: batch.name_ml ?? null,
          description: batch.description ?? null,
          capacity: batch.capacity ?? null,
          timing: batch.timing ?? null,
          status: batch.status,
        }
      : null,
    classes: classInfo
      ? {
          id: classInfo.id,
          name: classInfo.name,
          name_ml: classInfo.name_ml ?? null,
          level: classInfo.level ?? null,
        }
      : null,
  };
}

function decorateTeacher(teacher: DevTeacher) {
  const batchIds = teacherBatchAssignments
    .filter((item) => item.teacher_id === teacher.id)
    .map((item) => item.batch_id);
  const teacherBatches = batchIds
    .map((batchId) => batches.find((item) => item.id === batchId))
    .filter((item): item is DevBatch => item != null)
    .map((batch) => ({
      batch_id: batch.id,
      batches: {
        id: batch.id,
        name: batch.name,
        name_ml: batch.name_ml ?? null,
      },
    }));

  return {
    ...teacher,
    batch_ids: batchIds,
    teacher_batches: teacherBatches,
  };
}

function decorateActivityLog(log: DevActivityLog) {
  const activity = activities.find((item) => item.id === log.activity_id) ?? null;
  const rating = ratings.find((item) => item.id === log.rating_id) ?? null;

  return {
    ...log,
    activities: activity
      ? {
          id: activity.id,
          name: activity.name,
          name_ml: activity.name_ml ?? null,
          category_id: activity.category_id,
        }
      : null,
    activity_ratings: rating
      ? {
          id: rating.id,
          rating_name: rating.rating_name,
          rating_name_ml: rating.rating_name_ml ?? null,
          marks: rating.marks,
        }
      : null,
  };
}

export function shouldUseLocalData(error: unknown): boolean {
  if (config.forceLiveDb) {
    return false;
  }

  if (!config.allowLocalDataFallback) {
    return false;
  }

  const message =
    error instanceof Error
      ? error.message
      : typeof error === 'object' && error !== null && 'message' in error
        ? String((error as { message?: unknown }).message ?? '')
        : String(error ?? '');

  return /fetch failed|ECONNREFUSED|network|socket|ENOTFOUND/i.test(message);
}

export function listDevBatches(status?: string) {
  return batches.filter((item) => !status || item.status === status);
}

export function listDevClasses(params: {
  batch_id?: string;
  status?: string;
}) {
  let data = [...classes];

  if (params.batch_id) {
    data = data.filter((item) => item.batch_id === params.batch_id);
  }

  if (params.status) {
    data = data.filter((item) => item.status === params.status);
  }

  return data
    .sort((left, right) => left.name.localeCompare(right.name))
    .map((item) => {
      const batch = batches.find((batchItem) => batchItem.id === item.batch_id) ?? null;
      return {
        ...item,
        batches: batch
          ? {
              id: batch.id,
              name: batch.name,
              name_ml: batch.name_ml ?? null,
            }
          : null,
      };
    });
}

export function getDevClass(id: string) {
  return listDevClasses({}).find((item) => item.id === id) ?? null;
}

export function createDevClass(input: Omit<DevClass, 'id'>) {
  const created: DevClass = {
    id: randomUUID(),
    ...input,
  };

  classes.push(created);
  return getDevClass(created.id)!;
}

export function updateDevClass(id: string, input: Partial<Omit<DevClass, 'id'>>) {
  const index = classes.findIndex((item) => item.id === id);
  if (index === -1) {
    return null;
  }

  classes[index] = {
    ...classes[index],
    ...input,
  };

  return getDevClass(id);
}

export function deleteDevClass(id: string) {
  const index = classes.findIndex((item) => item.id === id);
  if (index === -1) {
    return false;
  }

  classes.splice(index, 1);
  for (const student of students) {
    if (student.class_id === id) {
      student.class_id = null;
    }
  }

  return true;
}

export function getDevBatch(id: string) {
  return batches.find((item) => item.id === id) ?? null;
}

export function getDevClasses(batchId: string) {
  return classes.filter((item) => item.batch_id === batchId && item.status === 'active');
}

export function createDevBatch(input: Omit<DevBatch, 'id'>) {
  const created: DevBatch = {
    id: randomUUID(),
    ...input,
  };
  batches.unshift(created);
  return created;
}

export function updateDevBatch(id: string, input: Partial<Omit<DevBatch, 'id'>>) {
  const index = batches.findIndex((item) => item.id === id);
  if (index === -1) {
    return null;
  }

  batches[index] = {
    ...batches[index],
    ...input,
  };

  return batches[index];
}

export function deleteDevBatch(id: string) {
  const index = batches.findIndex((item) => item.id === id);
  if (index === -1) {
    return false;
  }

  batches.splice(index, 1);

  for (let classIndex = classes.length - 1; classIndex >= 0; classIndex -= 1) {
    if (classes[classIndex].batch_id === id) {
      const classId = classes[classIndex].id;
      classes.splice(classIndex, 1);

      for (const student of students) {
        if (student.class_id === classId) {
          student.class_id = null;
        }
      }
    }
  }

  for (const student of students) {
    if (student.batch_id === id) {
      student.batch_id = null;
      student.class_id = null;
    }
  }

  for (let index = teacherBatchAssignments.length - 1; index >= 0; index -= 1) {
    if (teacherBatchAssignments[index].batch_id === id) {
      teacherBatchAssignments.splice(index, 1);
    }
  }

  return true;
}

export function listDevTeachers(params: {
  search?: string;
  status?: string;
  batch_id?: string;
}) {
  let data = [...teachers];

  if (params.search) {
    const query = params.search.toLowerCase();
    data = data.filter(
      (teacher) =>
        teacher.full_name.toLowerCase().includes(query) ||
        teacher.mobile_number.toLowerCase().includes(query) ||
        (teacher.email ?? '').toLowerCase().includes(query)
    );
  }

  if (params.status) {
    data = data.filter((teacher) => teacher.status === params.status);
  }

  if (params.batch_id) {
    const teacherIds = new Set(
      teacherBatchAssignments
        .filter((item) => item.batch_id === params.batch_id)
        .map((item) => item.teacher_id)
    );
    data = data.filter((teacher) => teacherIds.has(teacher.id));
  }

  return data.map(decorateTeacher);
}

export function getDevTeacher(id: string) {
  const teacher = teachers.find((item) => item.id === id);
  return teacher ? decorateTeacher(teacher) : null;
}

export function createDevTeacher(
  input: Omit<DevTeacher, 'id'> & { batch_ids?: string[] }
) {
  const { batch_ids = [], ...teacherInput } = input;
  const created: DevTeacher = {
    id: randomUUID(),
    ...teacherInput,
  };
  teachers.unshift(created);
  for (const batchId of batch_ids) {
    teacherBatchAssignments.push({ teacher_id: created.id, batch_id: batchId });
  }
  return decorateTeacher(created);
}

export function updateDevTeacher(
  id: string,
  input: Partial<Omit<DevTeacher, 'id'>> & { batch_ids?: string[] }
) {
  const index = teachers.findIndex((item) => item.id === id);
  if (index === -1) {
    return null;
  }

  const { batch_ids, ...teacherInput } = input;
  teachers[index] = {
    ...teachers[index],
    ...teacherInput,
  };

  if (batch_ids) {
    for (let assignmentIndex = teacherBatchAssignments.length - 1; assignmentIndex >= 0; assignmentIndex -= 1) {
      if (teacherBatchAssignments[assignmentIndex].teacher_id === id) {
        teacherBatchAssignments.splice(assignmentIndex, 1);
      }
    }

    for (const batchId of batch_ids) {
      teacherBatchAssignments.push({ teacher_id: id, batch_id: batchId });
    }
  }

  return decorateTeacher(teachers[index]);
}

export function deleteDevTeacher(id: string) {
  const index = teachers.findIndex((item) => item.id === id);
  if (index === -1) {
    return false;
  }

  teachers.splice(index, 1);
  for (let assignmentIndex = teacherBatchAssignments.length - 1; assignmentIndex >= 0; assignmentIndex -= 1) {
    if (teacherBatchAssignments[assignmentIndex].teacher_id === id) {
      teacherBatchAssignments.splice(assignmentIndex, 1);
    }
  }

  return true;
}

export function listDevCategories(status?: string) {
  const filtered = categories.filter((item) => !status || item.status === status);
  return filtered.sort((left, right) => left.display_order - right.display_order);
}

export function createDevCategory(input: Omit<DevCategory, 'id'>) {
  const created: DevCategory = {
    id: randomUUID(),
    ...input,
  };
  categories.push(created);
  return created;
}

export function updateDevCategory(id: string, input: Partial<Omit<DevCategory, 'id'>>) {
  const index = categories.findIndex((item) => item.id === id);
  if (index == -1) {
    return null;
  }

  categories[index] = {
    ...categories[index],
    ...input,
  };

  return categories[index];
}

export function deleteDevCategory(id: string) {
  const index = categories.findIndex((item) => item.id === id);
  if (index == -1) {
    return false;
  }

  categories.splice(index, 1);
  for (let activityIndex = activities.length - 1; activityIndex >= 0; activityIndex -= 1) {
    if (activities[activityIndex].category_id === id) {
      activities.splice(activityIndex, 1);
    }
  }
  return true;
}

export function listDevActivities(params: { category_id?: string; status?: string }) {
  let data = [...activities];

  if (params.category_id) {
    data = data.filter((item) => item.category_id === params.category_id);
  }

  if (params.status) {
    data = data.filter((item) => item.status === params.status);
  }

  data.sort((left, right) => {
    if (left.category_id != right.category_id) {
      return left.category_id.localeCompare(right.category_id);
    }

    return left.display_order - right.display_order;
  });

  return data.map((activity) => {
    const category = categories.find((item) => item.id === activity.category_id) ?? null;
    return {
      ...activity,
      activity_categories: category
          ? {
              id: category.id,
              name: category.name,
              name_ml: category.name_ml ?? null,
            }
          : null,
    };
  });
}

export function createDevActivity(input: Omit<DevActivity, 'id'>) {
  const created: DevActivity = {
    id: randomUUID(),
    ...input,
  };
  activities.push(created);
  return listDevActivities({}).find((item) => item.id === created.id)!;
}

export function updateDevActivity(id: string, input: Partial<Omit<DevActivity, 'id'>>) {
  const index = activities.findIndex((item) => item.id === id);
  if (index === -1) {
    return null;
  }

  activities[index] = {
    ...activities[index],
    ...input,
  };

  return listDevActivities({}).find((item) => item.id === id) ?? null;
}

export function deleteDevActivity(id: string) {
  const index = activities.findIndex((item) => item.id === id);
  if (index === -1) {
    return false;
  }

  activities.splice(index, 1);
  for (let ratingIndex = ratings.length - 1; ratingIndex >= 0; ratingIndex -= 1) {
    if (ratings[ratingIndex].activity_id === id) {
      ratings.splice(ratingIndex, 1);
    }
  }
  for (let logIndex = activityLogs.length - 1; logIndex >= 0; logIndex -= 1) {
    if (activityLogs[logIndex].activity_id === id) {
      activityLogs.splice(logIndex, 1);
    }
  }
  return true;
}

export function listDevRatings(activityId?: string) {
  let data = [...ratings];

  if (activityId) {
    data = data.filter((item) => item.activity_id === activityId);
  }

  data.sort((left, right) => left.display_order - right.display_order);

  return data.map((rating) => {
    const activity = activities.find((item) => item.id === rating.activity_id) ?? null;
    return {
      ...rating,
      activities: activity
          ? {
              id: activity.id,
              name: activity.name,
              name_ml: activity.name_ml ?? null,
            }
          : null,
    };
  });
}

export function createDevRating(input: Omit<DevRating, 'id'>) {
  const created: DevRating = {
    id: randomUUID(),
    ...input,
  };
  ratings.push(created);
  return listDevRatings().find((item) => item.id === created.id)!;
}

export function updateDevRating(id: string, input: Partial<Omit<DevRating, 'id'>>) {
  const index = ratings.findIndex((item) => item.id === id);
  if (index === -1) {
    return null;
  }

  ratings[index] = {
    ...ratings[index],
    ...input,
  };

  return listDevRatings().find((item) => item.id === id) ?? null;
}

export function deleteDevRating(id: string) {
  const index = ratings.findIndex((item) => item.id === id);
  if (index === -1) {
    return false;
  }

  ratings.splice(index, 1);
  for (let logIndex = activityLogs.length - 1; logIndex >= 0; logIndex -= 1) {
    if (activityLogs[logIndex].rating_id === id) {
      activityLogs.splice(logIndex, 1);
    }
  }
  return true;
}

export function listDevStudents(params: {
  search?: string;
  batch_id?: string;
  status?: string;
  limit: number;
  offset: number;
}) {
  let data = [...students];

  if (params.search) {
    const query = params.search.toLowerCase();
    data = data.filter(
      (student) =>
        student.parent_phone.toLowerCase().includes(query) ||
        student.father_name.toLowerCase().includes(query) ||
        student.mother_name.toLowerCase().includes(query)
    );
  }

  if (params.batch_id) {
    data = data.filter((student) => student.batch_id === params.batch_id);
  }

  if (params.status) {
    data = data.filter((student) => student.status === params.status);
  }

  data.sort((left, right) => right.enrollment_date.localeCompare(left.enrollment_date));

  return {
    data: data.slice(params.offset, params.offset + params.limit).map(decorateStudent),
    total: data.length,
  };
}

export function getDevStudent(id: string) {
  const student = students.find((item) => item.id === id);
  return student ? decorateStudent(student) : null;
}

export function createDevStudent(input: Omit<DevStudent, 'id' | 'enrollment_date' | 'status'> & { status?: DevStudent['status'] }) {
  const created: DevStudent = {
    id: randomUUID(),
    enrollment_date: new Date().toISOString().split('T')[0],
    status: input.status ?? 'active',
    ...input,
  };

  students.unshift(created);
  return decorateStudent(created);
}

export function updateDevStudent(id: string, input: Partial<Omit<DevStudent, 'id'>>) {
  const index = students.findIndex((item) => item.id === id);
  if (index === -1) {
    return null;
  }

  students[index] = {
    ...students[index],
    ...input,
  };

  return decorateStudent(students[index]);
}

export function deleteDevStudent(id: string) {
  const index = students.findIndex((item) => item.id === id);
  if (index === -1) {
    return false;
  }

  students.splice(index, 1);
  for (let logIndex = activityLogs.length - 1; logIndex >= 0; logIndex -= 1) {
    if (activityLogs[logIndex].student_id === id) {
      activityLogs.splice(logIndex, 1);
    }
  }
  return true;
}

export function listDevActivityLogs(params: {
  student_id?: string;
  log_date?: string;
  from_date?: string;
  to_date?: string;
}) {
  let data = [...activityLogs];

  if (params.student_id) {
    data = data.filter((item) => item.student_id === params.student_id);
  }

  if (params.log_date) {
    data = data.filter((item) => item.log_date === params.log_date);
  }

  if (params.from_date) {
    data = data.filter((item) => item.log_date >= params.from_date!);
  }

  if (params.to_date) {
    data = data.filter((item) => item.log_date <= params.to_date!);
  }

  data.sort((left, right) => {
    if (left.log_date !== right.log_date) {
      return right.log_date.localeCompare(left.log_date);
    }

    return left.activity_id.localeCompare(right.activity_id);
  });

  return data.map(decorateActivityLog);
}

export function createDevActivityLog(input: Omit<DevActivityLog, 'id' | 'marks_earned'>) {
  const rating = ratings.find((item) => item.id === input.rating_id);
  if (!rating) {
    throw new Error('Rating not found');
  }

  const existingIndex = activityLogs.findIndex(
    (item) =>
      item.student_id === input.student_id &&
      item.activity_id === input.activity_id &&
      item.log_date === input.log_date
  );

  const record: DevActivityLog = {
    id: existingIndex >= 0 ? activityLogs[existingIndex].id : randomUUID(),
    ...input,
    marks_earned: rating.marks,
  };

  if (existingIndex >= 0) {
    activityLogs[existingIndex] = record;
  } else {
    activityLogs.push(record);
  }

  return decorateActivityLog(record);
}

export function updateDevActivityLog(
  id: string,
  input: Partial<Omit<DevActivityLog, 'id' | 'marks_earned'>>
) {
  const index = activityLogs.findIndex((item) => item.id === id);
  if (index === -1) {
    return null;
  }

  const nextRatingId = input.rating_id ?? activityLogs[index].rating_id;
  const rating = ratings.find((item) => item.id === nextRatingId);
  if (!rating) {
    throw new Error('Rating not found');
  }

  activityLogs[index] = {
    ...activityLogs[index],
    ...input,
    rating_id: nextRatingId,
    marks_earned: rating.marks,
  };

  return decorateActivityLog(activityLogs[index]);
}

export function deleteDevActivityLog(id: string) {
  const index = activityLogs.findIndex((item) => item.id === id);
  if (index === -1) {
    return false;
  }

  activityLogs.splice(index, 1);
  return true;
}

export function listDevTeacherRemarks(params: {
  teacher_id?: string;
  student_id?: string;
  limit: number;
}) {
  let data = [...teacherRemarks];

  if (params.teacher_id) {
    data = data.filter((item) => item.teacher_id === params.teacher_id);
  }

  if (params.student_id) {
    data = data.filter((item) => item.student_id === params.student_id);
  }

  return data
    .sort((left, right) => right.created_at.localeCompare(left.created_at))
    .slice(0, params.limit)
    .map((item) => {
      const teacher = getDevTeacher(item.teacher_id);
      const student = getDevStudent(item.student_id);
      return {
        ...item,
        teacher_name: teacher?.full_name ?? null,
        student_name: student
          ? [student.father_name, student.mother_name]
              .filter((name) => name && name.trim().length > 0)
              .join(' / ')
          : null,
        parent_phone: student?.parent_phone ?? null,
      };
    });
}

export function createDevTeacherRemark(input: {
  teacher_id: string;
  student_id: string;
  remark: string;
}) {
  const created: DevTeacherRemark = {
    id: randomUUID(),
    teacher_id: input.teacher_id,
    student_id: input.student_id,
    remark: input.remark,
    created_at: new Date().toISOString(),
  };

  teacherRemarks.push(created);
  return listDevTeacherRemarks({ limit: 1, teacher_id: undefined, student_id: undefined }).find(
    (item) => item.id === created.id
  );
}

export function getDevAuthUserByPhone(phone: string) {
  return authUsers.find((item) => item.phone === phone) ?? null;
}

export function getDevAuthUserById(id: string) {
  return authUsers.find((item) => item.id === id) ?? null;
}

export function upsertDevDeviceToken(input: DevDeviceToken) {
  const index = deviceTokens.findIndex((item) => item.device_token === input.device_token);
  if (index === -1) {
    deviceTokens.unshift(input);
    return input;
  }

  deviceTokens[index] = {
    ...deviceTokens[index],
    ...input,
  };

  return deviceTokens[index];
}

export function deleteDevDeviceToken(profileId: string, token: string) {
  const index = deviceTokens.findIndex(
    (item) => item.profile_id === profileId && item.device_token === token
  );

  if (index === -1) {
    return false;
  }

  deviceTokens.splice(index, 1);
  return true;
}

export function listDevDeviceTokens(params: {
  profile_ids?: string[];
  notifications_enabled?: boolean;
}) {
  const profileIds = params.profile_ids ?? [];

  return deviceTokens.filter((item) => {
    if (params.notifications_enabled != null && item.notifications_enabled !== params.notifications_enabled) {
      return false;
    }

    if (profileIds.length > 0 && !profileIds.includes(item.profile_id)) {
      return false;
    }

    return true;
  });
}

export function getDevStudentProfilePhoto(studentId: string) {
  return devStudentProfilePhotos.get(studentId) ?? null;
}

export function setDevStudentProfilePhoto(studentId: string, photoUrl: string) {
  devStudentProfilePhotos.set(studentId, photoUrl);
  return photoUrl;
}

export function listDevBadges(status?: string) {
  return badges
    .filter((item) => !status || item.status === status)
    .sort((left, right) => right.created_at.localeCompare(left.created_at));
}

export function createDevBadge(input: Omit<DevBadge, 'id' | 'created_at'>) {
  const created: DevBadge = {
    id: randomUUID(),
    created_at: new Date().toISOString(),
    ...input,
  };
  badges.unshift(created);
  return created;
}

export function updateDevBadge(id: string, input: Partial<Omit<DevBadge, 'id' | 'created_at'>>) {
  const index = badges.findIndex((item) => item.id === id);
  if (index === -1) {
    return null;
  }

  badges[index] = {
    ...badges[index],
    ...input,
  };

  return badges[index];
}

export function deleteDevBadge(id: string) {
  const index = badges.findIndex((item) => item.id === id);
  if (index === -1) {
    return false;
  }

  badges.splice(index, 1);
  return true;
}

export function listDevNotifications(params: {
  target_type?: string;
  target_id?: string;
}) {
  let data = [...notifications];

  if (params.target_type) {
    data = data.filter((item) => item.target_type === params.target_type);
  }

  if (params.target_id) {
    data = data.filter((item) => item.target_id === params.target_id);
  }

  return data.sort((left, right) => right.created_at.localeCompare(left.created_at));
}

export function createDevNotification(input: Omit<DevNotification, 'id' | 'created_at' | 'sent_at'>) {
  const created: DevNotification = {
    id: randomUUID(),
    created_at: new Date().toISOString(),
    sent_at: input.scheduled_at ? null : new Date().toISOString(),
    ...input,
  };
  notifications.unshift(created);
  return created;
}

export function updateDevNotification(
  id: string,
  input: Partial<Omit<DevNotification, 'id' | 'created_at'>>
) {
  const index = notifications.findIndex((item) => item.id === id);
  if (index === -1) {
    return null;
  }

  notifications[index] = {
    ...notifications[index],
    ...input,
  };

  return notifications[index];
}

export function deleteDevNotification(id: string) {
  const index = notifications.findIndex((item) => item.id === id);
  if (index === -1) {
    return false;
  }

  notifications.splice(index, 1);
  return true;
}

if (badges.length > 0 && studentBadges[0].badge_id === '') {
  studentBadges[0].badge_id = badges[0].id;
}

export function listDevStudentBadges(studentId?: string) {
  const assignments = studentBadges.filter(
    (item) => !studentId || item.student_id === studentId
  );

  return assignments
    .map((item) => {
      const badge = badges.find((entry) => entry.id === item.badge_id);
      if (!badge) {
        return null;
      }

      return {
        ...item,
        badges: badge,
      };
    })
    .filter((item): item is NonNullable<typeof item> => item != null)
    .sort((left, right) => right.earned_at.localeCompare(left.earned_at));
}