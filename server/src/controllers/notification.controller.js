const { success, error } = require('../utils/response.util');
const { sendToTopic } = require('../services/notification.service');

async function notifyAnnouncement(req, res) {
	const { title, body } = req.body || {};
	if (!title || !body) return error(res, 400, 'title and body required');
	const result = await sendToTopic('announcements', { title, body });
	return success(res, result, 'Announcement notification attempted');
}

async function notifyEvent(req, res) {
	const { title, body } = req.body || {};
	if (!title || !body) return error(res, 400, 'title and body required');
	const result = await sendToTopic('events', { title, body });
	return success(res, result, 'Event notification attempted');
}

module.exports = { notifyAnnouncement, notifyEvent };
