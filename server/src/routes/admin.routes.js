const express = require('express');
const authenticate = require('../middleware/authenticate');
const authorizeAdmin = require('../middleware/authorizeAdmin');
const announcementCtrl = require('../controllers/announcement.controller');
const eventCtrl = require('../controllers/event.controller');
const resourceCtrl = require('../controllers/resource.controller');
const verseCtrl = require('../controllers/verse.controller');
const notifyCtrl = require('../controllers/notification.controller');
const dashboardCtrl = require('../controllers/dashboard.controller');
const userCtrl = require('../controllers/user.controller');
const { upload } = require('../services/fileUpload.service');

const router = express.Router();

router.use(authenticate, authorizeAdmin);

// Dashboard summary
router.get('/dashboard/summary', dashboardCtrl.summary);
router.get('/dashboard/recent', dashboardCtrl.recentActivity);

// Announcements admin (image optional upload)
router.post('/announcements', upload.single('image'), announcementCtrl.create);
router.put('/announcements/:id', upload.single('image'), announcementCtrl.update);
router.delete('/announcements/:id', announcementCtrl.remove);

// Events admin
router.post('/events', eventCtrl.create);
router.put('/events/:id', eventCtrl.update);
router.delete('/events/:id', eventCtrl.remove);

// Verses admin
router.get('/verses', verseCtrl.listAdmin);
router.post('/verses', verseCtrl.create);
router.put('/verses/:id', verseCtrl.update);
router.delete('/verses/:id', verseCtrl.remove);

// Resources admin (supports file upload)
router.post('/resources', upload.single('file'), resourceCtrl.create);
router.put('/resources/:id', upload.single('file'), resourceCtrl.update);
router.delete('/resources/:id', resourceCtrl.remove);

// Notifications
router.post('/notifications/announcements', notifyCtrl.notifyAnnouncement);
router.post('/notifications/events', notifyCtrl.notifyEvent);

// Members (user management)
router.get('/users', userCtrl.list);
router.post('/users', userCtrl.create);
router.put('/users/:id', userCtrl.update);
router.delete('/users/:id', userCtrl.remove);

module.exports = router;
