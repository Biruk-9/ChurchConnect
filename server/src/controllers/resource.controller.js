const { success, error } = require('../utils/response.util');
const resourceService = require('../services/resource.service');
const { getPublicUrl } = require('../services/fileUpload.service');

async function listPublic(req, res) {
	const items = await resourceService.listPublicResources();
	return success(res, items);
}

async function listMembers(req, res) {
	const items = await resourceService.listMemberResources();
	return success(res, items);
}

async function create(req, res) {
	const { title, description, category, accessLevel, mediaType, fileUrl } = req.body || {};
	if (!title || !accessLevel || !mediaType) return error(res, 400, 'title, accessLevel, mediaType required');
	let finalUrl = fileUrl;
	if (req.file && req.file.filename) {
		finalUrl = getPublicUrl(req.file.filename);
	}
	const resource = await resourceService.createResource({ title, description, category, accessLevel, mediaType, fileUrl: finalUrl, userId: req.user?.id });
	return success(res, resource, 'Resource created', 201);
}

async function update(req, res) {
	const { id } = req.params;
	const updates = { ...req.body };
	if (req.file && req.file.filename) {
		updates.fileUrl = getPublicUrl(req.file.filename);
	}
	const item = await resourceService.updateResource(id, updates);
	if (!item) return error(res, 404, 'Resource not found');
	return success(res, item, 'Resource updated');
}

async function remove(req, res) {
	const { id } = req.params;
	const item = await resourceService.deleteResource(id);
	if (!item) return error(res, 404, 'Resource not found');
	return success(res, null, 'Resource deleted');
}

module.exports = { listPublic, listMembers, create, update, remove };
