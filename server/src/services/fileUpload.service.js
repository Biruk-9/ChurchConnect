const path = require('path');
const fs = require('fs');
const multer = require('multer');
const env = require('../config/env');

const uploadsDir = path.join(process.cwd(), 'server', 'uploads');
if (!fs.existsSync(uploadsDir)) {
	fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
	destination: function (req, file, cb) {
		cb(null, uploadsDir);
	},
	filename: function (req, file, cb) {
		const safeName = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
		cb(null, `${Date.now()}_${safeName}`);
	}
});

const upload = multer({ storage });

function getPublicUrl(filename) {
	// For local driver, we expose a simple static URL path
	return `/uploads/${filename}`;
}

module.exports = { upload, getPublicUrl };
