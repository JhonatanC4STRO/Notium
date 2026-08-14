const { Router } = require('express');
const authController = require('../controllers/auth.controller');
const { requerirAutenticacion } = require('../middlewares/auth');

const router = Router();

// register y login son públicos (security: [] en openapi.yaml).
router.post('/register', authController.registrar);
router.post('/login', authController.iniciarSesion);

// refresh valida el access token por su cuenta (acepta uno expirado);
// no usa el middleware estándar, que rechazaría la expiración.
router.post('/refresh', authController.refrescar);

router.post('/logout', requerirAutenticacion, authController.cerrarSesion);

module.exports = router;
