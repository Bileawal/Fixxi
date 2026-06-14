const mongoose = require('mongoose');

const technicianProfileSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    skills: [{ type: String }],
    extraSkills: { type: String, default: '' },
    idCardFrontUrl: { type: String, required: true },
    idCardBackUrl: { type: String, required: true },
    status: {
      type: String,
      enum: [
        'pending_admin',
        'rejected',
        'approved',
        'test_passed',
        'test_failed',
      ],
      default: 'pending_admin',
    },
    rejectionReason: { type: String },
    testScore: { type: Number },
    testPassedAt: { type: Date },
  },
  { timestamps: true }
);

technicianProfileSchema.methods.toPublicJSON = function () {
  return {
    id: this._id.toString(),
    userId: this.userId.toString(),
    skills: this.skills,
    extraSkills: this.extraSkills,
    idCardFrontUrl: this.idCardFrontUrl,
    idCardBackUrl: this.idCardBackUrl,
    status: this.status,
    rejectionReason: this.rejectionReason,
    testScore: this.testScore,
    testPassedAt: this.testPassedAt,
  };
};

module.exports = mongoose.model('TechnicianProfile', technicianProfileSchema);
