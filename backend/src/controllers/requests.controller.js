const User = require('../models/User');
const TechnicianProfile = require('../models/TechnicianProfile');
const ServiceRequest = require('../models/ServiceRequest');
const Review = require('../models/Review');
const ChatMessage = require('../models/ChatMessage');
const Notification = require('../models/Notification');
const { haversineKm, checkFee } = require('../utils/helpers');

async function createNotification(userId, title, body, requestId) {
  await Notification.create({ userId, title, body, requestId });
}

async function nearbyTechnicians(req, res) {
  try {
    const { category, urgentOnly } = req.query;
    const customer = req.user;

    const techUsers = await User.find({ role: 'technician' });
    const profiles = await TechnicianProfile.find({
      status: 'test_passed',
    });
    const profileMap = new Map(profiles.map((p) => [p.userId.toString(), p]));

    let list = techUsers
      .filter((t) => profileMap.has(t._id.toString()))
      .map((t) => {
        const profile = profileMap.get(t._id.toString());
        const dist = haversineKm(
          customer.latitude,
          customer.longitude,
          t.latitude,
          t.longitude
        );
        return {
          ...t.toPublicJSON(),
          skills: profile.skills,
          extraSkills: profile.extraSkills,
          distanceKm: Math.round(dist * 10) / 10,
          checkFee: checkFee(dist),
          technicianProfileId: profile.id || profile._id?.toString(),
        };
      })
      .filter((t) => t.distanceKm <= 8);

    if (category) {
      list = list.filter((t) =>
        t.skills.some((s) =>
          s.toLowerCase().includes(category.toLowerCase())
        )
      );
    }

    if (urgentOnly === 'true') {
      list = list.filter((t) => t.isAvailable);
    }

    list.sort((a, b) => a.distanceKm - b.distanceKm);
    res.json({ technicians: list });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function createRequest(req, res) {
  try {
    const { category, description, type, scheduledAt, technicianId, address } =
      req.body;

    if (!category || !description || !type) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    let technician = null;
    let distanceKm = 2.5;
    if (technicianId) {
      technician = await User.findById(technicianId);
      if (!technician || technician.role !== 'technician') {
        return res.status(400).json({ message: 'Invalid technician' });
      }
      if (type === 'urgent' && !technician.isAvailable) {
        return res.status(400).json({
          message: 'Technician is offline. Please use Scheduled booking.',
        });
      }
      distanceKm = haversineKm(
        req.user.latitude,
        req.user.longitude,
        technician.latitude,
        technician.longitude
      );
    }

    const request = await ServiceRequest.create({
      customerId: req.user._id,
      customerName: req.user.name,
      category,
      description,
      type,
      scheduledAt: scheduledAt ? new Date(scheduledAt) : null,
      technicianId: technician?._id,
      technicianName: technician?.name,
      address: address || req.user.address,
      distanceKm,
    });

    if (technician) {
      await createNotification(
        technician._id,
        type === 'urgent' ? 'Urgent request' : 'New request',
        `${req.user.name}: ${description}`,
        request._id
      );
    }

    res.status(201).json({ request: request.toPublicJSON() });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function myRequests(req, res) {
  try {
    let filter = {};
    if (req.user.role === 'customer') {
      filter = { customerId: req.user._id };
    } else if (req.user.role === 'technician') {
      filter = { technicianId: req.user._id };
    }

    const requests = await ServiceRequest.find(filter).sort({ createdAt: -1 });
    res.json({ requests: requests.map((r) => r.toPublicJSON()) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function updateRequestStatus(req, res) {
  try {
    const { status } = req.body;
    const request = await ServiceRequest.findById(req.params.id);
    if (!request) {
      return res.status(404).json({ message: 'Request not found' });
    }

    const valid = ['pending', 'accepted', 'rejected', 'inProgress', 'completed', 'cancelled'];
    if (!valid.includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    if (req.user.role === 'technician' && request.technicianId?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Forbidden' });
    }

    request.status = status;
    await request.save();

    await createNotification(
      request.customerId,
      'Request update',
      `Your request is now ${status}`,
      request._id
    );

    res.json({ request: request.toPublicJSON() });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function setAvailability(req, res) {
  try {
    const { available } = req.body;
    const profile = await TechnicianProfile.findOne({ userId: req.user._id });
    if (!profile || profile.status !== 'test_passed') {
      return res.status(403).json({ message: 'Not active technician' });
    }

    await User.findByIdAndUpdate(req.user._id, { isAvailable: !!available });
    const user = await User.findById(req.user._id);
    res.json({ user: user.toPublicJSON() });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function getMessages(req, res) {
  try {
    const messages = await ChatMessage.find({
      requestId: req.params.requestId,
    }).sort({ createdAt: 1 });
    res.json({
      messages: messages.map((m) => m.toPublicJSON()),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function sendMessage(req, res) {
  try {
    const { text } = req.body;
    if (!text?.trim()) {
      return res.status(400).json({ message: 'Text required' });
    }

    const message = await ChatMessage.create({
      requestId: req.params.requestId,
      senderId: req.user._id,
      senderName: req.user.name,
      text: text.trim(),
    });

    res.status(201).json({ message: message.toPublicJSON() });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function addReview(req, res) {
  try {
    const { technicianId, requestId, rating, comment, repairCost, actualIssue } = req.body;
    if (!technicianId || !rating || repairCost == null) {
      return res.status(400).json({
        message: 'technicianId, rating and repairCost required',
      });
    }

    const review = await Review.create({
      technicianId,
      customerId: req.user._id,
      customerName: req.user.name,
      requestId,
      rating,
      comment: comment || '',
      repairCost: Number(repairCost),
      actualIssue: actualIssue || '',
    });

    const reviews = await Review.find({ technicianId });
    const avg =
      reviews.reduce((s, r) => s + r.rating, 0) / reviews.length;
    await User.findByIdAndUpdate(technicianId, {
      rating: Math.round(avg * 10) / 10,
      reviewCount: reviews.length,
    });

    res.status(201).json({ review: review.toPublicJSON() });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function getReviews(req, res) {
  try {
    const technicianId = req.params.id || req.params.technicianId;
    const reviews = await Review.find({ technicianId }).sort({ createdAt: -1 });
    res.json({ reviews: reviews.map((r) => r.toPublicJSON()) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function getNotifications(req, res) {
  try {
    const notifications = await Notification.find({
      userId: req.user._id,
    }).sort({ createdAt: -1 });
    res.json({ notifications: notifications.map((n) => n.toPublicJSON()) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function markNotificationsRead(req, res) {
  try {
    await Notification.updateMany(
      { userId: req.user._id, read: false },
      { read: true }
    );
    res.json({ message: 'Marked as read' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function getTechnicianPublic(req, res) {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user || user.role !== 'technician') {
      return res.status(404).json({ message: 'Not found' });
    }
    const profile = await TechnicianProfile.findOne({ userId: user._id });
    const reviews = await Review.find({ technicianId: user._id });
    res.json({
      user: user.toPublicJSON(),
      profile: profile?.toPublicJSON(),
      reviews: reviews.map((r) => r.toPublicJSON()),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

module.exports = {
  nearbyTechnicians,
  createRequest,
  myRequests,
  updateRequestStatus,
  setAvailability,
  getMessages,
  sendMessage,
  addReview,
  getReviews,
  getNotifications,
  markNotificationsRead,
  getTechnicianPublic,
};
