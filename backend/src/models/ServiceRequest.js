const mongoose = require('mongoose');

const serviceRequestSchema = new mongoose.Schema(
  {
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    customerName: { type: String, required: true },
    category: { type: String, required: true },
    description: { type: String, required: true },
    type: { type: String, enum: ['urgent', 'scheduled'], required: true },
    technicianId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    technicianName: { type: String },
    scheduledAt: { type: Date },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'rejected', 'inProgress', 'completed', 'cancelled'],
      default: 'pending',
    },
    address: { type: String },
    distanceKm: { type: Number, default: 2.5 },
  },
  { timestamps: true }
);

serviceRequestSchema.methods.toPublicJSON = function () {
  return {
    id: this._id.toString(),
    customerId: this.customerId.toString(),
    customerName: this.customerName,
    category: this.category,
    description: this.description,
    type: this.type,
    technicianId: this.technicianId?.toString(),
    technicianName: this.technicianName,
    scheduledAt: this.scheduledAt,
    status: this.status,
    createdAt: this.createdAt,
    address: this.address,
    distanceKm: this.distanceKm,
  };
};

module.exports = mongoose.model('ServiceRequest', serviceRequestSchema);
