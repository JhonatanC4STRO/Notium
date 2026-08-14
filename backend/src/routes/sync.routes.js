const { Router } = require('express');
const syncController = require('../controllers/sync.controller');
const { requerirAutenticacion } = require('../middlewares/auth');

const router = Router();

router.post('/push', requerirAutenticacion, syncController.enviarLote);
router.get('/pull', requerirAutenticacion, syncController.obtenerCambios);

module.exports = router;
