-- CreateTable
CREATE TABLE "plan_features" (
    "id" SERIAL NOT NULL,
    "plan_id" BIGINT NOT NULL,
    "feature_key" VARCHAR(100) NOT NULL,
    "is_enabled" BOOLEAN NOT NULL DEFAULT true,
    CONSTRAINT "plan_features_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "plan_features_plan_id_feature_key_key" UNIQUE ("plan_id", "feature_key"),
    CONSTRAINT "plan_features_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "platform_plans"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
