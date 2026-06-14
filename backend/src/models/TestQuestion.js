const mongoose = require('mongoose');

const testQuestionSchema = new mongoose.Schema({
  question: { type: String, required: true },
  options: [{ type: String, required: true }],
  correctIndex: { type: Number, required: true },
  category: { type: String, default: 'General' },
});

module.exports = mongoose.model('TestQuestion', testQuestionSchema);
