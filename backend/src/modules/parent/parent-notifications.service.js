/**
 * Parent Notifications Service — create in-app notifications and send FCM push.
 */
import * as ntRepo from './parent-notifications.repository.js';
import { getTokensForParent } from '../fcm/fcm.repository.js';
import { sendFcmToTokens } from '../fcm/fcm.service.js';

/**
 * Notify parent when their profile update request is approved or rejected.
 */
export async function notifyProfileRequestReviewed({
    parentId,
    schoolId,
    status,
    studentName,
    requestId,
    reviewNote,
}) {
    const isApproved = status === 'APPROVED';
    const title = isApproved
        ? 'Profile update approved'
        : 'Profile update request rejected';
    const body = isApproved
        ? `Your profile update request for ${studentName} has been approved.`
        : (reviewNote
            ? `Your profile update request for ${studentName} was rejected. Note: ${reviewNote}`
            : `Your profile update request for ${studentName} was rejected.`);

    const link = '/parent/profile-requests';
    const notification = await ntRepo.create({
        parentId,
        schoolId,
        type: isApproved ? 'success' : 'warning',
        title,
        body,
        link,
        entityType: 'profile_update_request',
        entityId: requestId,
    });

    // Send FCM push if parent has registered tokens
    const tokens = await getTokensForParent({ parentId, schoolId });
    if (tokens.length > 0) {
        sendFcmToTokens(tokens, {
            title,
            body,
            data: { type: 'profile_request_reviewed', requestId, status, route: link },
        }).catch(() => {});
    }

    return notification;
}
