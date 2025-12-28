const { error } = require('../utils/response.util');

module.exports = function authorizeAdmin(req, res, next) {
	if (req.user && req.user.role === 'admin') return next();
	return error(res, 403, 'Admin access required');
};
