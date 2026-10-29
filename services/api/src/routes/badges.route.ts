import { Router } from 'express';
import { z } from 'zod';

import {
  createDevBadge,
  deleteDevBadge,
  listDevBadges,
  shouldUseLocalData,
  updateDevBadge,
} from '../dev-data';
import { supabaseAdmin } from '../integrations';
import {
  CreateBadgeSchema,
  ListBadgesQuerySchema,
  UpdateBadgeSchema,
} from '../schemas/badge.schema';

const router = Router();
const BADGE_SELECT =
  'id, name, name_ml, description, icon, criteria, bonus_points, status, created_at, updated_at';

// ─────────────────────────────────────────────────────────────────
// Badge Management (Admin & Public Read)
// ─────────────────────────────────────────────────────────────────

router.get('/', async (req, res) => {
  const query = ListBadgesQuerySchema.parse(req.query);
  const role = req.header('x-alif-role') || 'student';

  try {
    let request = supabaseAdmin.from('badges').select(BADGE_SELECT).order('created_at', {
      ascending: false,
    });

    if (query.status) {
      request = request.eq('status', query.status);
    } else if (role !== 'admin') {
      // Non-admins only see active badges
      request = request.eq('status', 'active');
    }

    const { data, error } = await request;

    if (error) {
      if (shouldUseLocalData(error)) {
        res.json(listDevBadges(query.status));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      res.json(listDevBadges(query.status));
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to fetch badges';
    res.status(500).json({ error: msg });
  }
});

// Get single badge with rules
router.get('/:id', async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('badges')
      .select(`
        ${BADGE_SELECT},
        badge_award_rules(id, rule_type, rule_config, is_active)
      `)
      .eq('id', req.params.id)
      .maybeSingle();

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    if (!data) {
      res.status(404).json({ error: 'Badge not found' });
      return;
    }

    res.json(data);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch badge';
    res.status(500).json({ error: msg });
  }
});

router.post('/', async (req, res) => {
  try {
    const role = req.header('x-alif-role') || 'admin';
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const body = CreateBadgeSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('badges')
      .insert([body])
      .select(BADGE_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        res.status(201).json(createDevBadge(body));
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json(data);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = CreateBadgeSchema.parse(req.body);
      res.status(201).json(createDevBadge(body));
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to create badge';
    res.status(400).json({ error: msg });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const role = req.header('x-alif-role') || 'admin';
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const body = UpdateBadgeSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('badges')
      .update(body)
      .eq('id', req.params.id)
      .select(BADGE_SELECT)
      .single();

    if (error) {
      if (shouldUseLocalData(error)) {
        const updated = updateDevBadge(req.params.id, body);
        if (!updated) {
          res.status(404).json({ error: 'Badge not found' });
          return;
        }

        res.json(updated);
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data);
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const body = UpdateBadgeSchema.parse(req.body);
      const updated = updateDevBadge(req.params.id, body);
      if (!updated) {
        res.status(404).json({ error: 'Badge not found' });
        return;
      }

      res.json(updated);
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to update badge';
    res.status(400).json({ error: msg });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const role = req.header('x-alif-role') || 'admin';
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const { error } = await supabaseAdmin.from('badges').delete().eq('id', req.params.id);

    if (error) {
      if (shouldUseLocalData(error)) {
        const deleted = deleteDevBadge(req.params.id);
        if (!deleted) {
          res.status(404).json({ error: 'Badge not found' });
          return;
        }

        res.status(204).send();
        return;
      }

      res.status(400).json({ error: error.message });
      return;
    }

    res.status(204).send();
  } catch (err) {
    if (shouldUseLocalData(err)) {
      const deleted = deleteDevBadge(req.params.id);
      if (!deleted) {
        res.status(404).json({ error: 'Badge not found' });
        return;
      }

      res.status(204).send();
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to delete badge';
    res.status(500).json({ error: msg });
  }
});

// ─────────────────────────────────────────────────────────────────
// Badge Award Rules Management (Admin Only)
// ─────────────────────────────────────────────────────────────────

const CreateRuleSchema = z.object({
  badge_id: z.string().uuid(),
  rule_type: z.enum(['activity_count', 'total_marks', 'activity_streak', 'first_completion']),
  rule_config: z.record(z.any()),
  is_active: z.boolean().optional(),
});

const UpdateRuleSchema = CreateRuleSchema.partial();

router.get('/:badgeId/rules', async (req, res) => {
  try {
    const role = req.header('x-alif-role') || 'admin';
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('badge_award_rules')
      .select('id, rule_type, rule_config, is_active, created_at')
      .eq('badge_id', req.params.badgeId)
      .order('created_at', { ascending: false });

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch rules';
    res.status(500).json({ error: msg });
  }
});

router.post('/:badgeId/rules', async (req, res) => {
  try {
    const role = req.header('x-alif-role') || 'admin';
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const body = CreateRuleSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('badge_award_rules')
      .insert([body])
      .select('id, rule_type, rule_config, is_active, created_at')
      .single();

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json(data);
  } catch (err) {
    if (err instanceof z.ZodError) {
      res.status(400).json({ error: 'Invalid request body', details: err.errors });
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to create rule';
    res.status(500).json({ error: msg });
  }
});

router.put('/:badgeId/rules/:ruleId', async (req, res) => {
  try {
    const role = req.header('x-alif-role') || 'admin';
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const body = UpdateRuleSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('badge_award_rules')
      .update(body)
      .eq('id', req.params.ruleId)
      .eq('badge_id', req.params.badgeId)
      .select('id, rule_type, rule_config, is_active, created_at')
      .single();

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data);
  } catch (err) {
    if (err instanceof z.ZodError) {
      res.status(400).json({ error: 'Invalid request body', details: err.errors });
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to update rule';
    res.status(500).json({ error: msg });
  }
});

router.delete('/:badgeId/rules/:ruleId', async (req, res) => {
  try {
    const role = req.header('x-alif-role') || 'admin';
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const { error } = await supabaseAdmin
      .from('badge_award_rules')
      .delete()
      .eq('id', req.params.ruleId)
      .eq('badge_id', req.params.badgeId);

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    res.status(204).send();
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to delete rule';
    res.status(500).json({ error: msg });
  }
});

// ─────────────────────────────────────────────────────────────────
// Student Badge Endpoints
// ─────────────────────────────────────────────────────────────────

// Get badges earned by a student
router.get('/student/:studentId/earned', async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('student_badges')
      .select(`
        id,
        earned_at,
        awarded_by,
        awarded_reason,
        badges(${BADGE_SELECT})
      `)
      .eq('student_id', req.params.studentId)
      .order('earned_at', { ascending: false });

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    res.json(
      (data || []).map((sb: any) => ({
        ...sb.badges,
        earned_at: sb.earned_at,
        awarded_by: sb.awarded_by,
        awarded_reason: sb.awarded_reason,
      }))
    );
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch earned badges';
    res.status(500).json({ error: msg });
  }
});

// Get available badges (not yet earned)
router.get('/student/:studentId/available', async (req, res) => {
  try {
    // Get all active badges
    const { data: allBadges, error: badgesError } = await supabaseAdmin
      .from('badges')
      .select('id')
      .eq('status', 'active');

    if (badgesError) {
      res.status(400).json({ error: badgesError.message });
      return;
    }

    // Get earned badges
    const { data: earnedBadges, error: earnedError } = await supabaseAdmin
      .from('student_badges')
      .select('badge_id')
      .eq('student_id', req.params.studentId);

    if (earnedError) {
      res.status(400).json({ error: earnedError.message });
      return;
    }

    const earnedIds = new Set((earnedBadges || []).map((b: any) => b.badge_id));
    const availableIds = (allBadges || [])
      .map((b: any) => b.id)
      .filter((id) => !earnedIds.has(id));

    if (availableIds.length === 0) {
      res.json([]);
      return;
    }

    // Get details of available badges
    const { data, error } = await supabaseAdmin
      .from('badges')
      .select(BADGE_SELECT)
      .in('id', availableIds);

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    res.json(data || []);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to fetch available badges';
    res.status(500).json({ error: msg });
  }
});

// Award badge to student (admin only)
router.post('/student/:studentId/award', async (req, res) => {
  try {
    const role = req.header('x-alif-role') || 'admin';
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const { badge_id, reason } = z
      .object({
        badge_id: z.string().uuid(),
        reason: z.string().optional(),
      })
      .parse(req.body);

    // Check if already awarded
    const { data: existing } = await supabaseAdmin
      .from('student_badges')
      .select('id')
      .eq('student_id', req.params.studentId)
      .eq('badge_id', badge_id)
      .maybeSingle();

    if (existing) {
      res.status(409).json({ error: 'Badge already earned by this student' });
      return;
    }

    // Award badge
    const { data, error } = await supabaseAdmin
      .from('student_badges')
      .insert([
        {
          student_id: req.params.studentId,
          badge_id,
          awarded_by: 'admin',
          awarded_reason: reason,
        },
      ])
      .select()
      .single();

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    res.status(201).json(data);
  } catch (err) {
    if (err instanceof z.ZodError) {
      res.status(400).json({ error: 'Invalid request body', details: err.errors });
      return;
    }

    const msg = err instanceof Error ? err.message : 'Failed to award badge';
    res.status(500).json({ error: msg });
  }
});

// Remove badge from student (admin only)
router.delete('/student/:studentId/badges/:badgeId', async (req, res) => {
  try {
    const role = req.header('x-alif-role') || 'admin';
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin role required' });
      return;
    }

    const { error } = await supabaseAdmin
      .from('student_badges')
      .delete()
      .eq('student_id', req.params.studentId)
      .eq('badge_id', req.params.badgeId);

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    res.status(204).send();
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to remove badge';
    res.status(500).json({ error: msg });
  }
});

export default router;
