import { Router } from 'express';
import { NoteController } from '../../controllers/note.controller';
import { authenticateToken } from '../../middleware/auth.middleware';
import { requireRoles } from '../../middleware/role.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody, validateQuery } from '../../middleware/validate.middleware';
import { uploadRateLimiter } from '../../middleware/rateLimiter.middleware';
import {
  requestUploadUrlSchema,
  requestReplaceUrlSchema,
  updateNoteSchema,
  noteQuerySchema,
} from '../../validations/note.validation';
import { AppRole } from '../../constants/roles';
import { asyncHandler } from '../../utils/asyncHandler';

const router = Router();

router.use(authenticateToken);
router.use(requireCollegeScope);

// 1. Student Personal Notes Feed (Must come before :id route)
router.get(
  '/students/me',
  requireRoles(AppRole.STUDENT),
  asyncHandler(NoteController.getStudentNotes)
);

// 2. Upload Lifecycle
router.post(
  '/upload-url',
  uploadRateLimiter,
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY),
  validateBody(requestUploadUrlSchema),
  asyncHandler(NoteController.requestUploadUrl)
);

router.post(
  '/:id/complete',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY),
  asyncHandler(NoteController.completeUpload)
);

// 3. Download URL
router.get(
  '/:id/download',
  asyncHandler(NoteController.getDownloadUrl)
);

// 4. Replacement & Versioning
router.post(
  '/:id/replace-url',
  uploadRateLimiter,
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY),
  validateBody(requestReplaceUrlSchema),
  asyncHandler(NoteController.requestReplaceUrl)
);

router.post(
  '/:id/replace-complete',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY),
  asyncHandler(NoteController.completeReplace)
);

// 5. Note CRUD & Query
router.get(
  '/',
  validateQuery(noteQuerySchema),
  asyncHandler(NoteController.listNotes)
);

router.get(
  '/:id',
  asyncHandler(NoteController.getNoteById)
);

router.put(
  '/:id',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY),
  validateBody(updateNoteSchema),
  asyncHandler(NoteController.updateNote)
);

router.patch(
  '/:id',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY),
  validateBody(updateNoteSchema),
  asyncHandler(NoteController.updateNote)
);

router.delete(
  '/:id',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY),
  asyncHandler(NoteController.deleteNote)
);

export const noteRouter = router;
