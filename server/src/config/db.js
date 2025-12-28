const mongoose = require('mongoose');
const env = require('./env');
const logger = require('../utils/logger.util');

async function connectDB() {
	try {
		await mongoose.connect(env.MONGODB_URI, {
			autoIndex: true,
		});
		logger.info(`MongoDB connected`);
		return mongoose.connection;
	} catch (err) {
		logger.error('MongoDB connection error', err);
		process.exit(1);
	}
}

module.exports = { connectDB };
