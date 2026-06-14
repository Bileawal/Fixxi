require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
const ensureSeed = require('./utils/ensureSeed');

const authRoutes = require('./routes/auth.routes');
const adminRoutes = require('./routes/admin.routes');
const testRoutes = require('./routes/test.routes');
const apiRoutes = require('./routes/api.routes');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', app: 'Fixxi API' });
});

app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/test', testRoutes);
app.use('/api', apiRoutes);

app.use((err, _req, res, _next) => {
  console.error(err);
  if (err.message === 'Only images allowed') {
    return res.status(400).json({ message: err.message });
  }
  res.status(500).json({ message: err.message || 'Server error' });
});

async function start() {
  await connectDB();
  await ensureSeed();
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Fixxi API running on http://0.0.0.0:${PORT}`);
  });
}

start().catch((e) => {
  console.error('Failed to start:', e);
  process.exit(1);
});
