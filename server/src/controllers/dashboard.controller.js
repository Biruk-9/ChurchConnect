const Announcement = require('../models/Announcement');
const Event = require('../models/Event');
const Resource = require('../models/Resource');
const User = require('../models/user');
const { success, error } = require('../utils/response.util');

async function summary(req, res) {
	try {
		const now = new Date();
		const [announcementCount, upcomingEvents, resourceCount, memberCount] = await Promise.all([
			Announcement.countDocuments(),
			Event.countDocuments({ date: { $gte: now } }),
			Resource.countDocuments(),
			User.countDocuments({ role: 'member', isActive: true }),
		]);

		return success(res, {
			announcements: announcementCount,
			upcomingEvents,
			resources: resourceCount,
			members: memberCount,
		});
	} catch (e) {
		return error(res, 500, 'Failed to load dashboard summary');
	}
}

async function recentActivity(req, res) {
	try {
		const [announcements, events, resources] = await Promise.all([
			Announcement.find().sort({ createdAt: -1 }).limit(5),
			Event.find().sort({ createdAt: -1 }).limit(5),
			Resource.find().sort({ createdAt: -1 }).limit(5),
		]);
		return success(res, { announcements, events, resources });
	} catch (e) {
		return error(res, 500, 'Failed to load recent activity');
	}
}

module.exports = { summary, recentActivity };
