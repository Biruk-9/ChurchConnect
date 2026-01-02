const User = require('../models/user');
const { hashPassword } = require('../utils/password.util');
const { success, error } = require('../utils/response.util');

async function list(req, res) {
	try {
		const includeInactive = String(req.query.includeInactive || 'false').toLowerCase() === 'true';
		const query = {};
		if (!includeInactive) query.isActive = true;
		const users = await User.find(query).sort({ createdAt: -1 });
		return success(res, users);
	} catch (e) {
		return error(res, 500, 'Failed to list users');
	}
}

async function create(req, res) {
	try {
		const { name, email, password, isActive = true, role = 'member' } = req.body || {};
		if (!email || !password) return error(res, 400, 'Email and password are required');
		const existing = await User.findOne({ email: String(email).toLowerCase() });
		if (existing) return error(res, 409, 'Email already exists');
		const normalizedRole = role === 'admin' ? 'admin' : 'member';
		const hashed = await hashPassword(password);
		const user = await User.create({
			name,
			email: String(email).toLowerCase(),
			password: hashed,
			role: normalizedRole,
			isActive: Boolean(isActive),
		});
		return success(res, user, 'Member created', 201);
	} catch (e) {
		return error(res, 500, 'Failed to create user');
	}
}

async function update(req, res) {
	try {
		const { id } = req.params;
		const { name, email, password, isActive, role } = req.body || {};
		const user = await User.findById(id);
		if (!user) return error(res, 404, 'User not found');

		if (name !== undefined) user.name = name;
		if (email !== undefined) user.email = String(email).toLowerCase();
		if (typeof isActive === 'boolean') user.isActive = isActive;
		if (password) user.password = await hashPassword(password);
		if (role) user.role = role === 'admin' ? 'admin' : 'member';

		await user.save();
		return success(res, user, 'Member updated');
	} catch (e) {
		return error(res, 500, 'Failed to update user');
	}
}

async function remove(req, res) {
	try {
		const { id } = req.params;
		const hard = String(req.query.hard || 'false').toLowerCase() === 'true';
		const user = await User.findById(id);
		if (!user) return error(res, 404, 'User not found');

		if (hard) {
			await user.deleteOne();
			return success(res, null, 'Member deleted');
		}
		user.isActive = false;
		await user.save();
		return success(res, user, 'Member deactivated');
	} catch (e) {
		return error(res, 500, 'Failed to delete user');
	}
}

module.exports = { list, create, update, remove };
