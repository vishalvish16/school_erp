-- Migration: 20260317100000_fix_fee_structures_legacy_columns
-- Makes legacy columns nullable so new fee structure inserts (using academic_year, fee_head, amount)
-- don't fail with NOT NULL violations on academic_year_id and total_amount.
-- Also allows class_id to be null for school-wide fee structures.

-- Drop NOT NULL on legacy columns (preserve_data added academic_year, fee_head, amount, frequency)
ALTER TABLE "fee_structures" ALTER COLUMN "academic_year_id" DROP NOT NULL;
ALTER TABLE "fee_structures" ALTER COLUMN "total_amount" DROP NOT NULL;

-- Allow class_id to be null for school-wide fee structures
ALTER TABLE "fee_structures" ALTER COLUMN "class_id" DROP NOT NULL;
