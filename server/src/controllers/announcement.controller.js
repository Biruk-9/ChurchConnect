const Announcement = require('../models/Announcement');
const { success, error } = require('../utils/response.util');
const { getPublicUrl } = require('../services/fileUpload.service');

async function list(req, res) {
	const items = await Announcement.find({}).sort({ createdAt: -1 });
	return success(res, items);
}

async function create(req, res) {
	const { title, content, imageUrl } = req.body || {};
	if (!title || !content) return error(res, 400, 'title and content are required');
	const uploadedImage = req.file ? getPublicUrl(req.file.filename) : null;
	const item = new Announcement({
		title,
		content,
		imageUrl: uploadedImage || imageUrl,
	});
	await item.save();
	return success(res, item, 'Announcement created', 201);
}

async function update(req, res) {
	const { id } = req.params;
	const { title, content, imageUrl } = req.body || {};
	const updates = {};
	if (title) updates.title = title;
	if (content) updates.content = content;
	if (req.file) updates.imageUrl = getPublicUrl(req.file.filename);
	else if (imageUrl !== undefined) updates.imageUrl = imageUrl;
	const item = await Announcement.findByIdAndUpdate(id, updates, { new: true });
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
