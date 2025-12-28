const mongoose = require('mongoose');

const ResourceSchema = new mongoose.Schema({
	title: { type: String, required: true },
	description: { type: String },
	category: { type: String },
	accessLevel: { type: String, enum: ['public', 'members'], required: true },
	mediaType: { type: String, enum: ['pdf', 'audio', 'image', 'video_link'], required: true },
	fileUrl: { type: String },
	createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

module.exports = mongoose.model('Resource', ResourceSchema);
