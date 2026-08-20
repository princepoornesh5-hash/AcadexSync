import { Router } from 'express';
import { AuthController } from '../../controllers/auth.controller';
import { InvitationController } from '../../controllers/invitation.controller';
import { authenticateRequest } from '../../middleware/auth.middleware';
import {
  loginRateLimiter,
  forgotPasswordRateLimiter,
  otpVerifyRateLimiter,
  resetPasswordRateLimiter,
  activationRateLimiter,
  changePasswordRateLimiter,
  invitationCreationRateLimiter,
  invitationReissueRateLimiter,
} from '../../middleware/rateLimiter.middleware';

const router = Router();

// Public Authentication Endpoints
router.post('/login', loginRateLimiter, AuthController.login);
router.post('/refresh', AuthController.refresh);

// Public Account Activation Endpoint
router.post('/activate', activationRateLimiter, InvitationController.activate);

// Password Recovery Flow
router.post('/forgot-password', forgotPasswordRateLimiter, AuthController.forgotPassword);
router.post('/verify-password-reset-otp', otpVerifyRateLimiter, AuthController.verifyPasswordResetOtp);
router.post('/reset-password', resetPasswordRateLimiter, AuthController.resetPassword);

// Authenticated Session Endpoints
router.get('/me', authenticateRequest, AuthController.getMe);
router.post('/logout', authenticateRequest, AuthController.logout);
router.post('/logout-all', authenticateRequest, AuthController.logoutAll);
router.post('/change-password', authenticateRequest, changePasswordRateLimiter, AuthController.changePassword);

// Authenticated Invitation Management Endpoints
router.post('/invitations', authenticateRequest, invitationCreationRateLimiter, InvitationController.create);
router.get('/invitations', authenticateRequest, InvitationController.list);
router.get('/invitations/:id', authenticateRequest, InvitationController.getById);
router.post('/invitations/:id/reissue', authenticateRequest, invitationReissueRateLimiter, InvitationController.reissue);
router.post('/invitations/:id/revoke', authenticateRequest, InvitationController.revoke);

export const authRouter = router;

