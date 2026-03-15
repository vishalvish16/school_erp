-- CreateTable (IF NOT EXISTS for idempotency when table was created manually or by prior run)
CREATE TABLE IF NOT EXISTS "school_groups" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" VARCHAR(255) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "school_groups_pkey" PRIMARY KEY ("id")
);

-- AddColumn: group_id to schools (skip if column exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'schools' AND column_name = 'group_id'
    ) THEN
        ALTER TABLE "schools" ADD COLUMN "group_id" UUID;
    END IF;
END $$;

-- AddForeignKey (skip if exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'schools_group_id_fkey' AND table_name = 'schools'
    ) THEN
        ALTER TABLE "schools" ADD CONSTRAINT "schools_group_id_fkey"
            FOREIGN KEY ("group_id") REFERENCES "school_groups"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;
