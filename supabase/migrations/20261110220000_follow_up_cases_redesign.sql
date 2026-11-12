-- Follow-up Feature Redesign: Hierarchical Case Management & Activity Audit History
-- Migration: 20261110220000_follow_up_cases_redesign.sql

-- 1. Create follow_up_cases table
CREATE TABLE IF NOT EXISTS public.follow_up_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
    status TEXT NOT NULL CHECK (status IN ('open', 'assigned', 'in_progress', 'waiting', 'resolved', 'closed')) DEFAULT 'open',
    case_type TEXT NOT NULL DEFAULT 'general',
    created_by UUID NOT NULL REFERENCES public.servant_profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    closed_at TIMESTAMPTZ,
    client_operation_id TEXT
);

-- 2. Create follow_up_case_assignments table (M:N servant assignment with history)
CREATE TABLE IF NOT EXISTS public.follow_up_case_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.follow_up_cases(id) ON DELETE CASCADE,
    servant_id UUID NOT NULL REFERENCES public.servant_profiles(id) ON DELETE CASCADE,
    assigned_by UUID NOT NULL REFERENCES public.servant_profiles(id),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assignment_status TEXT NOT NULL CHECK (assignment_status IN ('active', 'removed', 'completed')) DEFAULT 'active',
    removed_at TIMESTAMPTZ,
    client_operation_id TEXT,
    UNIQUE(case_id, servant_id, assigned_at)
);

-- 3. Create follow_up_activities table (Immutable activity audit trail)
CREATE TABLE IF NOT EXISTS public.follow_up_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.follow_up_cases(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL CHECK (activity_type IN ('call', 'visit', 'message', 'in_person', 'status_change', 'assignment_change', 'note')),
    description TEXT NOT NULL,
    created_by UUID NOT NULL REFERENCES public.servant_profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    activity_date TEXT NOT NULL,
    client_operation_id TEXT
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_follow_up_cases_scope 
    ON public.follow_up_cases(service_id, class_id, status);
CREATE INDEX IF NOT EXISTS idx_follow_up_cases_student 
    ON public.follow_up_cases(student_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_cases_created_by 
    ON public.follow_up_cases(created_by);
CREATE INDEX IF NOT EXISTS idx_follow_up_case_assignments_case 
    ON public.follow_up_case_assignments(case_id, assignment_status);
CREATE INDEX IF NOT EXISTS idx_follow_up_case_assignments_servant 
    ON public.follow_up_case_assignments(servant_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_activities_case 
    ON public.follow_up_activities(case_id, created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.follow_up_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follow_up_case_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follow_up_activities ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES FOR follow_up_cases
-- ============================================================================

-- SELECT: Accessible within user's authorized organizational scope (Class, Stage, Service)
DROP POLICY IF EXISTS follow_up_cases_select ON public.follow_up_cases;
CREATE POLICY follow_up_cases_select ON public.follow_up_cases
    FOR SELECT TO authenticated
    USING (
        (SELECT private.is_super_admin())
        OR (SELECT private.can_access_class(follow_up_cases.class_id))
    );

-- INSERT: Can create case if user can access the student's class and created_by matches their active profile
DROP POLICY IF EXISTS follow_up_cases_insert ON public.follow_up_cases;
CREATE POLICY follow_up_cases_insert ON public.follow_up_cases
    FOR INSERT TO authenticated
    WITH CHECK (
        (SELECT private.is_super_admin())
        OR (
            (SELECT private.can_access_class(follow_up_cases.class_id))
            AND EXISTS (
                SELECT 1 FROM public.servant_profiles sp
                WHERE sp.id = follow_up_cases.created_by
                  AND sp.auth_user_id = (SELECT auth.uid())
                  AND sp.service_id = follow_up_cases.service_id
                  AND sp.account_status = 'active'
            )
        )
    );

-- UPDATE: Leaders have full update capability; Class servants can only update notes/in_progress (cannot resolve/close)
DROP POLICY IF EXISTS follow_up_cases_update ON public.follow_up_cases;
CREATE POLICY follow_up_cases_update ON public.follow_up_cases
    FOR UPDATE TO authenticated
    USING (
        (SELECT private.is_super_admin())
        OR (SELECT private.can_access_class(follow_up_cases.class_id))
    )
    WITH CHECK (
        (SELECT private.is_super_admin())
        OR (
            (SELECT private.can_access_class(follow_up_cases.class_id))
            AND (
                -- Non-leaders cannot set status to resolved or closed
                follow_up_cases.status NOT IN ('resolved', 'closed')
                OR EXISTS (
                    SELECT 1 FROM public.servant_profiles sp
                    WHERE sp.auth_user_id = (SELECT auth.uid())
                      AND sp.service_id = follow_up_cases.service_id
                      AND sp.account_status = 'active'
                      AND sp.role IN (
                          'overall_leader'::public.servant_role,
                          'overall_helper'::public.servant_role,
                          'stage_leader'::public.servant_role,
                          'class_leader'::public.servant_role
                      )
                )
            )
        )
    );

-- ============================================================================
-- RLS POLICIES FOR follow_up_case_assignments
-- ============================================================================

-- SELECT: Accessible if user can access the case's class
DROP POLICY IF EXISTS follow_up_case_assignments_select ON public.follow_up_case_assignments;
CREATE POLICY follow_up_case_assignments_select ON public.follow_up_case_assignments
    FOR SELECT TO authenticated
    USING (
        (SELECT private.is_super_admin())
        OR EXISTS (
            SELECT 1 FROM public.follow_up_cases c
            WHERE c.id = follow_up_case_assignments.case_id
              AND (SELECT private.can_access_class(c.class_id))
        )
    );

-- INSERT: Leaders only (class_leader, stage_leader, overall roles) within their scope
DROP POLICY IF EXISTS follow_up_case_assignments_insert ON public.follow_up_case_assignments;
CREATE POLICY follow_up_case_assignments_insert ON public.follow_up_case_assignments
    FOR INSERT TO authenticated
    WITH CHECK (
        (SELECT private.is_super_admin())
        OR EXISTS (
            SELECT 1 FROM public.follow_up_cases c
            JOIN public.servant_profiles assigner
              ON assigner.auth_user_id = (SELECT auth.uid())
             AND assigner.id = follow_up_case_assignments.assigned_by
             AND assigner.service_id = c.service_id
             AND assigner.account_status = 'active'
            WHERE c.id = follow_up_case_assignments.case_id
              AND (SELECT private.can_access_class(c.class_id))
              AND (
                  assigner.role IN ('overall_leader'::public.servant_role, 'overall_helper'::public.servant_role)
                  OR (assigner.role = 'stage_leader'::public.servant_role AND (SELECT private.can_access_stage(assigner.stage_id)))
                  OR (assigner.role = 'class_leader'::public.servant_role AND assigner.class_id = c.class_id)
              )
        )
    );

-- UPDATE: Leaders only for updating status (e.g. marking removed/completed)
DROP POLICY IF EXISTS follow_up_case_assignments_update ON public.follow_up_case_assignments;
CREATE POLICY follow_up_case_assignments_update ON public.follow_up_case_assignments
    FOR UPDATE TO authenticated
    USING (
        (SELECT private.is_super_admin())
        OR EXISTS (
            SELECT 1 FROM public.follow_up_cases c
            JOIN public.servant_profiles sp
              ON sp.auth_user_id = (SELECT auth.uid())
             AND sp.service_id = c.service_id
             AND sp.account_status = 'active'
            WHERE c.id = follow_up_case_assignments.case_id
              AND (SELECT private.can_access_class(c.class_id))
              AND sp.role IN (
                  'overall_leader'::public.servant_role,
                  'overall_helper'::public.servant_role,
                  'stage_leader'::public.servant_role,
                  'class_leader'::public.servant_role
              )
        )
    );

-- ============================================================================
-- RLS POLICIES FOR follow_up_activities
-- ============================================================================

-- SELECT: Accessible if user can access the case's class
DROP POLICY IF EXISTS follow_up_activities_select ON public.follow_up_activities;
CREATE POLICY follow_up_activities_select ON public.follow_up_activities
    FOR SELECT TO authenticated
    USING (
        (SELECT private.is_super_admin())
        OR EXISTS (
            SELECT 1 FROM public.follow_up_cases c
            WHERE c.id = follow_up_activities.case_id
              AND (SELECT private.can_access_class(c.class_id))
        )
    );

-- INSERT: User who can access the case's class and created_by matches their active profile
DROP POLICY IF EXISTS follow_up_activities_insert ON public.follow_up_activities;
CREATE POLICY follow_up_activities_insert ON public.follow_up_activities
    FOR INSERT TO authenticated
    WITH CHECK (
        (SELECT private.is_super_admin())
        OR EXISTS (
            SELECT 1 FROM public.follow_up_cases c
            JOIN public.servant_profiles sp
              ON sp.auth_user_id = (SELECT auth.uid())
             AND sp.id = follow_up_activities.created_by
             AND sp.service_id = c.service_id
             AND sp.account_status = 'active'
            WHERE c.id = follow_up_activities.case_id
              AND (SELECT private.can_access_class(c.class_id))
        )
    );

-- Activities are an immutable audit trail: no UPDATE or DELETE allowed for normal users

