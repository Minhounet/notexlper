-- =============================================================================
-- NOTEXLPER - Seed Data
-- Run this once after applying migrations to populate initial actors.
-- Matches the two actors seeded by FakeActorDataSource in dev mode.
-- =============================================================================

INSERT INTO actors (id, name, color_value) VALUES
  ('a1000000-0000-0000-0000-000000000001', 'Me',    4278190318),  -- 0xFF6200EE deep purple
  ('a1000000-0000-0000-0000-000000000002', 'Alice', 4279568582)   -- 0xFF03DAC6 teal
ON CONFLICT (id) DO NOTHING;
