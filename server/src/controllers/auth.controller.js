const User = require('../models/user');
const { signToken } = require('../config/jwt');
const { error, success } = require('../utils/response.util');

async function login(req, res) {
	const { email, password } = req.body || {};
	if (!email || !password) return error(res, 400, 'Email and password are required');
	const user = await User.findOne({ email: String(email).toLowerCase() });
	if (!user) return error(res, 401, 'Invalid credentials');
	const ok = await user.comparePassword(password);
	if (!ok) return error(res, 401, 'Invalid credentials');
	const token = signToken({ id: user._id.toString(), role: user.role, email: user.email });
	return success(res, { token, role: user.role }, 'Login successful');
}

module.exports = { login };
