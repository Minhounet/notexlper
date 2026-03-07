-- =============================================================================
-- NOTEXLPER - Add Workspaces
-- =============================================================================
-- A workspace groups actors who collaborate on the same notes.
-- Each actor who creates an account gets a personal workspace by default.
-- They can invite others to their workspace via the app.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- workspaces
-- Owned by one actor; other actors may be members via workspace_members.
-- ---------------------------------------------------------------------------
CREATE TABLE workspaces (
  id         UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT  NOT NULL,
  owner_id   UUID  REFERENCES actors(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- workspace_members
-- Junction table linking actors to workspaces (many-to-many).
-- The owner is also stored here for uniform membership queries.
-- ---------------------------------------------------------------------------
CREATE TABLE workspace_members (
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  actor_id     UUID NOT NULL REFERENCES actors(id)     ON DELETE CASCADE,
  joined_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (workspace_id, actor_id)
);

CREATE INDEX idx_workspace_members_actor_id ON workspace_members(actor_id);

-- =============================================================================
-- Row Level Security
-- =============================================================================

ALTER TABLE workspaces        ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_members ENABLE ROW LEVEL SECURITY;

-- Permissive policies - open access until Supabase Auth is wired up.
CREATE POLICY "allow_all" ON workspaces        FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON workspace_members FOR ALL USING (true) WITH CHECK (true);
