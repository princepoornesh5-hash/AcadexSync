import { Router } from 'express';
import { WorkspaceController } from '../../controllers/workspace.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

// All workspace routes require valid session authentication
router.use(authenticateToken);

// GET /api/v1/workspaces/my-memberships
router.get('/my-memberships', WorkspaceController.getMyMemberships);

// POST /api/v1/workspaces/switch
router.post('/switch', WorkspaceController.switchWorkspace);

export { router as workspaceRouter };
