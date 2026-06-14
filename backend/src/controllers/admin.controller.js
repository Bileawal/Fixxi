const User = require('../models/User');
const TechnicianProfile = require('../models/TechnicianProfile');
const ServiceRequest = require('../models/ServiceRequest');
const Review = require('../models/Review');
const Report = require('../models/Report');
const Notification = require('../models/Notification');

async function listTechnicians(req, res) {
  try {
    const { status } = req.query;
    const filter = {};
    if (status) filter.status = status;

    const profiles = await TechnicianProfile.find(filter)
      .sort({ createdAt: -1 })
      .populate('userId', '-password');

    const list = profiles.map((p) => ({
      ...p.toPublicJSON(),
      user: p.userId ? {
        id: p.userId._id.toString(),
        name: p.userId.name,
        email: p.userId.email,
        phone: p.userId.phone,
        address: p.userId.address,
        fatherName: p.userId.fatherName,
      } : null,
    }));

    res.json({ technicians: list });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function getTechnician(req, res) {
  try {
    const profile = await TechnicianProfile.findById(req.params.id).populate(
      'userId',
      '-password'
    );
    if (!profile) {
      return res.status(404).json({ message: 'Technician not found' });
    }

    res.json({
      ...profile.toPublicJSON(),
      user: profile.userId
        ? {
            id: profile.userId._id.toString(),
            name: profile.userId.name,
            email: profile.userId.email,
            phone: profile.userId.phone,
            address: profile.userId.address,
            fatherName: profile.userId.fatherName,
            rating: profile.userId.rating,
            reviewCount: profile.userId.reviewCount,
          }
        : null,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function getTechnicianByUserId(req, res) {
  try {
    const profile = await TechnicianProfile.findOne({
      userId: req.params.userId,
    }).populate('userId', '-password');
    if (!profile) {
      return res.status(404).json({ message: 'Profile not found' });
    }
    res.json({
      ...profile.toPublicJSON(),
      user: profile.userId?.toPublicJSON?.() || profile.userId,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function approveTechnician(req, res) {
  try {
    const profile = await TechnicianProfile.findById(req.params.id);
    if (!profile) {
      return res.status(404).json({ message: 'Technician not found' });
    }
    if (profile.status !== 'pending_admin') {
      return res.status(400).json({ message: 'Not pending approval' });
    }

    profile.status = 'approved';
    profile.rejectionReason = undefined;
    await profile.save();

    await User.findByIdAndUpdate(profile.userId, { isAvailable: false });

    res.json({ message: 'Technician approved', profile: profile.toPublicJSON() });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function rejectTechnician(req, res) {
  try {
    const { reason } = req.body;
    const profile = await TechnicianProfile.findById(req.params.id);
    if (!profile) {
      return res.status(404).json({ message: 'Technician not found' });
    }

    profile.status = 'rejected';
    profile.rejectionReason = reason || 'Application rejected by admin';
    await profile.save();

    await User.findByIdAndUpdate(profile.userId, { isAvailable: false });

    res.json({ message: 'Technician rejected', profile: profile.toPublicJSON() });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function listUsers(req, res) {
  try {
    const { role } = req.query;
    const filter = role ? { role } : { role: { $ne: 'admin' } };
    const users = await User.find(filter).select('-password').sort({ createdAt: -1 });
    res.json({ users: users.map((u) => u.toAdminJSON()) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function getUserProfile(req, res) {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user || user.role === 'admin') {
      return res.status(404).json({ message: 'User not found' });
    }

    let profile = null;
    if (user.role === 'technician') {
      profile = await TechnicianProfile.findOne({ userId: user._id });
    }

    const requestFilter =
      user.role === 'customer'
        ? { customerId: user._id }
        : { technicianId: user._id };

    const requests = await ServiceRequest.find(requestFilter)
      .sort({ createdAt: -1 })
      .limit(30);

    const reviews =
      user.role === 'technician'
        ? await Review.find({ technicianId: user._id }).sort({ createdAt: -1 }).limit(20)
        : await Review.find({ customerId: user._id }).sort({ createdAt: -1 }).limit(20);

    const reportsAsSubject = await Report.find({ reportedUserId: user._id })
      .sort({ createdAt: -1 })
      .limit(20);
    const reportsByUser = await Report.find({ reporterId: user._id })
      .sort({ createdAt: -1 })
      .limit(20);

    res.json({
      user: user.toAdminJSON(),
      technicianProfile: profile?.toPublicJSON() || null,
      activities: {
        requests: requests.map((r) => r.toPublicJSON()),
        reviews: reviews.map((r) => r.toPublicJSON()),
        reportsAgainst: reportsAsSubject.map((r) => r.toPublicJSON()),
        reportsFiled: reportsByUser.map((r) => r.toPublicJSON()),
      },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function suspendUser(req, res) {
  try {
    const { duration, reason } = req.body;
    if (!duration || !['week', 'month', 'permanent'].includes(duration)) {
      return res.status(400).json({ message: 'duration: week, month, or permanent' });
    }

    const user = await User.findById(req.params.id);
    if (!user || user.role === 'admin') {
      return res.status(404).json({ message: 'User not found' });
    }

    let suspendedUntil = null;
    const now = new Date();
    if (duration === 'week') {
      suspendedUntil = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    } else if (duration === 'month') {
      suspendedUntil = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    }

    user.isSuspended = true;
    user.suspensionType = duration;
    user.suspendedUntil = suspendedUntil;
    user.suspensionReason = reason || 'Suspended by admin';
    if (user.role === 'technician') {
      user.isAvailable = false;
    }
    await user.save();

    await Notification.create({
      userId: user._id,
      title: 'Account suspended',
      body: user.suspensionReason,
    });

    res.json({ message: 'User suspended', user: user.toAdminJSON() });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function unsuspendUser(req, res) {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.isSuspended = false;
    user.suspensionType = null;
    user.suspendedUntil = null;
    user.suspensionReason = '';
    await user.save();

    await Notification.create({
      userId: user._id,
      title: 'Account restored',
      body: 'Your account suspension has been lifted by admin.',
    });

    res.json({ message: 'Suspension lifted', user: user.toAdminJSON() });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function listReports(req, res) {
  try {
    const { status } = req.query;
    const filter = status ? { status } : {};
    const reports = await Report.find(filter).sort({ createdAt: -1 });
    res.json({ reports: reports.map((r) => r.toPublicJSON()) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function updateReport(req, res) {
  try {
    const { status, adminNote } = req.body;
    const report = await Report.findById(req.params.id);
    if (!report) {
      return res.status(404).json({ message: 'Report not found' });
    }
    if (status) report.status = status;
    if (adminNote != null) report.adminNote = adminNote;
    await report.save();
    res.json({ report: report.toPublicJSON() });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function notifyUser(req, res) {
  try {
    const { title, body } = req.body;
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    if (!title?.trim() || !body?.trim()) {
      return res.status(400).json({ message: 'title and body required' });
    }

    await Notification.create({
      userId: user._id,
      title: title.trim(),
      body: body.trim(),
    });

    res.json({ message: 'Notification sent' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

module.exports = {
  listTechnicians,
  getTechnician,
  getTechnicianByUserId,
  approveTechnician,
  rejectTechnician,
  listUsers,
  getUserProfile,
  suspendUser,
  unsuspendUser,
  listReports,
  updateReport,
  notifyUser,
};
