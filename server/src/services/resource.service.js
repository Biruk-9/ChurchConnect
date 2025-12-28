const Resource = require('../models/Resource');

async function listPublicResources() {
	return Resource.find({ accessLevel: 'public' }).sort({ createdAt: -1 });
}

async function listMemberResources() {
	return Resource.find({ accessLevel: 'members' }).sort({ createdAt: -1 });
}

async function createResource({ title, description, category, accessLevel, mediaType, fileUrl, userId }) {
	const resource = new Resource({ title, description, category, accessLevel, mediaType, fileUrl, createdBy: userId });
	await resource.save();
	return resource;
}

async function updateResource(id, updates) {
	return Resource.findByIdAndUpdate(id, updates, { new: true });
}

async function deleteResource(id) {
	return Resource.findByIdAndDelete(id);
}

module.exports = {
	listPublicResources,
	listMemberResources,
	createResource,
	updateResource,
	deleteResource,
};
