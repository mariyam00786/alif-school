# Badge and Achievement Management

## Overview

The badge system allows students to earn achievements based on their activity and performance. Badges can be:
- **Manually awarded** by admins
- **Auto-awarded** based on configurable rules (activity count, marks, streaks, etc.)
- **Viewed** by students and parents
- **Tracked** with award history

---

## Badge Endpoints

### List All Badges
```
GET /api/badges
```

**Query Parameters:**
- `status` (optional): `active` | `inactive` - Filter by status (non-admins see only active)

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Ace Student",
    "name_ml": "വിദ്യാർത്ഥി സാധു",
    "description": "Earned 100+ marks in a week",
    "icon": "🌟",
    "criteria": {...},
    "bonus_points": 50,
    "status": "active",
    "created_at": "2026-06-17T10:00:00Z"
  }
]
```

---

### Get Single Badge with Rules
```
GET /api/badges/{badgeId}
```

**Response:**
```json
{
  "id": "uuid",
  "name": "Ace Student",
  "description": "Earned 100+ marks in a week",
  "bonus_points": 50,
  "status": "active",
  "badge_award_rules": [
    {
      "id": "uuid",
      "rule_type": "total_marks",
      "rule_config": {
        "threshold": 100,
        "period": "weekly"
      },
      "is_active": true
    }
  ]
}
```

---

### Create Badge (Admin Only)
```
POST /api/badges
```

**Headers:**
```
x-alif-role: admin
```

**Body:**
```json
{
  "name": "Ace Student",
  "name_ml": "വിദ്യാർത്ഥി സാധു",
  "description": "Earned 100+ marks in a week",
  "icon": "🌟",
  "bonus_points": 50,
  "status": "active"
}
```

---

### Update Badge (Admin Only)
```
PUT /api/badges/{badgeId}
```

**Headers:**
```
x-alif-role: admin
```

**Body:** (all fields optional)
```json
{
  "name": "Updated Badge Name",
  "status": "inactive"
}
```

---

### Delete Badge (Admin Only)
```
DELETE /api/badges/{badgeId}
```

**Headers:**
```
x-alif-role: admin
```

---

## Badge Award Rules

### Create Award Rule
```
POST /api/badges/{badgeId}/rules
```

**Headers:**
```
x-alif-role: admin
```

**Rule Types and Configurations:**

#### 1. Activity Count Rule
```json
{
  "rule_type": "activity_count",
  "rule_config": {
    "threshold": 10,
    "period": "daily"
  },
  "is_active": true
}
```
Grants badge when student completes N activities in the specified period.

#### 2. Total Marks Rule
```json
{
  "rule_type": "total_marks",
  "rule_config": {
    "threshold": 100,
    "period": "weekly"
  },
  "is_active": true
}
```
Grants badge when student earns N marks in the specified period.

#### 3. Activity Streak Rule
```json
{
  "rule_type": "activity_streak",
  "rule_config": {
    "days": 7,
    "min_daily_activities": 2
  },
  "is_active": true
}
```
Grants badge for completing activities N days in a row.

#### 4. First Completion Rule
```json
{
  "rule_type": "first_completion",
  "rule_config": {
    "activity_id": "uuid"
  },
  "is_active": true
}
```
Grants badge on first completion of a specific activity.

---

### List Rules for Badge
```
GET /api/badges/{badgeId}/rules
```

**Headers:**
```
x-alif-role: admin
```

**Response:**
```json
[
  {
    "id": "uuid",
    "rule_type": "total_marks",
    "rule_config": {...},
    "is_active": true,
    "created_at": "2026-06-17T10:00:00Z"
  }
]
```

---

### Update Rule
```
PUT /api/badges/{badgeId}/rules/{ruleId}
```

**Headers:**
```
x-alif-role: admin
```

**Body:** (all fields optional)
```json
{
  "is_active": false
}
```

---

### Delete Rule
```
DELETE /api/badges/{badgeId}/rules/{ruleId}
```

**Headers:**
```
x-alif-role: admin
```

---

## Student Badge Endpoints

### Get Earned Badges (Student)
```
GET /api/badges/student/{studentId}/earned
```

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Ace Student",
    "description": "Earned 100+ marks in a week",
    "icon": "🌟",
    "bonus_points": 50,
    "earned_at": "2026-06-15T14:30:00Z",
    "awarded_by": "auto",
    "awarded_reason": "Total marks exceeded 100"
  }
]
```

---

### Get Available Badges (Student)
```
GET /api/badges/student/{studentId}/available
```

Returns all active badges that the student hasn't earned yet.

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Consistency Master",
    "description": "7-day activity streak",
    "icon": "📅",
    "bonus_points": 75
  }
]
```

---

### Award Badge to Student (Admin Only)
```
POST /api/badges/student/{studentId}/award
```

**Headers:**
```
x-alif-role: admin
```

**Body:**
```json
{
  "badge_id": "uuid",
  "reason": "Outstanding performance in mathematics"
}
```

**Response:**
```json
{
  "id": "uuid",
  "student_id": "uuid",
  "badge_id": "uuid",
  "earned_at": "2026-06-17T15:45:00Z",
  "awarded_by": "admin",
  "awarded_reason": "Outstanding performance in mathematics"
}
```

---

### Remove Badge from Student (Admin Only)
```
DELETE /api/badges/student/{studentId}/badges/{badgeId}
```

**Headers:**
```
x-alif-role: admin
```

---

## Badge Statistics

### Get Global Badge Statistics (Admin Only)
```
GET /api/badges/stats/global
```

**Headers:**
```
x-alif-role: admin
```

**Response:**
```json
[
  {
    "badge_id": "uuid",
    "students_earned": 23
  },
  {
    "badge_id": "uuid",
    "students_earned": 15
  }
]
```

---

## Bonus Points

When a student earns a badge, the associated `bonus_points` are automatically added to their account. This can be used for:
- Leaderboard rankings
- Incentive programs
- Special unlocks

---

## Best Practices

1. **Keep rules simple** - One rule per badge is easier to understand
2. **Set realistic thresholds** - Make achievements attainable but challenging
3. **Use meaningful icons** - Emojis work well and are cross-platform
4. **Multilingual support** - Provide both English and Malayalam names
5. **Document criteria** - Make it clear in description how to earn
6. **Monitor adoption** - Use stats endpoint to track which badges are popular
7. **Regular reviews** - Update rules based on student progress patterns

---

## Examples

### Create "7-Day Streak" Badge
```bash
curl -X POST http://localhost:4000/api/badges \
  -H "Content-Type: application/json" \
  -H "x-alif-role: admin" \
  -d '{
    "name": "Consistency Master",
    "description": "7-day activity streak",
    "icon": "📅",
    "bonus_points": 75,
    "status": "active"
  }'
```

Then create the rule:
```bash
curl -X POST http://localhost:4000/api/badges/{badgeId}/rules \
  -H "Content-Type: application/json" \
  -H "x-alif-role: admin" \
  -d '{
    "rule_type": "activity_streak",
    "rule_config": {
      "days": 7,
      "min_daily_activities": 1
    },
    "is_active": true
  }'
```

### Award Badge Manually
```bash
curl -X POST http://localhost:4000/api/badges/student/{studentId}/award \
  -H "Content-Type: application/json" \
  -H "x-alif-role: admin" \
  -d '{
    "badge_id": "{badgeId}",
    "reason": "Excellent participation in class"
  }'
```

### View Student's Earned Badges
```bash
curl http://localhost:4000/api/badges/student/{studentId}/earned
```

---

## Database Schema

### Badges Table
- `id` - UUID primary key
- `name` - Badge name (English)
- `name_ml` - Badge name (Malayalam)
- `description` - Badge description
- `icon` - Emoji or icon representation
- `criteria` - JSONB with criteria details
- `bonus_points` - Points awarded with badge
- `status` - `active` or `inactive`
- `created_at`, `updated_at` - Timestamps

### Student Badges Table
- `id` - UUID primary key
- `student_id` - FK to students
- `badge_id` - FK to badges
- `earned_at` - When badge was earned
- `awarded_by` - `auto` | `admin` | `manual`
- `awarded_reason` - Why badge was awarded
- Unique constraint: (student_id, badge_id)

### Badge Award Rules Table
- `id` - UUID primary key
- `badge_id` - FK to badges
- `rule_type` - Type of rule
- `rule_config` - JSONB with rule parameters
- `is_active` - Whether rule is active
- `created_at`, `updated_at` - Timestamps

---

## Error Responses

### Badge Not Found
```json
{
  "error": "Badge not found"
}
```
Status: `404`

### Already Earned
```json
{
  "error": "Badge already earned by this student"
}
```
Status: `409`

### Admin Required
```json
{
  "error": "Admin role required"
}
```
Status: `403`

### Invalid Data
```json
{
  "error": "Invalid request body",
  "details": [...]
}
```
Status: `400`
