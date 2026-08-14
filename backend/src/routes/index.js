const { Router } = require('express');
const healthRoutes = require('./health.routes');
const authRoutes = require('./auth.routes');
const syncRoutes = require('./sync.routes');
const attachmentsRoutes = require('./attachments.routes');
const historyRoutes = require('./history.routes');

const router = Router();

router.use(healthRoutes);
router.use('/auth', authRoutes);
router.use('/sync', syncRoutes);
router.use('/attachments', attachmentsRoutes);
router.use('/history', historyRoutes);

module.exports = router;
