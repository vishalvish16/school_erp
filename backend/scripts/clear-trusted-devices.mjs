#!/usr/bin/env node
/**
 * Clear trusted devices so OTP verification shows again on next login.
 * Run: node scripts/clear-trusted-devices.mjs
 * (from backend folder)
 *
 * Use for local testing when you need to see the OTP screen again.
 */

import 'dotenv/config';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const result = await prisma.$executeRawUnsafe(`
    UPDATE registered_devices
    SET is_trusted = false, trusted_until = NULL
    WHERE is_trusted = true
  `);
  console.log(`✓ Cleared trust from ${result} device(s). OTP screen will show on next login.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
