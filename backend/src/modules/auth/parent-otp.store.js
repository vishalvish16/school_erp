/**
 * In-memory Parent OTP session store (Option A for dev).
 * Map<otp_session_id, { parentId, schoolId, phone, otpCode, expiresAt, attempts }>
 * Expire entries after 2 minutes. Max 3 attempts.
 */
const store = new Map();
const MAX_ATTEMPTS = 3;
const CLEANUP_INTERVAL_MS = 60 * 1000;

function cleanup() {
    const now = new Date();
    for (const [id, sess] of store.entries()) {
        if (sess.expiresAt < now || sess.used) {
            store.delete(id);
        }
    }
}

let cleanupTimer = null;
function scheduleCleanup() {
    if (!cleanupTimer) {
        cleanupTimer = setInterval(cleanup, CLEANUP_INTERVAL_MS);
        cleanupTimer.unref?.();
    }
}

export function set(otpSessionId, data) {
    store.set(otpSessionId, { ...data, used: false });
    scheduleCleanup();
}

export function get(otpSessionId) {
    const sess = store.get(otpSessionId);
    if (!sess) return null;
    if (sess.expiresAt < new Date()) {
        store.delete(otpSessionId);
        return null;
    }
    if (sess.used) return null;
    if (sess.attempts >= MAX_ATTEMPTS) return null;
    return sess;
}

export function markUsed(otpSessionId) {
    const sess = store.get(otpSessionId);
    if (sess) sess.used = true;
}

export function incrementAttempts(otpSessionId) {
    const sess = store.get(otpSessionId);
    if (sess) sess.attempts = (sess.attempts || 0) + 1;
}
