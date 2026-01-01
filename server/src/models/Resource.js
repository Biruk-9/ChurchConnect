const mongoose = require('mongoose');

const ResourceSchema = new mongoose.Schema({
	title: { type: String, required: true },
	description: { type: String },
	category: { type: String, required: true },
	accessLevel: { type: String, enum: ['public', 'members'], required: true },
	fileUrl: { type: String },
	filePath: { type: String },
}, { timestamps: true });

ResourceSchema.path('fileUrl').validate(function validator() {
	// enforce either uploaded file (filePath) or link (fileUrl), not both
	const hasUrl = !!this.fileUrl;
	const hasPath = !!this.filePath;
	return !(hasUrl && hasPath);
}, 'Provide either a link or an uploaded file, not both.');

ResourceSchema.path('filePath').validate(function validator() {
	const hasUrl = !!this.fileUrl;
	const hasPath = !!this.filePath;
	return !(hasUrl && hasPath);
}, 'Provide either a link or an uploaded file, not both.');

module.exports = mongoose.model('Resource', ResourceSchema);
