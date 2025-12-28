const { admin } = require('../config/firebase');
const logger = require('../utils/logger.util');
const env = require('../config/env');

async function sendToTopic(topic, notification, data = {}) {
	if (!env.FCM_ENABLED) {
		logger.warn('FCM disabled; skipping send');
		return { success: false, message: 'FCM disabled' };
	}
	if (!admin.apps || admin.apps.length === 0) {
		logger.warn('Firebase not initialized; cannot send');
		return { success: false, message: 'Firebase not initialized' };
	}
	const message = {
		topic,
		notification,
		data: Object.fromEntries(Object.entries(data).map(([k, v]) => [String(k), String(v)])),
	};
	try {
		const id = await admin.messaging().send(message);
		logger.info('FCM sent', { topic, id });
		return { success: true, id };
	} catch (e) {
		logger.error('FCM error', e);
		return { success: false, error: e.message };
	}
}

module.exports = { sendToTopic };
