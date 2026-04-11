/**
 * Prisma Client Singleton
 * ========================
 * ONE instance shared across the entire application.
 * Never import { PrismaClient } and call new PrismaClient() directly —
 * doing so in 40+ modules opens a separate connection pool per module,
 * exhausting PostgreSQL's max_connections limit (typically 100).
 *
 * Usage in every repository / service / middleware:
 *   import prisma from '../../config/prisma.js';
 */

import { PrismaClient } from '@prisma/client';

const globalForPrisma = globalThis;

const prisma =
  globalForPrisma.__prisma ??
  new PrismaClient({
    log:
      process.env.NODE_ENV === 'development'
        ? ['warn', 'error']
        : ['error'],
  });

// In development hot-reload keeps the old module cached, so re-use the
// existing client instead of opening yet another pool.
if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.__prisma = prisma;
}

export default prisma;
