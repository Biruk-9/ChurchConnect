require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const mongoose = require('mongoose');
const User = require('../src/models/user');
const { hashPassword } = require('../src/utils/password.util');

(async () => {
	try {
		// Connect to MongoDB
		await mongoose.connect(process.env.MONGODB_URI);

		// Hash the member password
		const passwordHash = await hashPassword('nati123'); 

		// Create the member user
		await User.create({
			email: 'nati123@gmail.com', 
			password: passwordHash,
			role: 'member',
			name: 'Nati Abreha',
			isActive: true,
		});

		console.log('✅ Member user created successfully');
		process.exit();
	} catch (err) {
		console.error('❌ Error creating member:', err);
		process.exit(1);
	}
})();
