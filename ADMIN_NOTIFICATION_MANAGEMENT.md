# Admin Notification Management

## Overview

Admin Notification Management allows administrators to:
- **Send immediate notifications** to all users or targeted groups
- **Schedule notifications** for future delivery
- **Set up recurring notifications** for daily, weekly, or monthly reminders
- **Target audiences** by batch, class, or individual student
- **Manage notification history** and view delivery status

---

## Notification Endpoints

### Send Immediate Notification
```
POST /api/notifications
```

**Headers:**
```
x-alif-role: admin
Content-Type: application/json
```

**Body:**
```json
{
  "title": "Batch Meeting Tomorrow",
  "body": "Don't forget the batch meeting at 10 AM",
  "target_type": "batch",
  "target_id": "batch-uuid"
}
```

**Target Types:**
- `all` - Send to all users
- `batch` - Send to specific batch (requires target_id)
- `class` - Send to specific class (requires target_id)
- `student` - Send to specific student (requires target_id)

**Response:**
```json
{
  "id": "notification-uuid",
  "title": "Batch Meeting Tomorrow",
  "body": "Don't forget the batch meeting at 10 AM",
  "target_type": "batch",
  "target_id": "batch-uuid",
  "sent_at": "2026-06-17T15:45:00Z",
  "created_at": "2026-06-17T15:45:00Z"
}
```

---

### Schedule Notification for Later
```
POST /api/notifications/reminders
```

**Headers:**
```
x-alif-role: admin
Content-Type: application/json
```

**Body:**
```json
{
  "title": "Weekly Batch Reminder",
  "body": "Your weekly batch report is ready",
  "target_type": "all",
  "scheduled_at": "2026-06-24T08:00:00Z",
  "frequency": null
}
```

**Response:**
```json
{
  "id": "reminder-uuid",
  "title": "Weekly Batch Reminder",
  "body": "Your weekly batch report is ready",
  "target_type": "all",
  "scheduled_at": "2026-06-24T08:00:00Z",
  "frequency": null,
  "is_active": true,
  "created_at": "2026-06-17T15:45:00Z"
}
```

---

### Set Up Recurring Notification
```
POST /api/notifications/reminders
```

**Headers:**
```
x-alif-role: admin
Content-Type: application/json
```

**Body:**
```json
{
  "title": "Daily Attendance Reminder",
  "body": "Mark attendance for your students",
  "target_type": "batch",
  "target_id": "batch-uuid",
  "scheduled_at": "2026-06-18T08:00:00Z",
  "frequency": "daily"
}
```

**Frequency Options:**
- `daily` - Repeats every day at the same time
- `weekly` - Repeats every week on the same day at the same time
- `monthly` - Repeats every month on the same date at the same time

**Response:**
```json
{
  "id": "reminder-uuid",
  "title": "Daily Attendance Reminder",
  "body": "Mark attendance for your students",
  "target_type": "batch",
  "target_id": "batch-uuid",
  "scheduled_at": "2026-06-18T08:00:00Z",
  "frequency": "daily",
  "is_active": true,
  "last_sent_at": null,
  "created_at": "2026-06-17T15:45:00Z"
}
```

---

### List Notifications
```
GET /api/notifications
```

**Headers:**
```
x-alif-role: admin
```

**Query Parameters:**
- `target_type` (optional): Filter by `all`, `batch`, `class`, or `student`
- `target_id` (optional): Filter by specific target ID

**Response:**
```json
[
  {
    "id": "notification-uuid",
    "title": "Batch Meeting Tomorrow",
    "body": "Don't forget the batch meeting at 10 AM",
    "target_type": "batch",
    "target_id": "batch-uuid",
    "sent_at": "2026-06-17T15:45:00Z",
    "created_at": "2026-06-17T15:45:00Z"
  },
  {
    "id": "reminder-uuid",
    "title": "Daily Attendance Reminder",
    "body": "Mark attendance for your students",
    "target_type": "batch",
    "target_id": "batch-uuid",
    "scheduled_at": "2026-06-18T08:00:00Z",
    "frequency": "daily",
    "is_active": true,
    "last_sent_at": "2026-06-17T08:00:00Z",
    "created_at": "2026-06-17T15:45:00Z"
  }
]
```

---

### Update Recurring Notification
```
PUT /api/notifications/reminders/{reminderId}
```

**Headers:**
```
x-alif-role: admin
Content-Type: application/json
```

**Body:** (all fields optional)
```json
{
  "title": "Updated Title",
  "body": "Updated message",
  "is_active": false
}
```

---

### Delete Notification/Reminder
```
DELETE /api/notifications/{notificationId}
```

**Headers:**
```
x-alif-role: admin
```

---

### Get Notification Statistics
```
GET /api/notifications/stats
```

**Headers:**
```
x-alif-role: admin
```

**Response:**
```json
{
  "total_sent": 1234,
  "total_scheduled": 45,
  "total_recurring": 12,
  "by_target_type": {
    "all": 500,
    "batch": 400,
    "class": 250,
    "student": 84
  }
}
```

---

## Device Token Management

### Register Device for Notifications
```
POST /api/device-tokens
```

**Body:**
```json
{
  "device_token": "firebase-device-token",
  "device_type": "android",
  "device_id": "unique-device-id"
}
```

**Response:**
```json
{
  "id": "device-token-uuid",
  "device_token": "firebase-device-token",
  "device_type": "android",
  "device_id": "unique-device-id",
  "is_active": true,
  "created_at": "2026-06-17T15:45:00Z"
}
```

---

### List Registered Devices
```
GET /api/device-tokens
```

**Response:**
```json
[
  {
    "id": "device-token-uuid",
    "device_type": "android",
    "device_id": "unique-device-id",
    "is_active": true,
    "created_at": "2026-06-17T15:45:00Z"
  }
]
```

---

### Update Device Preference
```
PUT /api/device-tokens/{deviceTokenId}/preference
```

**Body:**
```json
{
  "notification_type": "reminders",
  "is_enabled": true
}
```

**Response:**
```json
{
  "id": "preference-uuid",
  "device_token_id": "device-token-uuid",
  "notification_type": "reminders",
  "is_enabled": true,
  "updated_at": "2026-06-17T16:00:00Z"
}
```

---

## Best Practices

### 1. Targeting Strategies

**Broadcast to All Users**
```bash
curl -X POST http://localhost:4000/api/notifications \
  -H "x-alif-role: admin" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "System Maintenance",
    "body": "Server maintenance scheduled for tonight",
    "target_type": "all"
  }'
```

**Target Specific Batch**
```bash
curl -X POST http://localhost:4000/api/notifications \
  -H "x-alif-role: admin" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Batch News",
    "body": "Important update for Batch 2026",
    "target_type": "batch",
    "target_id": "batch-uuid"
  }'
```

---

### 2. Scheduling Strategies

**Schedule for Specific Time**
```bash
curl -X POST http://localhost:4000/api/notifications/reminders \
  -H "x-alif-role: admin" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Monthly Review",
    "body": "Time to review your progress",
    "target_type": "all",
    "scheduled_at": "2026-06-30T18:00:00Z"
  }'
```

**Daily Reminder at 8 AM**
```bash
curl -X POST http://localhost:4000/api/notifications/reminders \
  -H "x-alif-role: admin" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Daily Standup",
    "body": "Don't forget your daily standup",
    "target_type": "batch",
    "target_id": "batch-uuid",
    "scheduled_at": "2026-06-18T08:00:00Z",
    "frequency": "daily"
  }'
```

**Weekly Report Every Monday**
```bash
curl -X POST http://localhost:4000/api/notifications/reminders \
  -H "x-alif-role: admin" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Weekly Report",
    "body": "Your weekly performance report is ready",
    "target_type": "all",
    "scheduled_at": "2026-06-23T09:00:00Z",
    "frequency": "weekly"
  }'
```

---

### 3. Notification Preferences

Users can control which types of notifications they receive:
- Classroom announcements
- Assignment reminders
- Progress reports
- System notifications
- Promotional messages

---

## Error Responses

### Admin Role Required
```json
{
  "error": "Admin role required"
}
```
Status: `403`

### Notification Not Found
```json
{
  "error": "Notification not found"
}
```
Status: `404`

### Invalid Target
```json
{
  "error": "Invalid target type. Must be 'all', 'batch', 'class', or 'student'"
}
```
Status: `400`

### Missing Required Field
```json
{
  "error": "Title is required"
}
```
Status: `400`

---

## Implementation Details

### Notification Delivery Flow

1. **Admin creates notification** via API
2. **If immediate**: Notification is sent to registered device tokens immediately
3. **If scheduled**: Notification is stored and scheduled via cron job
4. **Scheduler triggers**: Reminder is sent at scheduled time
5. **Device receives notification**: Firebase Cloud Messaging delivers to client
6. **User sees notification**: Notification appears in app notification center

### Retry Strategy

- Failed deliveries are retried up to 3 times
- Retry delays: 1 minute, 5 minutes, 15 minutes
- After 3 failures, notification is marked as failed
- Admin is notified of delivery failures

### Rate Limiting

- Maximum 100 notifications per minute per admin
- Maximum 1000 notifications per hour per admin
- Batch operations are rate-limited to prevent abuse

---

## Database Schema

### Notifications Table
- `id` - UUID primary key
- `title` - Notification title
- `body` - Notification body (optional)
- `target_type` - `all`, `batch`, `class`, or `student`
- `target_id` - UUID of specific target (if not `all`)
- `sent_at` - When notification was sent (if immediate)
- `created_at`, `updated_at` - Timestamps

### Reminders Table
- `id` - UUID primary key
- `title` - Reminder title
- `body` - Reminder body (optional)
- `target_type` - `all`, `batch`, `class`, or `student`
- `target_id` - UUID of specific target (if not `all`)
- `scheduled_at` - When to send/first send
- `frequency` - `daily`, `weekly`, `monthly`, or null (one-time)
- `is_active` - Whether reminder is active
- `last_sent_at` - Last time notification was sent
- `created_at`, `updated_at` - Timestamps

### Device Tokens Table
- `id` - UUID primary key
- `user_id` - FK to users
- `device_token` - Firebase token
- `device_type` - `ios`, `android`, `web`
- `device_id` - Unique device identifier
- `is_active` - Whether token is active
- `created_at`, `updated_at` - Timestamps

### Notification Preferences Table
- `id` - UUID primary key
- `user_id` - FK to users (or device_token_id)
- `notification_type` - Type of notification
- `is_enabled` - Whether notifications of this type are enabled
- `updated_at` - Last update time

---

## Security

### Role-Based Access Control
- Only admins can create/update/delete notifications
- Students can view reminders targeted to them
- Parents can view reminders for their children

### Rate Limiting
- Prevents notification spam
- Limits notification creation per admin
- Protects against abuse

### RLS Policies
- Reminders are visible only to intended recipients
- Admins can see all notifications
- Non-admins see only reminders they're targeted with

---

## Future Enhancements

- Notification templates for common scenarios
- Scheduled bulk operations (import from CSV)
- A/B testing for notification content
- Delivery analytics and performance metrics
- Rich media support (images, videos)
- Deep linking to specific app screens
- Localization support (multiple languages)
