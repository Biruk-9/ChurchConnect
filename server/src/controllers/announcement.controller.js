const Announcement = require('../models/Announcement');
const { success, error } = require('../utils/response.util');

async function list(req, res) {
	const items = await Announcement.find({}).sort({ date: -1 });
	return success(res, items);
}

async function create(req, res) {
	const { title, content, date, imageUrl } = req.body || {};
	if (!title || !content || !date) return error(res, 400, 'title, content, date required');
	const item = new Announcement({ title, content, date, imageUrl, createdBy: req.user?.id });
	await item.save();
	return success(res, item, 'Announcement created', 201);
}

async function update(req, res) {
	const { id } = req.params;
	const item = await Announcement.findByIdAndUpdate(id, req.body, { new: true });
	if (!item) return error(res, 404, 'Announcement not found');
	return success(res, item, 'Announcement updated');
}

async function remove(req, res) {
	const { id } = req.params;
	const item = await Announcement.findByIdAndDelete(id);
	if (!item) return error(res, 404, 'Announcement not found');
	return success(res, null, 'Announcement deleted');
}

module.exports = { list, create, update, remove };
