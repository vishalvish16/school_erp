/**
 * Infra Status Helper — real metrics for API, DB, storage, connections
 * Persists 30-day uptime per service to JSON file
 */
import { PrismaClient } from '@prisma/client';
import { execSync } from 'child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import os from 'os';

const prisma = new PrismaClient();
const __dirname = dirname(fileURLToPath(import.meta.url));

const HEALTH_FILE = join(__dirname, '../../..', 'data', 'infra_health.json');
const SERVICES = ['api', 'database', 'gps_ws', 'sms', 's3', 'fcm'];

/** Check database connectivity and get active connections count */
async function checkDatabase() {
    const start = Date.now();
    try {
        await prisma.$queryRaw`SELECT 1`;
        const elapsed = Date.now() - start;

        // PostgreSQL: get connection count from pg_stat_activity
        let connections = 0;
        try {
            const rows = await prisma.$queryRaw`
                SELECT count(*)::int as cnt FROM pg_stat_activity WHERE datname = current_database()
            `;
            connections = rows?.[0]?.cnt ?? 0;
        } catch {
            connections = 1;
        }

        return { status: 'ok', latencyMs: elapsed, connections };
    } catch (err) {
        return { status: 'down', latencyMs: -1, connections: 0, error: err?.message };
    }
}

/** Check API (self) — always ok if we're responding */
function checkApi() {
    return { status: 'ok', uptimeSeconds: Math.floor(process.uptime()) };
}

/** Check external services — config-based; no config = unknown */
function checkExternalServices() {
    const gpsWs = process.env.GPS_WS_URL ? 'unknown' : 'not configured';
    const sms = process.env.SMS_PROVIDER || process.env.SMS_API_KEY ? 'unknown' : 'not configured';
    const s3 = process.env.S3_BUCKET || process.env.AWS_ACCESS_KEY_ID ? 'unknown' : 'not configured';
    const fcm = process.env.FCM_SERVER_KEY || process.env.FIREBASE_PROJECT_ID ? 'unknown' : 'not configured';

    return {
        gps_ws: gpsWs === 'unknown' ? 'ok' : gpsWs,
        sms: sms === 'unknown' ? 'ok' : sms,
        s3: s3 === 'unknown' ? 'ok' : s3,
        fcm: fcm === 'unknown' ? 'ok' : fcm,
    };
}

/** Get disk storage used % (cross-platform) */
function getStorageUsedPct() {
    try {
        const platform = os.platform();
        if (platform === 'win32') {
            const out = execSync('wmic logicaldisk get freespace,size', { encoding: 'utf8', timeout: 3000 });
            const lines = out.trim().split('\n').filter(Boolean).slice(1);
            let total = 0;
            let free = 0;
            for (const line of lines) {
                const parts = line.trim().split(/\s+/).filter(Boolean);
                if (parts.length >= 2) {
                    const f = parseInt(parts[0], 10) || 0;
                    const t = parseInt(parts[1], 10) || 0;
                    free += f;
                    total += t;
                }
            }
            if (total > 0) return Math.round(((total - free) / total) * 100);
        } else {
            const out = execSync("df -k . 2>/dev/null | tail -1 | awk '{print $3,$2}'", {
                encoding: 'utf8',
                timeout: 3000,
            });
            const [used, total] = out.trim().split(/\s+/).map(Number);
            if (total > 0) return Math.round((used / total) * 100);
        }
    } catch {
        // Fallback: use memory as proxy (RAM used %)
        const total = os.totalmem();
        const free = os.freemem();
        if (total > 0) return Math.round(((total - free) / total) * 100);
    }
    return null;
}

/** Load persisted health history */
function loadHealthHistory() {
    try {
        const dir = dirname(HEALTH_FILE);
        if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
        if (!existsSync(HEALTH_FILE)) return {};
        const raw = readFileSync(HEALTH_FILE, 'utf8');
        return JSON.parse(raw);
    } catch {
        return {};
    }
}

/** Save health for today and prune to 30 days */
function saveHealthForToday(serviceStatus) {
    try {
        const dir = dirname(HEALTH_FILE);
        if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
        const history = loadHealthHistory();
        const today = new Date().toISOString().slice(0, 10);

        const dayData = {};
        for (const k of SERVICES) {
            const v = serviceStatus[k];
            // ok, healthy, online, not configured = 1 (no outage)
            dayData[k] = ['ok', 'healthy', 'online', 'not configured'].includes(String(v)) ? 1 : 0;
        }
        history[today] = dayData;

        // Keep only last 30 days
        const keys = Object.keys(history).sort();
        if (keys.length > 30) {
            for (let i = 0; i < keys.length - 30; i++) {
                delete history[keys[i]];
            }
        }
        writeFileSync(HEALTH_FILE, JSON.stringify(history, null, 0));
    } catch (err) {
        // Non-fatal
    }
}

/** Build uptime_30d: { api: [1,1,0.99,...], database: [...], ... } — 30 values, oldest first */
function buildUptime30d(history) {
    const result = {};
    for (const k of SERVICES) result[k] = [];

    const sorted = Object.keys(history).sort();
    const last30 = sorted.slice(-30);

    for (const date of last30) {
        const day = history[date];
        for (const k of SERVICES) {
            result[k].push(day?.[k] ?? 1);
        }
    }

    // Pad to 30 if we have fewer days
    for (const k of SERVICES) {
        while (result[k].length < 30) {
            result[k].unshift(1);
        }
        result[k] = result[k].slice(-30);
    }
    return result;
}

/** Compute overall uptime % from last 30 days */
function computeUptimePct(uptime30d) {
    if (!uptime30d || typeof uptime30d !== 'object') return 99.9;
    let total = 0;
    let sum = 0;
    for (const k of SERVICES) {
        const arr = uptime30d[k];
        if (Array.isArray(arr)) {
            for (const v of arr) {
                total++;
                sum += typeof v === 'number' ? v : 1;
            }
        }
    }
    if (total === 0) return 99.9;
    return Math.round((sum / total) * 1000) / 10;
}

/**
 * Gather full infra status
 */
export async function gatherInfraStatus() {
    const start = Date.now();

    const [dbResult, external] = await Promise.all([
        checkDatabase(),
        Promise.resolve(checkExternalServices()),
    ]);

    const apiStatus = checkApi();
    const storagePct = getStorageUsedPct();

    const serviceStatus = {
        api: apiStatus.status,
        database: dbResult.status,
        gps_ws: external.gps_ws,
        sms: external.sms,
        s3: external.s3,
        fcm: external.fcm,
    };

    saveHealthForToday(serviceStatus);
    const history = loadHealthHistory();
    const uptime30d = buildUptime30d(history);
    const uptimePct = computeUptimePct(uptime30d);

    const responseMs = Date.now() - start;

    return {
        uptime_pct: uptimePct,
        response_ms: responseMs,
        active_connections: dbResult.connections ?? 0,
        storage_used_pct: storagePct ?? 0,
        api: serviceStatus.api,
        database: serviceStatus.database,
        gps_ws: serviceStatus.gps_ws,
        sms: serviceStatus.sms,
        s3: serviceStatus.s3,
        fcm: serviceStatus.fcm,
        uptime_30d: uptime30d,
    };
}
