-- AddColumn: subdomain to schools (skip if column exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'schools' AND column_name = 'subdomain'
    ) THEN
        ALTER TABLE "schools" ADD COLUMN "subdomain" VARCHAR(50) NULL;
        CREATE UNIQUE INDEX IF NOT EXISTS "schools_subdomain_key" ON "schools"("subdomain");
    END IF;
END $$;
