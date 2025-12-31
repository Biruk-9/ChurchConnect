const path = require('path');
const dotenv = require('dotenv');

// Load .env from project root
dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const env = {
	NODE_ENV: process.env.NODE_ENV || 'development',
	PORT: parseInt(process.env.PORT || '5000', 10),
	MONGODB_URI: process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/churchconnect',
	JWT_SECRET: process.env.JWT_SECRET || 'change_this_in_prod',
	JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '10m',
	ADMIN_BASE_PATH: process.env.ADMIN_BASE_PATH || '/api/_admin_9b27',
	CORS_ORIGIN: process.env.CORS_ORIGIN || '*',
	STORAGE_DRIVER: process.env.STORAGE_DRIVER || 'local', // local | firebase | cloudinary
	FCM_ENABLED: (process.env.FCM_ENABLED || 'false').toLowerCase() === 'true',
	FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID || '',
	FIREBASE_CLIENT_EMAIL: process.env.FIREBASE_CLIENT_EMAIL || '',
	FIREBASE_PRIVATE_KEY: process.env.FIREBASE_PRIVATE_KEY ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n') : ''
};

module.exports = env;
