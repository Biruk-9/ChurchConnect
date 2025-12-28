const mongoose = require('mongoose');

const AnnouncementSchema = new mongoose.Schema({
	title: { type: String, required: true },
	content: { type: String, required: true },
	date: { type: Date, required: true },
	imageUrl: { type: String },
	createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

module.exports = mongoose.model('Announcement', AnnouncementSchema);
