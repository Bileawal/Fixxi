const express = require('express');
const adminController = require('../controllers/admin.controller');
const { auth } = require('../middleware/auth');

const router = express.Router();

router.use(auth(['admin']));

router.get('/users', adminController.listUsers);
router.get('/users/:id', adminController.getUserProfile);
router.patch('/users/:id/suspend', adminController.suspendUser);
router.patch('/users/:id/unsuspend', adminController.unsuspendUser);
router.post('/users/:id/notify', adminController.notifyUser);

router.get('/reports', adminController.listReports);
router.patch('/reports/:id', adminController.updateReport);

router.get('/technicians', adminController.listTechnicians);
router.get('/technicians/:id', adminController.getTechnician);
router.patch('/technicians/:id/approve', adminController.approveTechnician);
router.patch('/technicians/:id/reject', adminController.rejectTechnician);

module.exports = router;
