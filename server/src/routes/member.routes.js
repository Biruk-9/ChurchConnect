const express = require('express');
const authenticate = require('../middleware/authenticate');
const authorizeMember = require('../middleware/authorizeMember');
const resourceCtrl = require('../controllers/resource.controller');

const router = express.Router();

router.use(authenticate, authorizeMember);

// Members-only resources
router.get('/resources', resourceCtrl.listMembers);

module.exports = router;
