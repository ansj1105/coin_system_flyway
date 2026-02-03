-- Rename display_name -> name if display_name exists and name does not
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'users'
          AND column_name = 'display_name'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'users'
          AND column_name = 'name'
    ) THEN
        ALTER TABLE users RENAME COLUMN display_name TO name;
    END IF;
END $$;
