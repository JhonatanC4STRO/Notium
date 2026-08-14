const { Router } = require('express');
const healthController = require('../controllers/health.controller');

const router = Router();

router.get('/health', healthController.verificarSalud);

module.exports = router;
