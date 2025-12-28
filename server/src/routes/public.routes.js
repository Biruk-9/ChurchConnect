const express = require('express');
const { list } = require('../controllers/announcement.controller');
const { listUpcoming } = require('../controllers/event.controller');
const resourceCtrl = require('../controllers/resource.controller');
const { success } = require('../utils/response.util');

const router = express.Router();

// Announcements (public)
router.get('/announcements', list);

// Events (public)
router.get('/events', listUpcoming);

// Resources (public)
router.get('/resources', resourceCtrl.listPublic);

// Bible Verse of the Day (simple deterministic rotation)
const verses = [
	{ ref: 'John 3:16', text: 'For God so loved the world that he gave his one and only Son...' },
	{ ref: 'Psalm 23:1', text: 'The Lord is my shepherd; I shall not want.' },
	{ ref: 'Philippians 4:13', text: 'I can do all things through Christ who strengthens me.' },
	{ ref: 'Proverbs 3:5-6', text: 'Trust in the Lord with all your heart...'
	},
	{ ref: 'Isaiah 41:10', text: 'Fear not, for I am with you...' },
];

router.get('/verse', (req, res) => {
	const now = new Date();
	const start = new Date(now.getFullYear(), 0, 0);
	const diff = (now - start) + ((start.getTimezoneOffset() - now.getTimezoneOffset()) * 60 * 1000);
	const day = Math.floor(diff / (1000 * 60 * 60 * 24));
	const verse = verses[day % verses.length];
	return success(res, verse, 'Verse of the day');
});

module.exports = router;
