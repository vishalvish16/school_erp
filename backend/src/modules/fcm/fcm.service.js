/**
 * FCM Service — Firebase Cloud Messaging for push notifications.
 * Requires: FIREBASE_SERVICE_ACCOUNT_PATH in .env (path to service account JSON).
 * Or GOOGLE_APPLICATION_CREDENTIALS env.
 * Download from Firebase Console → Project Settings → Service Accounts.
 */
import { readFileSync } from 'fs';
import { resolve } from 'path';
import admin from 'firebase-admin';
import { env } from '../../config/env.js';
import { logger } from '../../config/logger.js';

let _initialized = false;

function ensureInitialized() {
    if (_initialized) return;
    const credPath = env.FIREBASE_SERVICE_ACCOUNT_PATH || process.env.GOOGLE_APPLICATION_CREDENTIALS;
    if (!credPath) {
        logger.warn('[FCM] No credentials — set FIREBASE_SERVICE_ACCOUNT_PATH in .env');
        return;
    }
    try {
        const fullPath = resolve(process.cwd(), credPath);
        const cred = JSON.parse(readFileSync(fullPath, 'utf8'));
        admin.initializeApp({ credential: admin.credential.cert(cred) });
        _initialized = true;
        logger.info('[FCM] Initialized');
    } catch (err) {
        logger.error('[FCM] Init failed:', err.message);
    }
}

/**
 * Send FCM to tokens. Payload: { title, body, data: { type, portal, route, ... } }
 */
export async function sendFcmToTokens(tokens, { title, body, data = {} }) {
    if (!tokens || tokens.length === 0) return;
    ensureInitialized();
    if (!_initialized) return;

    const message = {
        notification: { title, body },
        data: Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v ?? '')]),
        ),
        android: {
            priority: 'high',
            notification: { channelId: 'high_importance_channel' },
        },
        webpush: {
            fcmOptions: { link: data.route || '/parent/notices' },
        },
        tokens,
    };

    try {
        const res = await admin.messaging().sendEachForMulticast(message);
        if (res.failureCount > 0) {
            logger.warn(`[FCM] ${res.failureCount}/${res.successCount} failed`);
        }
    } catch (err) {
        logger.error('[FCM] Send failed:', err.message);
    }
}
