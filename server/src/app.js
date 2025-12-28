const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const env = require('./config/env');
const { initFirebase } = require('./config/firebase');

const publicRoutes = require('./routes/public.routes');
const authRoutes = require('./routes/auth.routes');
const adminRoutes = require('./routes/admin.routes');
const memberRoutes = require('./routes/member.routes');

const app = express();

// Security & middleware
app.use(helmet());
app.use(cors({ origin: env.CORS_ORIGIN, credentials: false }));
app.use(express.json());
app.use(morgan('dev'));

// Static serving for local uploads
app.use('/uploads', express.static(path.join(process.cwd(), 'server', 'uploads')));

// Initialize FCM if configured
initFirebase();

// Routes
app.use('/api/public', publicRoutes);
app.use('/api/auth', authRoutes);
app.use(env.ADMIN_BASE_PATH, adminRoutes); // hidden admin base path
app.use('/api/member', memberRoutes);

// Health
app.get('/health', (req, res) => res.json({ ok: true }));

// 404 handler
app.use((req, res) => {
	res.status(404).json({ success: false, message: 'Not Found' });
});

module.exports = app;
