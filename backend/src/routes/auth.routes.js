const express = require('express');
const authController = require('../controllers/auth.controller');
const { technicianRegisterUpload } = require('../utils/upload');
const { auth } = require('../middleware/auth');

const router = express.Router();

router.post('/customer/send-otp', authController.sendCustomerOtp);
router.post('/customer/verify-otp', authController.verifyCustomerOtp);
router.post('/customer/register', authController.registerCustomer);
router.post(
  '/technician/register',
  technicianRegisterUpload,
  authController.registerTechnician
);
router.post('/login', authController.login);
router.get('/me', auth(), authController.getMe);
router.post('/fcm-token', auth(), authController.updateFcmToken);

module.exports = router;
