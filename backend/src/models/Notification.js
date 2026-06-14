const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    title: { type: String, required: true },
    body: { type: String, required: true },
    read: { type: Boolean, default: false },
    requestId: { type: mongoose.Schema.Types.ObjectId, ref: 'ServiceRequest' },
  },
  { timestamps: true }
);

notificationSchema.methods.toPublicJSON = function () {
  return {
    id: this._id.toString(),
    userId: this.userId.toString(),
    title: this.title,
    body: this.body,
    read: this.read,
    requestId: this.requestId?.toString(),
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model('Notification', notificationSchema);
