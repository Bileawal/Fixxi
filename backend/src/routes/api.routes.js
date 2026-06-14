const express = require('express');
const requestsController = require('../controllers/requests.controller');
const reportsController = require('../controllers/reports.controller');
const { auth } = require('../middleware/auth');

const router = express.Router();

router.use(auth());

router.get('/technicians/nearby', auth(['customer']), requestsController.nearbyTechnicians);
router.get('/technicians/:id/reviews', requestsController.getReviews);
router.get('/technicians/:id', requestsController.getTechnicianPublic);

router.post('/requests', auth(['customer']), requestsController.createRequest);
router.get('/requests', requestsController.myRequests);
router.patch('/requests/:id/status', requestsController.updateRequestStatus);

router.patch('/technician/availability', auth(['technician']), requestsController.setAvailability);

router.get('/chat/:requestId', requestsController.getMessages);
router.post('/chat/:requestId', requestsController.sendMessage);

router.post('/reviews', auth(['customer']), requestsController.addReview);

router.post('/reports', auth(['customer']), reportsController.submitReport);

router.get('/notifications', requestsController.getNotifications);
router.patch('/notifications/read', requestsController.markNotificationsRead);

module.exports = router;
