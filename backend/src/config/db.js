const mongoose = require('mongoose');

async function connectDB() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/fixxi';

  try {
    await mongoose.connect(uri, { serverSelectionTimeoutMS: 4000 });
    console.log('MongoDB connected:', uri);
    return;
  } catch (err) {
    if (process.env.USE_MEMORY_DB === 'false') {
      throw err;
    }
    console.warn('Local MongoDB unavailable — starting in-memory database (dev only)');
    const { MongoMemoryServer } = require('mongodb-memory-server');
    const mongod = await MongoMemoryServer.create();
    const memUri = mongod.getUri('fixxi');
    await mongoose.connect(memUri);
    global.__mongod = mongod;
    console.log('In-memory MongoDB connected');
  }
}

module.exports = connectDB;
