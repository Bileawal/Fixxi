const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema(
  {
    technicianId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    customerName: { type: String, required: true },
    requestId: { type: mongoose.Schema.Types.ObjectId, ref: 'ServiceRequest' },
    rating: { type: Number, required: true, min: 1, max: 5 },
    comment: { type: String, default: '' },
    repairCost: { type: Number, default: 0, min: 0 },
    actualIssue: { type: String, default: '' },
  },
  { timestamps: true }
);

reviewSchema.methods.toPublicJSON = function () {
  return {
    id: this._id.toString(),
    technicianId: this.technicianId.toString(),
    customerId: this.customerId.toString(),
    customerName: this.customerName,
    rating: this.rating,
    comment: this.comment,
    repairCost: this.repairCost,
    actualIssue: this.actualIssue || '',
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model('Review', reviewSchema);
