import { Router } from 'express';
import { InstitutionConfigController } from '../../controllers/institutionConfig.controller';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope, requireActiveCollege } from '../../middleware/tenant.middleware';
import { requireCollegeAdmin } from '../../middleware/role.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { updateInstitutionConfigSchema } from '../../validations/institutionConfig.validation';

const router = Router();

// All routes require authentication and college tenant scope
router.use(authenticateRequest);
router.use(requireActiveCollege);
router.use(requireCollegeScope);

// Presets retrieval
router.get('/presets', InstitutionConfigController.getPresets);

// Get current effective tenant configuration (accessible to all authenticated college members)
router.get('/', InstitutionConfigController.getConfig);

// Update institution configuration (restricted strictly to COLLEGE_ADMIN and SUPER_ADMIN)
router.put(
  '/',
  requireCollegeAdmin,
  validateBody(updateInstitutionConfigSchema),
  InstitutionConfigController.updateConfig
);

export default router;
