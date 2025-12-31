require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const mongoose = require('mongoose');
const User = require('../src/models/user');
const { hashPassword } = require('../src/utils/password.util');

(async () => {
	await mongoose.connect(process.env.MONGODB_URI);

	const passwordHash = await hashPassword('changeme123');

	await User.create({
		email: 'birukmitiku16@gmail.com',
		password: passwordHash,
		role: 'admin',
		name: 'Biruk Mitiku'
	});

	console.log('✅ Admin user created');
	process.exit();
})();
