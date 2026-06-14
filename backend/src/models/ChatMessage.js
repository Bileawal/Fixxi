const mongoose = require('mongoose');

const chatMessageSchema = new mongoose.Schema(
  {
    requestId: { type: mongoose.Schema.Types.ObjectId, ref: 'ServiceRequest', required: true },
    senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    senderName: { type: String, required: true },
    text: { type: String, required: true },
  },
  { timestamps: true }
);

chatMessageSchema.methods.toPublicJSON = function () {
  return {
    id: this._id.toString(),
    requestId: this.requestId.toString(),
    senderId: this.senderId.toString(),
    senderName: this.senderName,
    text: this.text,
    sentAt: this.createdAt,
  };
};

module.exports = mongoose.model('ChatMessage', chatMessageSchema);
