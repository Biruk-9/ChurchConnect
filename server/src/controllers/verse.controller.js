const Verse = require('../models/Verse');
const { success, error } = require('../utils/response.util');

function startOfDay(date = new Date()) {
	return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function endOfDay(date = new Date()) {
	return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59, 999);
}

async function getToday(req, res) {
	const todayStart = startOfDay();
	const todayEnd = endOfDay();
	const verse = await Verse.findOne({ date: { $gte: todayStart, $lte: todayEnd } });
	if (!verse) return error(res, 404, 'No verse scheduled for today');
	if (!verse.posted) {
		verse.posted = true;
		await verse.save();
	}
	return success(res, { ref: verse.ref, text: verse.text }, 'Verse of the day');
}

async function listAdmin(req, res) {
	const items = await Verse.find({}).sort({ date: 1 });
	return success(res, items);
}

async function create(req, res) {
	const { date, ref, text } = req.body || {};
	if (!date || !ref || !text) return error(res, 400, 'date, ref, and text are required');
	const dateValue = new Date(date);
	if (Number.isNaN(dateValue.getTime())) return error(res, 400, 'Invalid date');
	const existing = await Verse.findOne({ date: { $gte: startOfDay(dateValue), $lte: endOfDay(dateValue) } });
	if (existing) return error(res, 400, 'Verse already scheduled for that date');
	const item = new Verse({ date: dateValue, ref, text, posted: false });
	await item.save();
	return success(res, item, 'Verse scheduled', 201);
}

async function update(req, res) {
	const { id } = req.params;
	const updates = {};
	const payload = req.body || {};
	if (payload.ref !== undefined) updates.ref = payload.ref;
	if (payload.text !== undefined) updates.text = payload.text;
	if (payload.date !== undefined) {
		const dateValue = new Date(payload.date);
		if (Number.isNaN(dateValue.getTime())) return error(res, 400, 'Invalid date');
		updates.date = dateValue;
	}
	const verse = await Verse.findById(id);
	if (!verse) return error(res, 404, 'Verse not found');
	if (verse.posted) return error(res, 400, 'Verse already posted; cannot edit');
	Object.assign(verse, updates);
	await verse.save();
	return success(res, verse, 'Verse updated');
}

async function remove(req, res) {
	const { id } = req.params;
	const verse = await Verse.findById(id);
	if (!verse) return error(res, 404, 'Verse not found');
	if (verse.posted) return error(res, 400, 'Verse already posted; cannot delete');
	await verse.deleteOne();
	return success(res, null, 'Verse deleted');
}

module.exports = { getToday, listAdmin, create, update, remove };
