const TestQuestion = require('../models/TestQuestion');
const TechnicianProfile = require('../models/TechnicianProfile');
const User = require('../models/User');

async function getQuestions(req, res) {
  try {
    const profile = await TechnicianProfile.findOne({ userId: req.user._id });
    if (!profile) {
      return res.status(404).json({ message: 'Profile not found' });
    }
    if (profile.status !== 'approved' && profile.status !== 'test_failed') {
      return res.status(403).json({ message: 'Not eligible for test' });
    }

    const questions = await TestQuestion.find().limit(15);
    res.json({
      questions: questions.map((q) => ({
        id: q._id.toString(),
        question: q.question,
        options: q.options,
        category: q.category,
      })),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function submitTest(req, res) {
  try {
    const { answers } = req.body;
    if (!Array.isArray(answers) || answers.length === 0) {
      return res.status(400).json({ message: 'Answers required' });
    }

    const profile = await TechnicianProfile.findOne({ userId: req.user._id });
    if (!profile) {
      return res.status(404).json({ message: 'Profile not found' });
    }
    if (profile.status !== 'approved' && profile.status !== 'test_failed') {
      return res.status(403).json({ message: 'Not eligible for test' });
    }

    const questionIds = answers.map((a) => a.questionId);
    const questions = await TestQuestion.find({ _id: { $in: questionIds } });
    const questionMap = new Map(questions.map((q) => [q._id.toString(), q]));

    let correct = 0;
    for (const ans of answers) {
      const q = questionMap.get(ans.questionId);
      if (q && q.correctIndex === ans.optionIndex) correct++;
    }

    const total = questions.length || answers.length;
    const score = Math.round((correct / total) * 100);
    const passing = Number(process.env.PASSING_TEST_SCORE) || 60;
    const passed = score >= passing;

    profile.testScore = score;
    profile.status = passed ? 'test_passed' : 'test_failed';
    if (passed) profile.testPassedAt = new Date();
    await profile.save();

    if (passed) {
      await User.findByIdAndUpdate(req.user._id, { isAvailable: true });
    }

    res.json({
      score,
      passed,
      passingScore: passing,
      message: passed
        ? 'Congratulations! You passed the test.'
        : 'Test failed. Contact admin or retry when allowed.',
      technicianProfile: profile.toPublicJSON(),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

module.exports = { getQuestions, submitTest };
