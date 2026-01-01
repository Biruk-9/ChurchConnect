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

const verseCtrl = require('../controllers/verse.controller');

router.get('/verse', verseCtrl.getToday);

module.exports = router;
