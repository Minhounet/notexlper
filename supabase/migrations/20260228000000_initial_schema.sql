-- =============================================================================
-- NOTEXLPER - Initial Schema
-- =============================================================================
-- NOTE: RLS is enabled on all tables but policies are permissive for now.
-- Authentication is actor-based at the app level (no Supabase Auth yet).
-- Policies should be tightened when Supabase Auth is introduced.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- actors
-- Represents a person in the workspace who can create or be assigned to notes.
-- ---------------------------------------------------------------------------
CREATE TABLE actors (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT        NOT NULL,
  color_value INTEGER     NOT NULL
);

-- ---------------------------------------------------------------------------
-- categories
-- Used to group checklist items within a note.
-- ---------------------------------------------------------------------------
CREATE TABLE categories (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT        NOT NULL,
  color_value INTEGER     NOT NULL
);

-- ---------------------------------------------------------------------------
-- reminders
-- One-to-one with checklist_notes (a note may have one reminder).
-- ---------------------------------------------------------------------------
CREATE TABLE reminders (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  date_time   TIMESTAMPTZ NOT NULL,
  frequency   TEXT        NOT NULL DEFAULT 'once'
                CHECK (frequency IN ('once', 'daily', 'weekly', 'monthly')),
  is_enabled  BOOLEAN     NOT NULL DEFAULT TRUE
);

-- ---------------------------------------------------------------------------
-- checklist_notes
-- ---------------------------------------------------------------------------
CREATE TABLE checklist_notes (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT        NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_pinned   BOOLEAN     NOT NULL DEFAULT FALSE,
  creator_id  UUID        REFERENCES actors(id)    ON DELETE SET NULL,
  reminder_id UUID        REFERENCES reminders(id) ON DELETE SET NULL
);

-- ---------------------------------------------------------------------------
-- checklist_items
-- Belong to a note; deleted when their note is deleted.
-- ---------------------------------------------------------------------------
CREATE TABLE checklist_items (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id             UUID        NOT NULL REFERENCES checklist_notes(id) ON DELETE CASCADE,
  text                TEXT        NOT NULL,
  is_checked          BOOLEAN     NOT NULL DEFAULT FALSE,
  due_date            TIMESTAMPTZ,
  reminder_date_time  TIMESTAMPTZ,
  "order"             INTEGER     NOT NULL DEFAULT 0,
  category_id         UUID        REFERENCES categories(id) ON DELETE SET NULL
);

CREATE INDEX idx_checklist_items_note_id ON checklist_items(note_id);

-- ---------------------------------------------------------------------------
-- note_assignees
-- Junction table for ChecklistNote.assigneeIds (many actors per note).
-- ---------------------------------------------------------------------------
CREATE TABLE note_assignees (
  note_id   UUID NOT NULL REFERENCES checklist_notes(id) ON DELETE CASCADE,
  actor_id  UUID NOT NULL REFERENCES actors(id)          ON DELETE CASCADE,
  PRIMARY KEY (note_id, actor_id)
);

-- =============================================================================
-- Row Level Security
-- =============================================================================

ALTER TABLE actors          ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories      ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders       ENABLE ROW LEVEL SECURITY;
ALTER TABLE checklist_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_assignees  ENABLE ROW LEVEL SECURITY;

-- Permissive policies - open access until Supabase Auth is wired up.
CREATE POLICY "allow_all" ON actors          FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON categories      FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON reminders       FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON checklist_notes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON checklist_items FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON note_assignees  FOR ALL USING (true) WITH CHECK (true);
