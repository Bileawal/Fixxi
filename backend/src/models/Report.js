const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema(
  {
    reporterId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    reporterName: { type: String, required: true },
    reportedUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    reportedUserName: { type: String, required: true },
    reason: { type: String, required: true },
    reviewId: { type: mongoose.Schema.Types.ObjectId, ref: 'Review' },
    status: { type: String, enum: ['open', 'resolved'], default: 'open' },
    adminNote: { type: String, default: '' },
  },
  { timestamps: true }
);

reportSchema.methods.toPublicJSON = function () {
  return {
    id: this._id.toString(),
    reporterId: this.reporterId.toString(),
    reporterName: this.reporterName,
    reportedUserId: this.reportedUserId.toString(),
    reportedUserName: this.reportedUserName,
    reason: this.reason,
    reviewId: this.reviewId?.toString(),
    status: this.status,
    adminNote: this.adminNote,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model('Report', reportSchema);
