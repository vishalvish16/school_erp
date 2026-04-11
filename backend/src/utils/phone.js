/**
 * Phone normalization — E.164 format for India (+91 + 10 digits).
 * Use consistently for Parent lookup/create to avoid duplicate records
 * when school admin uses "9876543210" and parent login uses "+919876543210".
 */
export function normalizePhone(phone) {
    const digits = String(phone || '').replace(/\D/g, '').slice(-10);
    if (digits.length < 10) return null;
    return '+91' + digits;
}
