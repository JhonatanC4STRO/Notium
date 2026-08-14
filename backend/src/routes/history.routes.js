const { Router } = require('express');
const historyController = require('../controllers/history.controller');
const { requerirAutenticacion } = require('../middlewares/auth');

const router = Router();

router.get('/:nota_uuid', requerirAutenticacion, historyController.obtenerHistorial);

module.exports = router;
