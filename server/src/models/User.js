const mongoose = require('mongoose');
const { hashPassword, comparePassword } = require('../utils/password.util');

const UserSchema = new mongoose.Schema({
	email: { type: String, required: true, unique: true, index: true },
	password: { type: String, required: true },
	role: { type: String, enum: ['member', 'admin'], required: true },
	name: { type: String },
}, { timestamps: true });

UserSchema.pre('save', async function (next) {
	if (!this.isModified('password')) return next();
	this.password = await hashPassword(this.password);
	next();
});

UserSchema.methods.comparePassword = function (plain) {
	return comparePassword(plain, this.password);
};

module.exports = mongoose.model('User', UserSchema);
