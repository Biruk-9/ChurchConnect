const Event = require('../models/Event');
const { success, error } = require('../utils/response.util');

async function listUpcoming(req, res) {
	const today = new Date();
	const items = await Event.find({ date: { $gte: today } }).sort({ date: 1 });
	return success(res, items);
}

async function create(req, res) {
	const { title, description, date, time, location } = req.body || {};
	if (!title || !date || !time) return error(res, 400, 'title, date, time required');
	const item = new Event({ title, description, date, time, location, createdBy: req.user?.id });
	await item.save();
	return success(res, item, 'Event created', 201);
}

async function update(req, res) {
	const { id } = req.params;
	const item = await Event.findByIdAndUpdate(id, req.body, { new: true });
	if (!item) return error(res, 404, 'Event not found');
	return success(res, item, 'Event updated');
}

async function remove(req, res) {
	const { id } = req.params;
	const item = await Event.findByIdAndDelete(id);
	if (!item) return error(res, 404, 'Event not found');
	return success(res, null, 'Event deleted');
}

module.exports = { listUpcoming, create, update, remove };
