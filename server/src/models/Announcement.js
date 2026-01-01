const mongoose = require('mongoose');

const AnnouncementSchema = new mongoose.Schema({
	title: { type: String, required: true },
	content: { type: String, required: true },
	imageUrl: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('Announcement', AnnouncementSchema);
