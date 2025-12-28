const { verifyToken } = require('../config/jwt');
const { error } = require('../utils/response.util');

module.exports = function authenticate(req, res, next) {
	const header = req.headers.authorization || '';
	const [scheme, token] = header.split(' ');
	if (scheme !== 'Bearer' || !token) {
		return error(res, 401, 'Authentication required');
	}
	try {
		const decoded = verifyToken(token);
		req.user = decoded;
		next();
	} catch (e) {
		return error(res, 401, 'Invalid or expired token');
	}
};
