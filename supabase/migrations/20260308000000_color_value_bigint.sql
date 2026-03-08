-- =============================================================================
-- NOTEXLPER - Fix color_value column type overflow
-- =============================================================================
-- Flutter color values are 32-bit unsigned integers (0xFF______).
-- The upper half of that range exceeds PostgreSQL INTEGER max (2,147,483,647),
-- causing a "value is out of range for type integer" error.
-- Widening to BIGINT fixes the overflow.
-- =============================================================================

ALTER TABLE actors     ALTER COLUMN color_value TYPE BIGINT;
ALTER TABLE categories ALTER COLUMN color_value TYPE BIGINT;
