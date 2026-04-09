const {onDocumentCreated, onDocumentUpdated} = require('firebase-functions/v2/firestore');
const {onRequest} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const logger = require('firebase-functions/logger');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue, Timestamp} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');

initializeApp();

const REMINDER_TIME_ZONE = 'Asia/Kathmandu';

function toDate(value) {
  if (!value) {
    return null;
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value.toDate === 'function') {
    return value.toDate();
  }
  return null;
}

function formatEventDateTime(date) {
  return new Intl.DateTimeFormat('en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: REMINDER_TIME_ZONE,
  }).format(date);
}

function dateKeyInNepal(date) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: REMINDER_TIME_ZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(date);

  const year = parts.find((part) => part.type === 'year')?.value ?? '0000';
  const month = parts.find((part) => part.type === 'month')?.value ?? '00';
  const day = parts.find((part) => part.type === 'day')?.value ?? '00';
  return `${year}${month}${day}`;
}

function attendanceRecordId({userId, eventId, date}) {
  return `${userId}-${eventId}-${dateKeyInNepal(date)}`;
}

async function createNotificationWithLock({
  db,
  userId,
  notificationId,
  lockId,
  title,
  body,
  type,
  targetId = null,
  actorUserId = null,
}) {
  const lockRef = db.collection('notification_dispatch_locks').doc(lockId);
  const notificationRef = db
    .collection('users')
    .doc(userId)
    .collection('notifications')
    .doc(notificationId);

  return db.runTransaction(async (transaction) => {
    const lockSnapshot = await transaction.get(lockRef);
    if (lockSnapshot.exists) {
      return false;
    }

    transaction.set(lockRef, {
      userId,
      type,
      targetId,
      createdAt: FieldValue.serverTimestamp(),
    });

    transaction.set(notificationRef, {
      title,
      body,
      type,
      targetId,
      actorUserId,
      createdAt: FieldValue.serverTimestamp(),
      isRead: false,
    });

    return true;
  });
}

async function notifyAdminsForEventReview({
  db,
  eventId,
  eventTitle,
  reviewRequestedAt,
  bodyText,
}) {
  const adminsSnapshot = await db.collection('users').where('role', '==', 'admin').get();
  if (adminsSnapshot.empty) {
    logger.info(`No admins found to notify for event ${eventId} review.`);
    return;
  }

  const reviewKey = reviewRequestedAt ? `${reviewRequestedAt.getTime()}` : 'pending';
  let sentCount = 0;

  for (const adminDoc of adminsSnapshot.docs) {
    const adminData = adminDoc.data() || {};
    if (adminData.isBanned === true) {
      continue;
    }

    const userId = adminDoc.id;
    const sent = await createNotificationWithLock({
      db,
      userId,
      notificationId: `admin-review-${eventId}-${reviewKey}`,
      lockId: `admin-review-${eventId}-${userId}-${reviewKey}`,
      title: 'Admin review required',
      body: bodyText ?? `A review item is waiting: ${eventTitle}.`,
      type: 'admin_review_required',
      targetId: eventId,
    });

    if (sent) {
      sentCount += 1;
    }
  }

  logger.info(`Admin review notifications sent for event ${eventId}: ${sentCount}`);
}

exports.sendNotificationPush = onDocumentCreated(
  {
    document: 'users/{userId}/notifications/{notificationId}',
    region: 'us-central1',
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn('Notification trigger fired without snapshot data.');
      return;
    }

    const notification = snapshot.data();
    const userId = event.params.userId;
    const db = getFirestore();
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      logger.warn(`User ${userId} not found for notification push.`);
      return;
    }

    const userData = userDoc.data() || {};
    const rawTokens = Array.isArray(userData.fcmTokens) ? userData.fcmTokens : [];
    const tokens = rawTokens.filter((token) => typeof token === 'string' && token.trim().length > 0);

    if (tokens.length === 0) {
      logger.info(`No FCM tokens found for user ${userId}. Skipping push send.`);
      return;
    }

    const title = notification.title || 'Shramdaan';
    const body = notification.body || 'You have a new update.';
    const type = notification.type || 'general';
    const targetId = notification.targetId || '';
    const actorUserId = notification.actorUserId || '';

    const message = {
      tokens,
      notification: {
        title,
        body,
      },
      data: {
        title: String(title),
        body: String(body),
        type: String(type),
        targetId: String(targetId),
        actorUserId: String(actorUserId),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'shramdaan_updates',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      webpush: {
        fcmOptions: {
          link: '/',
        },
      },
    };

    const response = await getMessaging().sendEachForMulticast(message);
    logger.info(
      `Push send complete for user ${userId}. Success: ${response.successCount}, Failure: ${response.failureCount}.`,
    );

    const invalidTokens = [];
    response.responses.forEach((result, index) => {
      if (!result.success && result.error) {
        const code = result.error.code || '';
        if (
          code === 'messaging/invalid-registration-token' ||
          code === 'messaging/registration-token-not-registered'
        ) {
          invalidTokens.push(tokens[index]);
        } else {
          logger.error(`Push failed for user ${userId}: ${code}`, result.error);
        }
      }
    });

    if (invalidTokens.length > 0) {
      await userRef.update({
        fcmTokens: FieldValue.arrayRemove(...invalidTokens),
      });
      logger.info(`Removed ${invalidTokens.length} invalid FCM tokens for user ${userId}.`);
    }
  },
);

exports.notifyAdminsOnPendingEventCreate = onDocumentCreated(
  {
    document: 'events/{eventId}',
    region: 'us-central1',
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const eventData = snapshot.data() || {};
    if (eventData.status !== 'pending') {
      return;
    }

    const db = getFirestore();
    const eventTitle = eventData.title || 'Untitled event';
    await notifyAdminsForEventReview({
      db,
      eventId: event.params.eventId,
      eventTitle,
      reviewRequestedAt: toDate(eventData.reviewRequestedAt),
      bodyText: `New event submission needs review: ${eventTitle}.`,
    });
  },
);

exports.notifyAdminsOnEventResubmission = onDocumentUpdated(
  {
    document: 'events/{eventId}',
    region: 'us-central1',
  },
  async (event) => {
    const beforeData = event.data?.before.data() || {};
    const afterData = event.data?.after.data() || {};

    if (beforeData.status === 'pending' || afterData.status !== 'pending') {
      return;
    }

    const db = getFirestore();
    const eventTitle = afterData.title || 'Untitled event';
    await notifyAdminsForEventReview({
      db,
      eventId: event.params.eventId,
      eventTitle,
      reviewRequestedAt: toDate(afterData.reviewRequestedAt),
      bodyText: `Event resubmission is waiting for review: ${eventTitle}.`,
    });
  },
);

exports.sendOneHourEventReminders = onSchedule(
  {
    schedule: '* * * * *',
    timeZone: REMINDER_TIME_ZONE,
    region: 'us-central1',
  },
  async () => {
    const db = getFirestore();
    const now = new Date();
    const minTime = new Date(now.getTime() + 59 * 60 * 1000);
    const maxTime = new Date(now.getTime() + 60 * 60 * 1000);

    const eventsSnapshot = await db
      .collection('events')
      .where('status', '==', 'approved')
      .where('eventDate', '>=', Timestamp.fromDate(minTime))
      .where('eventDate', '<=', Timestamp.fromDate(maxTime))
      .get();

    if (eventsSnapshot.empty) {
      return;
    }

    for (const eventDoc of eventsSnapshot.docs) {
      const eventData = eventDoc.data() || {};
      if (eventData.endedAt) {
        continue;
      }

      const eventDate = toDate(eventData.eventDate);
      if (!eventDate) {
        continue;
      }

      const eventId = eventDoc.id;
      const eventTitle = eventData.title || 'your event';
      const rsvpSnapshot = await db.collection('rsvps').where('eventId', '==', eventId).get();

      for (const rsvpDoc of rsvpSnapshot.docs) {
        const userId = rsvpDoc.data().userId;
        if (!userId) {
          continue;
        }

        await createNotificationWithLock({
          db,
          userId,
          notificationId: `event-reminder-1h-${eventId}`,
          lockId: `event-reminder-1h-${eventId}-${userId}`,
          title: 'Event starts in 1 hour',
          body: `${eventTitle} starts at ${formatEventDateTime(eventDate)}.`,
          type: 'event_reminder_1h',
          targetId: eventId,
        });
      }
    }
  },
);

exports.sendCheckInStartReminders = onSchedule(
  {
    schedule: '* * * * *',
    timeZone: REMINDER_TIME_ZONE,
    region: 'us-central1',
  },
  async () => {
    const db = getFirestore();
    const now = new Date();
    const minTime = new Date(now.getTime() - 2 * 60 * 1000);
    const maxTime = new Date(now.getTime() + 2 * 60 * 1000);

    const eventsSnapshot = await db
      .collection('events')
      .where('status', '==', 'approved')
      .where('eventDate', '>=', Timestamp.fromDate(minTime))
      .where('eventDate', '<=', Timestamp.fromDate(maxTime))
      .get();

    if (eventsSnapshot.empty) {
      return;
    }

    for (const eventDoc of eventsSnapshot.docs) {
      const eventData = eventDoc.data() || {};
      if (eventData.endedAt) {
        continue;
      }

      const eventDate = toDate(eventData.eventDate);
      if (!eventDate) {
        continue;
      }

      const eventId = eventDoc.id;
      const eventTitle = eventData.title || 'your event';
      const rsvpSnapshot = await db.collection('rsvps').where('eventId', '==', eventId).get();

      for (const rsvpDoc of rsvpSnapshot.docs) {
        const userId = rsvpDoc.data().userId;
        if (!userId) {
          continue;
        }

        const attendanceId = attendanceRecordId({
          userId,
          eventId,
          date: eventDate,
        });
        const attendanceDoc = await db.collection('attendance').doc(attendanceId).get();
        if (attendanceDoc.exists) {
          continue;
        }

        await createNotificationWithLock({
          db,
          userId,
          notificationId: `event-checkin-reminder-${eventId}`,
          lockId: `event-checkin-reminder-${eventId}-${userId}`,
          title: 'Check-in reminder',
          body: `${eventTitle} is starting now. Open the event to check in when you arrive.`,
          type: 'event_checkin_reminder',
          targetId: eventId,
        });
      }
    }
  },
);

exports.seedAttendanceData = onRequest(
  {region: 'us-central1'},
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const db = getFirestore();
    const seedData = [
      {
        id: 'RngVLCRNgpUMCupD5as2qt1CTXc2-6dZGUvJCi5rk18lomfG5-20260322',
        volunteer_id: 'RngVLCRNgpUMCupD5as2qt1CTXc2',
        event_id: '6dZGUvJCi5rk18lomfG5',
        attendance_date: Timestamp.fromDate(new Date('2026-03-22T00:00:00Z')),
        check_in_time: Timestamp.fromDate(new Date('2026-03-22T08:00:00Z')),
        check_out_time: Timestamp.fromDate(new Date('2026-03-22T10:30:00Z')),
      },
      {
        id: '0Roby0hGWnOXR9z1FZtfAElwHgi2-Eng341bN0qxI4ylPxyab-20260322',
        volunteer_id: '0Roby0hGWnOXR9z1FZtfAElwHgi2',
        event_id: 'Eng341bN0qxI4ylPxyab',
        attendance_date: Timestamp.fromDate(new Date('2026-03-22T00:00:00Z')),
        check_in_time: Timestamp.fromDate(new Date('2026-03-22T09:15:00Z')),
        check_out_time: Timestamp.fromDate(new Date('2026-03-22T11:15:00Z')),
      },
      {
        id: 'lHiAdcFIHDV6kKfxCPMPEGBRfpk2-hzXnwp8MCxhAndJ82i70-20260322',
        volunteer_id: 'lHiAdcFIHDV6kKfxCPMPEGBRfpk2',
        event_id: 'hzXnwp8MCxhAndJ82i70',
        attendance_date: Timestamp.fromDate(new Date('2026-03-22T00:00:00Z')),
        check_in_time: Timestamp.fromDate(new Date('2026-03-22T07:45:00Z')),
        check_out_time: Timestamp.fromDate(new Date('2026-03-22T12:15:00Z')),
      },
      {
        id: 'dGgz2UtfivPOwi1Jx9Z2DUzBbY13-pI9vYlmhZNETYOlKZyB5-20260322',
        volunteer_id: 'dGgz2UtfivPOwi1Jx9Z2DUzBbY13',
        event_id: 'pI9vYlmhZNETYOlKZyB5',
        attendance_date: Timestamp.fromDate(new Date('2026-03-22T00:00:00Z')),
        check_in_time: Timestamp.fromDate(new Date('2026-03-22T10:00:00Z')),
        check_out_time: Timestamp.fromDate(new Date('2026-03-22T11:00:00Z')),
      },
      {
        id: 'EL4xyuEzWSeA3OKNH6wgADgHWEw2-6dZGUvJCi5rk18lomfG5-20260322',
        volunteer_id: 'EL4xyuEzWSeA3OKNH6wgADgHWEw2',
        event_id: '6dZGUvJCi5rk18lomfG5',
        attendance_date: Timestamp.fromDate(new Date('2026-03-22T00:00:00Z')),
        check_in_time: Timestamp.fromDate(new Date('2026-03-22T08:30:00Z')),
        check_out_time: Timestamp.fromDate(new Date('2026-03-22T09:00:00Z')),
      },
      {
        id: 'K6bqLAtlvnZpk0lSIydOiPFxeHd2-Eng341bN0qxI4ylPxyab-20260322',
        volunteer_id: 'K6bqLAtlvnZpk0lSIydOiPFxeHd2',
        event_id: 'Eng341bN0qxI4ylPxyab',
        attendance_date: Timestamp.fromDate(new Date('2026-03-22T00:00:00Z')),
        check_in_time: Timestamp.fromDate(new Date('2026-03-22T06:30:00Z')),
        check_out_time: Timestamp.fromDate(new Date('2026-03-22T12:30:00Z')),
      },
      {
        id: 'RngVLCRNgpUMCupD5as2qt1CTXc2-hzXnwp8MCxhAndJ82i70-20260321',
        volunteer_id: 'RngVLCRNgpUMCupD5as2qt1CTXc2',
        event_id: 'hzXnwp8MCxhAndJ82i70',
        attendance_date: Timestamp.fromDate(new Date('2026-03-21T00:00:00Z')),
        check_in_time: Timestamp.fromDate(new Date('2026-03-21T09:00:00Z')),
        check_out_time: Timestamp.fromDate(new Date('2026-03-21T13:00:00Z')),
      },
      {
        id: 'K6bqLAtlvnZpk0lSIydOiPFxeHd2-pI9vYlmhZNETYOlKZyB5-20260321',
        volunteer_id: 'K6bqLAtlvnZpk0lSIydOiPFxeHd2',
        event_id: 'pI9vYlmhZNETYOlKZyB5',
        attendance_date: Timestamp.fromDate(new Date('2026-03-21T00:00:00Z')),
        check_in_time: Timestamp.fromDate(new Date('2026-03-21T08:00:00Z')),
        check_out_time: Timestamp.fromDate(new Date('2026-03-21T10:00:00Z')),
      },
      {
        id: '0Roby0hGWnOXR9z1FZtfAElwHgi2-6dZGUvJCi5rk18lomfG5-20260321',
        volunteer_id: '0Roby0hGWnOXR9z1FZtfAElwHgi2',
        event_id: '6dZGUvJCi5rk18lomfG5',
        attendance_date: Timestamp.fromDate(new Date('2026-03-21T00:00:00Z')),
        check_in_time: Timestamp.fromDate(new Date('2026-03-21T11:00:00Z')),
        check_out_time: Timestamp.fromDate(new Date('2026-03-21T12:30:00Z')),
      },
    ];

    const batch = db.batch();
    seedData.forEach((entry) => {
      const docRef = db.collection('attendance').doc(entry.id);
      batch.set(docRef, {
        volunteer_id: entry.volunteer_id,
        event_id: entry.event_id,
        attendance_date: entry.attendance_date,
        check_in_time: entry.check_in_time,
        check_out_time: entry.check_out_time,
        updated_at: FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
    res.status(200).json({ok: true, inserted: seedData.length});
  },
);
