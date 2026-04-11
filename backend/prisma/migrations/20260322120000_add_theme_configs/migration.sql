-- CreateTable: theme_configs
-- Stores dynamic color tokens for each portal role

CREATE TABLE "theme_configs" (
    "id" TEXT NOT NULL,
    "role" VARCHAR(50) NOT NULL,
    "light_tokens" JSONB NOT NULL,
    "dark_tokens" JSONB NOT NULL,
    "preset_name" VARCHAR(100) DEFAULT 'Default',
    "updated_by" VARCHAR(255),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "theme_configs_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "theme_configs_role_key" ON "theme_configs"("role");
