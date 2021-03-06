-- Clean up
DROP TABLE IF EXISTS counter_table;
DROP FUNCTION IF EXISTS increment_counter(); 
DROP FUNCTION IF EXISTS test_increment();

-- The objects being tested
CREATE TABLE counter_table(counter int);
CREATE FUNCTION increment_counter() RETURNS void AS 
$$
BEGIN
  INSERT INTO counter_table SELECT count(*) FROM counter_table;
END;
$$
LANGUAGE plpgsql;

-- Test function
CREATE FUNCTION test_increment() RETURNS boolean AS 
$$
DECLARE
  c int; m int;
BEGIN
  RAISE NOTICE '1..2';
  -- Separate test scenario from testing environment
  BEGIN
    -- Test 1. Call increment function
    BEGIN
      PERFORM increment_counter();
      RAISE NOTICE 'ok 1 - Call increment function';
    EXCEPTION WHEN OTHERS THEN 
      RAISE NOTICE 'not ok 1 - Call increment function';
    END;
    -- Test 2. Test results
    BEGIN
      SELECT COUNT(*), MAX(counter) INTO c, m FROM counter_table; 
      IF NOT (c = 1 AND m = 0) THEN RAISE EXCEPTION 'Test 2: wrong values in output data'; END IF;
      RAISE NOTICE 'ok 2 - Check first record';
    EXCEPTION WHEN OTHERS THEN 
      RAISE NOTICE 'not ok 2 - Check first record';
    END;
    -- Rollback changes made by the test
    RAISE EXCEPTION 'Rollback test data';
  EXCEPTION 
    WHEN raise_exception THEN RETURN true;
    WHEN OTHERS THEN RETURN false;
  END;
END;
$$
LANGUAGE plpgsql;

-- Run test (success expected)
SELECT test_increment();

-- Refactor the table
ALTER TABLE counter_table add insert_time timestamp with time zone NOT NULL;

-- Run test (fail expected)
SELECT test_increment();

-- Refactor the function
CREATE OR REPLACE FUNCTION increment_counter() RETURNS void AS 
$$
BEGIN
  INSERT INTO counter_table SELECT count(*), now() FROM counter_table;
END;
$$
LANGUAGE plpgsql;

-- Run test (success expected)
SELECT test_increment();