const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') });
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const morgan = require('morgan');
const bcrypt = require('bcryptjs');

const authRoutes = require('./routes/authRoutes');
const locationRoutes = require('./routes/locationRoutes');
const lostFoundRoutes = require('./routes/lostFoundRoutes');
const Faculty = require('./models/Faculty');
const Student = require('./models/Student');
const Visitor = require('./models/Visitor');
const CampusLocation = require('./models/CampusLocation');
const defaultLocations = require('./data/campusLocations.json');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/campus_connect';

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('dev'));

// Health check endpoint
app.get('/api/health', async (req, res) => {
  const dbState = mongoose.connection.readyState;
  const stateLabels = ['disconnected', 'connected', 'connecting', 'disconnecting'];

  let locationCount = 0;
  if (dbState === 1) {
    try {
      locationCount = await CampusLocation.countDocuments();
    } catch (_) {}
  }

  res.status(200).json({
    status: 'online',
    app: 'Campus Connect MAD Backend',
    database: stateLabels[dbState] || 'unknown',
    tables: ['faculty', 'students', 'visitors', 'locations', 'lost_found', 'lost_found_claims'],
    campusLocationsCount: locationCount,
    timestamp: new Date().toISOString(),
  });
});

// Authentication routes
app.use('/api/auth', authRoutes);

// Campus Locations routes
app.use('/api/locations', locationRoutes);

// Lost & Found routes
app.use('/api/lost-found', lostFoundRoutes);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Endpoint ${req.method} ${req.originalUrl} not found`,
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[Unhandled Server Error]:', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error',
  });
});

const DB_NAME = process.env.DB_NAME || 'test';

// Seed default demo accounts into their respective collections if empty
async function seedDefaultDemoAccounts() {
  try {
    const studentCount = await Student.countDocuments();
    if (studentCount === 0) {
      const hashedPass = await bcrypt.hash('password123', 10);
      await Student.create({
        name: 'Amrita Student',
        email: 'student@cb.students.amrita.edu',
        phone: '9876543210',
        rollNumber: 'CB.EN.U4CSE21001',
        password: hashedPass,
        role: 'Student',
        category: 'students',
      });
      console.log('[Seed]: Created demo student in "students" table');
    }

    const facultyCount = await Faculty.countDocuments();
    if (facultyCount === 0) {
      const hashedPass = await bcrypt.hash('password123', 10);
      await Faculty.create({
        name: 'Amrita Faculty',
        email: 'faculty@cb.amrita.edu',
        phone: '9876543211',
        rollNumber: 'EMP1001',
        password: hashedPass,
        role: 'Faculty',
        category: 'faculty',
      });
      console.log('[Seed]: Created demo faculty in "faculty" table');
    }

    const visitorCount = await Visitor.countDocuments();
    if (visitorCount === 0) {
      const hashedPass = await bcrypt.hash('password123', 10);
      await Visitor.create({
        name: 'Campus Visitor',
        email: 'user@gmail.com',
        phone: '9876543212',
        rollNumber: 'VIS001',
        password: hashedPass,
        role: 'Visitor',
        category: 'visitors',
      });
      console.log('[Seed]: Created demo visitor in "visitors" table');
    }
  } catch (err) {
    console.error('[Seed Demo Accounts Error]:', err.message);
  }
}

// Seed default 53 campus locations into MongoDB if collection is empty
async function seedDefaultCampusLocations() {
  try {
    const count = await CampusLocation.countDocuments();
    if (count === 0) {
      console.log(`[Seed Locations]: Seeding ${defaultLocations.length} campus locations into MongoDB (${DB_NAME}.locations)...`);
      const payload = defaultLocations.map((loc) => ({
        name: loc.name,
        category: loc.category,
        description: loc.description || '',
        distance: loc.distance || '850 m',
        walkingTime: loc.walkingTime || '~10 min',
        buildingCode: loc.buildingCode || '',
        floorCount: loc.floorCount || 1,
        isFavorite: loc.isFavorite || false,
        keywords: loc.keywords || [],
        checkpoints: loc.checkpoints || [],
        latitude: loc.latitude,
        longitude: loc.longitude,
      }));

      await CampusLocation.insertMany(payload);
      console.log(`[Seed Locations]: Successfully seeded ${payload.length} campus locations in "${DB_NAME}.locations"!`);
    } else {
      console.log(`[Locations]: Found ${count} existing campus locations in "${DB_NAME}.locations".`);
    }
  } catch (err) {
    console.error('[Seed Campus Locations Error]:', err.message);
  }
}

// Connect to MongoDB & Start Server
async function startServer() {
  try {
    console.log(`Connecting to MongoDB at: ${MONGODB_URI.replace(/\/\/.*@/, '//<credentials>@')} (dbName: ${DB_NAME})...`);
    await mongoose.connect(MONGODB_URI, {
      dbName: DB_NAME,
      serverSelectionTimeoutMS: 5000,
    });
    console.log(`MongoDB connected successfully to database: "${DB_NAME}"!`);

    // Seed initial demo users & campus locations
    await seedDefaultDemoAccounts();
    await seedDefaultCampusLocations();
  } catch (error) {
    console.warn(`[MongoDB Warning]: Could not connect to MongoDB server: ${error.message}`);
    console.warn('Backend server will start, but database operations will fail until MongoDB is available.');
  }

  const server = app.listen(PORT, '0.0.0.0', () => {
    console.log('====================================================');
    console.log(`Campus Connect Backend running on http://localhost:${PORT}`);
    console.log(`Connected Database: "${DB_NAME}"`);
    console.log(`Health Check: http://localhost:${PORT}/api/health`);
    console.log(`Auth Endpoints: http://localhost:${PORT}/api/auth/signup & /login`);
    console.log(`Location Endpoints: http://localhost:${PORT}/api/locations`);
    console.log(`Lost & Found Endpoints: http://localhost:${PORT}/api/lost-found`);
    console.log(`Collections (Tables): faculty, students, visitors, locations, lost_found, lost_found_claims`);
    console.log('====================================================');
  });

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.warn(`[Port Notice]: Port ${PORT} is already in use by another running terminal.`);
      console.warn(`Your backend is already running and serving requests on port ${PORT}!`);
    } else {
      console.error('[Server Error]:', err);
    }
  });
}

startServer();

module.exports = app;
