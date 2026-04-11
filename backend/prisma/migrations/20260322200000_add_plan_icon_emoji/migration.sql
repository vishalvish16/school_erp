-- Migration: add icon_emoji column to platform_plans
ALTER TABLE "platform_plans"
  ADD COLUMN IF NOT EXISTS "icon_emoji" VARCHAR(10) DEFAULT '📦';
