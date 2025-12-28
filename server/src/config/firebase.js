const admin = require('firebase-admin');
const env = require('./env');
const logger = require('../utils/logger.util');

let initialized = false;

function initFirebase() {
	if (!env.FCM_ENABLED) {
		logger.info('FCM disabled by configuration');
		return;
	}
	if (initialized) return;
	if (!env.FIREBASE_PROJECT_ID || !env.FIREBASE_CLIENT_EMAIL || !env.FIREBASE_PRIVATE_KEY) {
		logger.warn('Missing Firebase credentials; FCM will not work');
		return;
	}

	admin.initializeApp({
		credential: admin.credential.cert({
			projectId: env.FIREBASE_PROJECT_ID,
			clientEmail: env.FIREBASE_CLIENT_EMAIL,
			privateKey: env.FIREBASE_PRIVATE_KEY,
		}),
	});
	initialized = true;
	logger.info('Firebase Admin initialized');
}

module.exports = { admin, initFirebase };
