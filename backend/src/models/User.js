const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    phone: { type: String, required: true },
    password: { type: String, required: true },
    role: {
      type: String,
      enum: ['customer', 'technician', 'admin'],
      required: true,
    },
    address: { type: String },
    fatherName: { type: String },
    isAvailable: { type: Boolean, default: true },
    rating: { type: Number, default: 4.5 },
    reviewCount: { type: Number, default: 0 },
    latitude: { type: Number, default: 31.5204 },
    longitude: { type: Number, default: 74.3587 },
    emailVerified: { type: Boolean, default: false },
    isSuspended: { type: Boolean, default: false },
    suspendedUntil: { type: Date, default: null },
    suspensionType: {
      type: String,
      enum: ['week', 'month', 'permanent'],
    },
    suspensionReason: { type: String, default: '' },
    fcmToken: { type: String, default: null },
  },
  { timestamps: true }
);

userSchema.methods.isCurrentlySuspended = function () {
  if (!this.isSuspended) return false;
  if (this.suspensionType === 'permanent') return true;
  if (this.suspendedUntil && this.suspendedUntil > new Date()) return true;
  return false;
};

userSchema.methods.toPublicJSON = function () {
  return {
    id: this._id.toString(),
    name: this.name,
    email: this.email,
    phone: this.phone,
    role: this.role,
    address: this.address,
    fatherName: this.fatherName,
    isAvailable: this.isAvailable,
    rating: this.rating,
    reviewCount: this.reviewCount,
    latitude: this.latitude,
    longitude: this.longitude,
    emailVerified: this.emailVerified,
    isSuspended: this.isCurrentlySuspended(),
  };
};

userSchema.methods.toAdminJSON = function () {
  return {
    ...this.toPublicJSON(),
    isSuspendedFlag: this.isSuspended,
    suspendedUntil: this.suspendedUntil,
    suspensionType: this.suspensionType,
    suspensionReason: this.suspensionReason,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model('User', userSchema);
