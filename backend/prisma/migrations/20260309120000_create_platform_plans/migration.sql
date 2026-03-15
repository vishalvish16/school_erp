-- Create platform_plans table if it does not exist
-- (Required for super-admin plan management when DB was set up without original migration)
CREATE TABLE IF NOT EXISTS platform_plans (
    id BIGSERIAL NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    max_branches INTEGER NOT NULL DEFAULT 1,
    max_users INTEGER NOT NULL DEFAULT 50,
    created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT platform_plans_pkey PRIMARY KEY (id)
);
