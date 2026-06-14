const express = require('express');
const testController = require('../controllers/test.controller');
const { auth } = require('../middleware/auth');

const router = express.Router();

router.use(auth(['technician']));

router.get('/questions', testController.getQuestions);
router.post('/submit', testController.submitTest);

module.exports = router;
