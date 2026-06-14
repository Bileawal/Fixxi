const jwt = require('jsonwebtoken');
const User = require('../models/User');

function auth(requiredRoles = []) {
  return async (req, res, next) => {
    try {
      const header = req.headers.authorization || '';
      const token = header.startsWith('Bearer ') ? header.slice(7) : null;
      if (!token) {
        return res.status(401).json({ message: 'Unauthorized' });
      }
      const payload = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(payload.userId).select('-password');
      if (!user) {
        return res.status(401).json({ message: 'User not found' });
      }
      if (requiredRoles.length && !requiredRoles.includes(user.role)) {
        return res.status(403).json({ message: 'Forbidden' });
      }
      if (user.role !== 'admin' && user.isCurrentlySuspended?.()) {
        return res.status(403).json({
          message: `Account suspended${user.suspensionReason ? ': ' + user.suspensionReason : ''}`,
        });
      }
      req.user = user;
      next();
    } catch (err) {
      return res.status(401).json({ message: 'Invalid token' });
    }
  };
}

module.exports = { auth };
