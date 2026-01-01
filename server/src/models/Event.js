const mongoose = require('mongoose');

const EventSchema = new mongoose.Schema({
	title: { type: String, required: true },
	description: { type: String },
	date: { type: Date, required: true },
	time: { type: String, required: true }, // e.g., "18:30"
	location: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('Event', EventSchema);
