-- Migration: 20260315190000_increase_admission_no_length
-- admission_no VARCHAR(50) can overflow for long school codes + names. Increase to 100.

ALTER TABLE "students" ALTER COLUMN "admission_no" TYPE VARCHAR(100);
