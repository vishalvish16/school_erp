-- CreateTable: group_notices (IF NOT EXISTS for idempotency)
CREATE TABLE IF NOT EXISTS "group_notices" (
    "id"           UUID NOT NULL DEFAULT gen_random_uuid(),
    "group_id"     UUID NOT NULL,
    "title"        VARCHAR(255) NOT NULL,
    "body"         TEXT NOT NULL,
    "target_role"  VARCHAR(50),
    "is_pinned"    BOOLEAN NOT NULL DEFAULT false,
    "published_at" TIMESTAMPTZ(6),
    "expires_at"   TIMESTAMPTZ(6),
    "created_by"   UUID NOT NULL,
    "deleted_at"   TIMESTAMPTZ(6),
    "created_at"   TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
    "updated_at"   TIMESTAMPTZ(6) NOT NULL DEFAULT now(),

    CONSTRAINT "group_notices_pkey" PRIMARY KEY ("id")
);

-- CreateTable: group_alert_rules (IF NOT EXISTS for idempotency)
CREATE TABLE IF NOT EXISTS "group_alert_rules" (
    "id"             UUID NOT NULL DEFAULT gen_random_uuid(),
    "group_id"       UUID NOT NULL,
    "name"           VARCHAR(255) NOT NULL,
    "metric"         VARCHAR(100) NOT NULL,
    "condition"      VARCHAR(20) NOT NULL,
    "threshold"      DECIMAL(10,2) NOT NULL,
    "notify_email"   BOOLEAN NOT NULL DEFAULT true,
    "notify_sms"     BOOLEAN NOT NULL DEFAULT false,
    "is_active"      BOOLEAN NOT NULL DEFAULT true,
    "last_triggered" TIMESTAMPTZ(6),
    "created_by"     UUID NOT NULL,
    "created_at"     TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
    "updated_at"     TIMESTAMPTZ(6) NOT NULL DEFAULT now(),

    CONSTRAINT "group_alert_rules_pkey" PRIMARY KEY ("id")
);

-- CreateIndex (IF NOT EXISTS for idempotency)
CREATE INDEX IF NOT EXISTS "group_notices_group_id_idx" ON "group_notices"("group_id");
CREATE INDEX IF NOT EXISTS "group_notices_published_at_idx" ON "group_notices"("published_at");
CREATE INDEX IF NOT EXISTS "group_alert_rules_group_id_idx" ON "group_alert_rules"("group_id");

-- AddForeignKey (skip if exists)
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'group_notices_group_id_fkey' AND conrelid = 'group_notices'::regclass) THEN
        ALTER TABLE "group_notices" ADD CONSTRAINT "group_notices_group_id_fkey"
            FOREIGN KEY ("group_id") REFERENCES "school_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'group_alert_rules_group_id_fkey' AND conrelid = 'group_alert_rules'::regclass) THEN
        ALTER TABLE "group_alert_rules" ADD CONSTRAINT "group_alert_rules_group_id_fkey"
            FOREIGN KEY ("group_id") REFERENCES "school_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
