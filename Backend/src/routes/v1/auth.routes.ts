import { Router } from 'express';
import { AuthController } from '../../controllers/auth.controller';
import { InvitationController } from '../../controllers/invitation.controller';
import { ActivationController } from '../../controllers/activation.controller';
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
router.post('/login/request-otp', forgotPasswordRateLimiter, AuthController.requestLoginOtp);
router.post('/login/verify-otp', otpVerifyRateLimiter, AuthController.loginWithOtp);
router.post('/refresh', AuthController.refresh);
router.post('/dev-login', AuthController.devLogin);

// Public Self-Registration Endpoints (Email OTP)
router.post('/register/request-otp', forgotPasswordRateLimiter, AuthController.registerRequestOtp);
router.post('/register/verify-otp', otpVerifyRateLimiter, AuthController.registerVerifyOtp);
router.post('/register/complete', loginRateLimiter, AuthController.registerComplete);

// Public Multi-Step Account Activation Endpoints
router.post('/activate/validate-code', activationRateLimiter, ActivationController.validateCode);
router.post('/activate/send-otp', forgotPasswordRateLimiter, ActivationController.sendOtp);
router.post('/activate/verify-otp', otpVerifyRateLimiter, ActivationController.verifyOtp);
router.post('/activate/complete', activationRateLimiter, ActivationController.complete);

// Institutional Account Activation Endpoints (Verified Email + Activation Code)
router.post('/institutional-activate/request-otp', forgotPasswordRateLimiter, ActivationController.requestInstitutionalActivationOtp);
router.post('/institutional-activate/verify-otp', otpVerifyRateLimiter, ActivationController.verifyInstitutionalActivationOtp);
router.post('/institutional-activate/complete', activationRateLimiter, ActivationController.completeInstitutionalActivation);

// Backward-Compatible Legacy Activation Endpoint
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
router.post('/terms/accept', authenticateRequest, AuthController.acceptTerms);
router.get('/terms/status', authenticateRequest, AuthController.getTermsStatus);

// Authenticated Invitation Management Endpoints
router.post('/invitations', authenticateRequest, invitationCreationRateLimiter, InvitationController.create);
router.get('/invitations', authenticateRequest, InvitationController.list);
router.get('/invitations/:id', authenticateRequest, InvitationController.getById);
router.post('/invitations/:id/reissue', authenticateRequest, invitationReissueRateLimiter, InvitationController.reissue);
router.post('/invitations/:id/revoke', authenticateRequest, InvitationController.revoke);

export const authRouter = router;

