const mongoose = require('mongoose');
const { comparePassword } = require('../utils/password.util');

const UserSchema = new mongoose.Schema({
	name: { type: String, required: true },
	email: { type: String, required: true, unique: true, index: true },
	password: { type: String, required: true },
	role: { type: String, enum: ['member', 'admin'], required: true },
	isActive: { type: Boolean, default: true },
}, { timestamps: true });

// Method to compare plain password with hashed password
UserSchema.methods.comparePassword = function (plain) {
	return comparePassword(plain, this.password);
};

module.exports = mongoose.model('User', UserSchema);
