const Report = require('../models/Report');
const User = require('../models/User');
const Notification = require('../models/Notification');

async function submitReport(req, res) {
  try {
    const { reportedUserId, reason, reviewId } = req.body;
    if (!reportedUserId || !reason?.trim()) {
      return res.status(400).json({ message: 'reportedUserId and reason required' });
    }

    const reported = await User.findById(reportedUserId);
    if (!reported || reported.role === 'admin') {
      return res.status(400).json({ message: 'Invalid user to report' });
    }

    const report = await Report.create({
      reporterId: req.user._id,
      reporterName: req.user.name,
      reportedUserId,
      reportedUserName: reported.name,
      reason: reason.trim(),
      reviewId: reviewId || undefined,
    });

    const admins = await User.find({ role: 'admin' });
    for (const admin of admins) {
      await Notification.create({
        userId: admin._id,
        title: 'New report',
        body: `${req.user.name} reported ${reported.name}: ${reason.trim().slice(0, 80)}`,
      });
    }

    res.status(201).json({ report: report.toPublicJSON() });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

module.exports = { submitReport };
