const { error } = require('../utils/response.util');

module.exports = function authorizeMember(req, res, next) {
	if (req.user && (req.user.role === 'member' || req.user.role === 'admin')) return next();
	return error(res, 403, 'Member access required');
};
