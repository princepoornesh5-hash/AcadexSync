import { Router } from 'express';
import multer from 'multer';
import { ImportController } from '../../controllers/import.controller';
import { authenticateToken } from '../../middleware/auth.middleware';
import { requireRoles } from '../../middleware/role.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { AppRole } from '../../constants/roles';
import { IMPORT_CONSTRAINTS } from '../../constants/import.constants';
import {
  uploadImportSchema,
  updateSheetAndMappingsSchema,
  validateAndPreviewSchema,
  resolveRowSchema,
  confirmImportSchema,
} from '../../validations/import.validation';

const router = Router();

// Multer memory storage configuration for spreadsheet file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: IMPORT_CONSTRAINTS.MAX_FILE_SIZE_BYTES,
  },
  fileFilter: (_req, file, cb) => {
    const lower = file.originalname.toLowerCase();
    const isSupported = IMPORT_CONSTRAINTS.SUPPORTED_EXTENSIONS.some((ext) => lower.endsWith(ext));
    if (isSupported) {
      cb(null, true);
    } else {
      cb(new Error(`Unsupported file format. Allowed formats: ${IMPORT_CONSTRAINTS.SUPPORTED_EXTENSIONS.join(', ')}`));
    }
  },
});

router.use(authenticateToken);
router.use(requireCollegeScope);

// Only Academic staff / Admins can access import operations (Students forbidden)
router.use(
  requireRoles(
    AppRole.SUPER_ADMIN,
    AppRole.COLLEGE_ADMIN,
    AppRole.HOD,
    AppRole.FACULTY
  )
);

// 1. Upload & initialize
router.post(
  '/upload',
  upload.single('file'),
  validateBody(uploadImportSchema),
  ImportController.upload
);

// 2. List batches
router.get('/', ImportController.listBatches);

// 3. Batch details
router.get('/:id', ImportController.getBatch);

// 4. Update selected sheet and column mappings
router.put(
  '/:id/mappings',
  validateBody(updateSheetAndMappingsSchema),
  ImportController.updateSheetAndMappings
);

// 5. Validate staged rows and generate preview
router.post(
  '/:id/validate',
  validateBody(validateAndPreviewSchema),
  ImportController.validateAndPreview
);

router.get('/:id/preview', ImportController.validateAndPreview);

// 6. Resolve individual ambiguous row
router.post(
  '/:id/resolve-row',
  validateBody(resolveRowSchema),
  ImportController.resolveRow
);

// 7. Explicit Confirmation & Persistence
router.post(
  '/:id/confirm',
  validateBody(confirmImportSchema),
  ImportController.confirmImport
);

export default router;
