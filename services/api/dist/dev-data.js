"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.shouldUseLocalData = shouldUseLocalData;
exports.listDevBatches = listDevBatches;
exports.listDevClasses = listDevClasses;
exports.getDevClass = getDevClass;
exports.createDevClass = createDevClass;
exports.updateDevClass = updateDevClass;
exports.deleteDevClass = deleteDevClass;
exports.getDevBatch = getDevBatch;
exports.getDevClasses = getDevClasses;
exports.createDevBatch = createDevBatch;
exports.updateDevBatch = updateDevBatch;
exports.deleteDevBatch = deleteDevBatch;
exports.listDevTeachers = listDevTeachers;
exports.getDevTeacher = getDevTeacher;
exports.createDevTeacher = createDevTeacher;
exports.updateDevTeacher = updateDevTeacher;
exports.deleteDevTeacher = deleteDevTeacher;
exports.listDevCategories = listDevCategories;
exports.createDevCategory = createDevCategory;
exports.updateDevCategory = updateDevCategory;
exports.deleteDevCategory = deleteDevCategory;
exports.listDevActivities = listDevActivities;
exports.createDevActivity = createDevActivity;
exports.updateDevActivity = updateDevActivity;
exports.deleteDevActivity = deleteDevActivity;
exports.listDevRatings = listDevRatings;
exports.createDevRating = createDevRating;
exports.updateDevRating = updateDevRating;
exports.deleteDevRating = deleteDevRating;
exports.listDevStudents = listDevStudents;
exports.getDevStudent = getDevStudent;
exports.createDevStudent = createDevStudent;
exports.updateDevStudent = updateDevStudent;
exports.deleteDevStudent = deleteDevStudent;
exports.listDevActivityLogs = listDevActivityLogs;
exports.createDevActivityLog = createDevActivityLog;
exports.updateDevActivityLog = updateDevActivityLog;
exports.deleteDevActivityLog = deleteDevActivityLog;
exports.listDevTeacherRemarks = listDevTeacherRemarks;
exports.createDevTeacherRemark = createDevTeacherRemark;
exports.getDevAuthUserByPhone = getDevAuthUserByPhone;
exports.getDevAuthUserById = getDevAuthUserById;
exports.upsertDevDeviceToken = upsertDevDeviceToken;
exports.deleteDevDeviceToken = deleteDevDeviceToken;
exports.listDevDeviceTokens = listDevDeviceTokens;
exports.getDevStudentProfilePhoto = getDevStudentProfilePhoto;
exports.setDevStudentProfilePhoto = setDevStudentProfilePhoto;
exports.listDevBadges = listDevBadges;
exports.createDevBadge = createDevBadge;
exports.updateDevBadge = updateDevBadge;
exports.deleteDevBadge = deleteDevBadge;
exports.listDevNotifications = listDevNotifications;
exports.createDevNotification = createDevNotification;
exports.updateDevNotification = updateDevNotification;
exports.deleteDevNotification = deleteDevNotification;
exports.listDevStudentBadges = listDevStudentBadges;
const crypto_1 = require("crypto");
const config_1 = require("./config");
const devStudentProfilePhotos = new Map();
const batches = [
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
const classes = [
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
const students = [
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
const authUsers = [
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
const teachers = [
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
const teacherBatchAssignments = [
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
const categories = [
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
const activities = [
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
const ratings = [];
const activityLogs = [];
const teacherRemarks = [];
const badges = [
    {
        id: (0, crypto_1.randomUUID)(),
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
        id: (0, crypto_1.randomUUID)(),
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
const notifications = [];
const deviceTokens = [];
const studentBadges = [
    {
        id: (0, crypto_1.randomUUID)(),
        student_id: '55555555-5555-4555-8555-555555555555',
        badge_id: '',
        earned_at: new Date().toISOString(),
    },
];
for (const activity of activities) {
    ratings.push({
        id: (0, crypto_1.randomUUID)(),
        activity_id: activity.id,
        rating_name: 'excellent',
        rating_name_ml: 'മികച്ചത്',
        marks: 10,
        color: '#3FA34D',
        display_order: 1,
    }, {
        id: (0, crypto_1.randomUUID)(),
        activity_id: activity.id,
        rating_name: 'satisfactory',
        rating_name_ml: 'തൃപ്തികരം',
        marks: 5,
        color: '#F1B500',
        display_order: 2,
    }, {
        id: (0, crypto_1.randomUUID)(),
        activity_id: activity.id,
        rating_name: 'needs_improvement',
        rating_name_ml: 'തൃപ്തികരമല്ല',
        marks: 2,
        color: '#E07A11',
        display_order: 3,
    }, {
        id: (0, crypto_1.randomUUID)(),
        activity_id: activity.id,
        rating_name: 'not_done',
        rating_name_ml: 'ചെയ്തില്ല',
        marks: 0,
        color: '#9CA3AF',
        display_order: 4,
    });
}
function decorateStudent(student) {
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
function decorateTeacher(teacher) {
    const batchIds = teacherBatchAssignments
        .filter((item) => item.teacher_id === teacher.id)
        .map((item) => item.batch_id);
    const teacherBatches = batchIds
        .map((batchId) => batches.find((item) => item.id === batchId))
        .filter((item) => item != null)
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
function decorateActivityLog(log) {
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
function shouldUseLocalData(error) {
    if (config_1.config.forceLiveDb) {
        return false;
    }
    if (!config_1.config.allowLocalDataFallback) {
        return false;
    }
    const message = error instanceof Error
        ? error.message
        : typeof error === 'object' && error !== null && 'message' in error
            ? String(error.message ?? '')
            : String(error ?? '');
    return /fetch failed|ECONNREFUSED|network|socket|ENOTFOUND/i.test(message);
}
function listDevBatches(status) {
    return batches.filter((item) => !status || item.status === status);
}
function listDevClasses(params) {
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
function getDevClass(id) {
    return listDevClasses({}).find((item) => item.id === id) ?? null;
}
function createDevClass(input) {
    const created = {
        id: (0, crypto_1.randomUUID)(),
        ...input,
    };
    classes.push(created);
    return getDevClass(created.id);
}
function updateDevClass(id, input) {
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
function deleteDevClass(id) {
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
function getDevBatch(id) {
    return batches.find((item) => item.id === id) ?? null;
}
function getDevClasses(batchId) {
    return classes.filter((item) => item.batch_id === batchId && item.status === 'active');
}
function createDevBatch(input) {
    const created = {
        id: (0, crypto_1.randomUUID)(),
        ...input,
    };
    batches.unshift(created);
    return created;
}
function updateDevBatch(id, input) {
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
function deleteDevBatch(id) {
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
function listDevTeachers(params) {
    let data = [...teachers];
    if (params.search) {
        const query = params.search.toLowerCase();
        data = data.filter((teacher) => teacher.full_name.toLowerCase().includes(query) ||
            teacher.mobile_number.toLowerCase().includes(query) ||
            (teacher.email ?? '').toLowerCase().includes(query));
    }
    if (params.status) {
        data = data.filter((teacher) => teacher.status === params.status);
    }
    if (params.batch_id) {
        const teacherIds = new Set(teacherBatchAssignments
            .filter((item) => item.batch_id === params.batch_id)
            .map((item) => item.teacher_id));
        data = data.filter((teacher) => teacherIds.has(teacher.id));
    }
    return data.map(decorateTeacher);
}
function getDevTeacher(id) {
    const teacher = teachers.find((item) => item.id === id);
    return teacher ? decorateTeacher(teacher) : null;
}
function createDevTeacher(input) {
    const { batch_ids = [], ...teacherInput } = input;
    const created = {
        id: (0, crypto_1.randomUUID)(),
        ...teacherInput,
    };
    teachers.unshift(created);
    for (const batchId of batch_ids) {
        teacherBatchAssignments.push({ teacher_id: created.id, batch_id: batchId });
    }
    return decorateTeacher(created);
}
function updateDevTeacher(id, input) {
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
function deleteDevTeacher(id) {
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
function listDevCategories(status) {
    const filtered = categories.filter((item) => !status || item.status === status);
    return filtered.sort((left, right) => left.display_order - right.display_order);
}
function createDevCategory(input) {
    const created = {
        id: (0, crypto_1.randomUUID)(),
        ...input,
    };
    categories.push(created);
    return created;
}
function updateDevCategory(id, input) {
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
function deleteDevCategory(id) {
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
function listDevActivities(params) {
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
function createDevActivity(input) {
    const created = {
        id: (0, crypto_1.randomUUID)(),
        ...input,
    };
    activities.push(created);
    return listDevActivities({}).find((item) => item.id === created.id);
}
function updateDevActivity(id, input) {
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
function deleteDevActivity(id) {
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
function listDevRatings(activityId) {
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
function createDevRating(input) {
    const created = {
        id: (0, crypto_1.randomUUID)(),
        ...input,
    };
    ratings.push(created);
    return listDevRatings().find((item) => item.id === created.id);
}
function updateDevRating(id, input) {
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
function deleteDevRating(id) {
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
function listDevStudents(params) {
    let data = [...students];
    if (params.search) {
        const query = params.search.toLowerCase();
        data = data.filter((student) => student.parent_phone.toLowerCase().includes(query) ||
            student.father_name.toLowerCase().includes(query) ||
            student.mother_name.toLowerCase().includes(query));
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
function getDevStudent(id) {
    const student = students.find((item) => item.id === id);
    return student ? decorateStudent(student) : null;
}
function createDevStudent(input) {
    const created = {
        id: (0, crypto_1.randomUUID)(),
        enrollment_date: new Date().toISOString().split('T')[0],
        status: input.status ?? 'active',
        ...input,
    };
    students.unshift(created);
    return decorateStudent(created);
}
function updateDevStudent(id, input) {
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
function deleteDevStudent(id) {
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
function listDevActivityLogs(params) {
    let data = [...activityLogs];
    if (params.student_id) {
        data = data.filter((item) => item.student_id === params.student_id);
    }
    if (params.log_date) {
        data = data.filter((item) => item.log_date === params.log_date);
    }
    if (params.from_date) {
        data = data.filter((item) => item.log_date >= params.from_date);
    }
    if (params.to_date) {
        data = data.filter((item) => item.log_date <= params.to_date);
    }
    data.sort((left, right) => {
        if (left.log_date !== right.log_date) {
            return right.log_date.localeCompare(left.log_date);
        }
        return left.activity_id.localeCompare(right.activity_id);
    });
    return data.map(decorateActivityLog);
}
function createDevActivityLog(input) {
    const rating = ratings.find((item) => item.id === input.rating_id);
    if (!rating) {
        throw new Error('Rating not found');
    }
    const existingIndex = activityLogs.findIndex((item) => item.student_id === input.student_id &&
        item.activity_id === input.activity_id &&
        item.log_date === input.log_date);
    const record = {
        id: existingIndex >= 0 ? activityLogs[existingIndex].id : (0, crypto_1.randomUUID)(),
        ...input,
        marks_earned: rating.marks,
    };
    if (existingIndex >= 0) {
        activityLogs[existingIndex] = record;
    }
    else {
        activityLogs.push(record);
    }
    return decorateActivityLog(record);
}
function updateDevActivityLog(id, input) {
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
function deleteDevActivityLog(id) {
    const index = activityLogs.findIndex((item) => item.id === id);
    if (index === -1) {
        return false;
    }
    activityLogs.splice(index, 1);
    return true;
}
function listDevTeacherRemarks(params) {
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
function createDevTeacherRemark(input) {
    const created = {
        id: (0, crypto_1.randomUUID)(),
        teacher_id: input.teacher_id,
        student_id: input.student_id,
        remark: input.remark,
        created_at: new Date().toISOString(),
    };
    teacherRemarks.push(created);
    return listDevTeacherRemarks({ limit: 1, teacher_id: undefined, student_id: undefined }).find((item) => item.id === created.id);
}
function getDevAuthUserByPhone(phone) {
    return authUsers.find((item) => item.phone === phone) ?? null;
}
function getDevAuthUserById(id) {
    return authUsers.find((item) => item.id === id) ?? null;
}
function upsertDevDeviceToken(input) {
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
function deleteDevDeviceToken(profileId, token) {
    const index = deviceTokens.findIndex((item) => item.profile_id === profileId && item.device_token === token);
    if (index === -1) {
        return false;
    }
    deviceTokens.splice(index, 1);
    return true;
}
function listDevDeviceTokens(params) {
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
function getDevStudentProfilePhoto(studentId) {
    return devStudentProfilePhotos.get(studentId) ?? null;
}
function setDevStudentProfilePhoto(studentId, photoUrl) {
    devStudentProfilePhotos.set(studentId, photoUrl);
    return photoUrl;
}
function listDevBadges(status) {
    return badges
        .filter((item) => !status || item.status === status)
        .sort((left, right) => right.created_at.localeCompare(left.created_at));
}
function createDevBadge(input) {
    const created = {
        id: (0, crypto_1.randomUUID)(),
        created_at: new Date().toISOString(),
        ...input,
    };
    badges.unshift(created);
    return created;
}
function updateDevBadge(id, input) {
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
function deleteDevBadge(id) {
    const index = badges.findIndex((item) => item.id === id);
    if (index === -1) {
        return false;
    }
    badges.splice(index, 1);
    return true;
}
function listDevNotifications(params) {
    let data = [...notifications];
    if (params.target_type) {
        data = data.filter((item) => item.target_type === params.target_type);
    }
    if (params.target_id) {
        data = data.filter((item) => item.target_id === params.target_id);
    }
    return data.sort((left, right) => right.created_at.localeCompare(left.created_at));
}
function createDevNotification(input) {
    const created = {
        id: (0, crypto_1.randomUUID)(),
        created_at: new Date().toISOString(),
        sent_at: input.scheduled_at ? null : new Date().toISOString(),
        ...input,
    };
    notifications.unshift(created);
    return created;
}
function updateDevNotification(id, input) {
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
function deleteDevNotification(id) {
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
function listDevStudentBadges(studentId) {
    const assignments = studentBadges.filter((item) => !studentId || item.student_id === studentId);
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
        .filter((item) => item != null)
        .sort((left, right) => right.earned_at.localeCompare(left.earned_at));
}
