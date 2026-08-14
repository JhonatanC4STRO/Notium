const { Router } = require('express');
const multer = require('multer');
const attachmentsController = require('../controllers/attachments.controller');
const { requerirAutenticacion } = require('../middlewares/auth');
const AppError = require('../utils/app-error');
const env = require('../config/env');

const router = Router();

// El binario cabe en memoria (límite 10 MB, RNF-05); multer corta la carga
// excedida ANTES de bufferizar el resto.
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: env.maxAdjuntoBytes, files: 1 },
});

/** Traduce los errores de multer al esquema Error de openapi.yaml. */
function recibirArchivo(req, res, next) {
  upload.single('archivo')(req, res, (err) => {
    if (!err) return next();
    if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
      return next(
        new AppError(413, 'ADJUNTO_EXCEDE_LIMITE', 'El archivo excede el límite de 10 MB por adjunto.')
      );
    }
    next(err);
  });
}

router.post('/', requerirAutenticacion, recibirArchivo, attachmentsController.subir);
router.get('/:uuid', requerirAutenticacion, attachmentsController.descargar);
router.delete('/:uuid', requerirAutenticacion, attachmentsController.eliminar);

module.exports = router;
