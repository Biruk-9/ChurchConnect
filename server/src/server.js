const app = require('./app');
const { connectDB } = require('./config/db');
const env = require('./config/env');
const logger = require('./utils/logger.util');

(async () => {
	await connectDB();
	app.listen(env.PORT, () => {
		logger.info(`Server running on port ${env.PORT}`);
	});
})();
