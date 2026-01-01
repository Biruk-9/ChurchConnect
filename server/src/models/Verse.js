const mongoose = require('mongoose');

const VerseSchema = new mongoose.Schema({
	date: { type: Date, required: true, unique: true },
	ref: { type: String, required: true },
	text: { type: String, required: true },
	posted: { type: Boolean, default: false },
}, { timestamps: true });

module.exports = mongoose.model('Verse', VerseSchema);
