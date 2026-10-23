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
const uploadRoutes = require('./routes/uploadRoutes');
const clubRoutes = require('./routes/clubRoutes');
const eventRoutes = require('./routes/eventRoutes');
const facultyRoutes = require('./routes/facultyRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const calendarRoutes = require('./routes/calendarRoutes');
const Faculty = require('./models/Faculty');
const Student = require('./models/Student');
const Visitor = require('./models/Visitor');
const CampusLocation = require('./models/CampusLocation');
const Club = require('./models/Club');
const Event = require('./models/Event');
const defaultLocations = require('./data/campusLocations.json');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/campus_connect';

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('dev'));

// Static uploads serving
app.use('/uploads', express.static(path.resolve(__dirname, 'uploads')));

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
    tables: ['faculty', 'students', 'visitors', 'locations', 'lost_found', 'lost_found_claims', 'clubs', 'events', 'notifications', 'calendar_items'],
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

// Image Upload routes
app.use('/api/upload', uploadRoutes);

// Club routes
app.use('/api/clubs', clubRoutes);

// Event routes
app.use('/api/events', eventRoutes);

// Faculty routes
app.use('/api/faculty', facultyRoutes);

// Notification routes (role-tailored and user-specific)
app.use('/api/notifications', notificationRoutes);

// Calendar routes (classes, tasks, schedule per user & role)
app.use('/api/calendar', calendarRoutes);

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

// Seed default campus clubs if collection is empty
async function seedDefaultClubs() {
  try {
    const count = await Club.countDocuments();
    if (count === 0) {
      const defaultClubs = [
        {
          name: 'DevTech Coding Club',
          category: 'Technical',
          description: 'Building real-world web, mobile apps & AI solutions. Join hackathons and tech talks!',
          membersCount: 142,
          members: ['Faculty Member'],
          createdBy: 'system-seed',
          createdByName: 'Faculty Coordinator',
        },
        {
          name: 'Creative UI/UX Design',
          category: 'Creative',
          description: 'Master Figma, graphic design, animation, and digital brand storytelling.',
          membersCount: 98,
          members: ['Faculty Member'],
          createdBy: 'system-seed',
          createdByName: 'Faculty Coordinator',
        },
        {
          name: 'Acoustics Music Society',
          category: 'Cultural',
          description: 'Jamming sessions, vocal coaching, band performances & annual music fests.',
          membersCount: 115,
          members: ['Faculty Member'],
          createdBy: 'system-seed',
          createdByName: 'Faculty Coordinator',
        },
        {
          name: 'Campus Varsity Sports',
          category: 'Sports',
          description: 'Cricket, Football, Basketball and Badminton tournaments and regular practice sessions.',
          membersCount: 180,
          members: ['Faculty Member'],
          createdBy: 'system-seed',
          createdByName: 'Faculty Coordinator',
        },
      ];
      await Club.insertMany(defaultClubs);
      console.log(`[Seed Clubs]: Successfully seeded ${defaultClubs.length} default clubs in MongoDB.`);
    }
  } catch (err) {
    console.error('[Seed Clubs Error]:', err.message);
  }
}

// Seed default campus events if collection is empty
async function seedDefaultEvents() {
  try {
    const count = await Event.countDocuments();
    if (count === 0) {
      const now = new Date();
      const defaultEvents = [
        {
          title: 'Tech Talk 2026',
          date: new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000),
          timeString: '10:00 AM',
          endTimeString: '12:00 PM',
          location: 'AB2 Seminar Hall',
          description: 'Insightful tech talk on AI and the future of software development. Industry leaders share experiences on cutting-edge technologies.',
          organizer: 'Coding Club',
          availableSeats: 50,
          capacity: 150,
          participantCount: 78,
          category: 'Technology',
          featured: false,
          createdBy: 'system-seed',
          createdByName: 'Faculty Coordinator',
        },
        {
          title: 'Hackathon 3.0',
          date: new Date(now.getTime() + 6 * 24 * 60 * 60 * 1000),
          timeString: '09:00 AM',
          endTimeString: '09:00 AM',
          location: 'Innovation Lab, Main Block',
          description: '24-hour hackathon to build innovative solutions for real-world campus problems. Teams of 2-4. Prizes worth 1,00,000+.',
          organizer: 'Tech Society',
          availableSeats: 20,
          capacity: 200,
          participantCount: 124,
          category: 'Hackathon',
          featured: true,
          createdBy: 'system-seed',
          createdByName: 'Faculty Coordinator',
        },
        {
          title: 'Cultural Fest - Utsav 2026',
          date: new Date(now.getTime() + 10 * 24 * 60 * 60 * 1000),
          timeString: '09:00 AM',
          endTimeString: '09:00 PM',
          location: 'Main Auditorium',
          description: 'Annual cultural festival featuring music, dance, art exhibitions, and dramatic performances. A celebration of campus talent.',
          organizer: 'Cultural Committee',
          availableSeats: 500,
          capacity: 1000,
          participantCount: 342,
          category: 'Cultural',
          featured: false,
          createdBy: 'system-seed',
          createdByName: 'Faculty Coordinator',
        },
        {
          title: 'AI and ML Workshop',
          date: new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000),
          timeString: '02:00 PM',
          endTimeString: '05:00 PM',
          location: 'Computer Lab 3, AB2',
          description: 'Hands-on workshop on practical machine learning using Python and TensorFlow. Train your own model. Bring your laptop.',
          organizer: 'AI Research Club',
          availableSeats: 15,
          capacity: 60,
          participantCount: 45,
          category: 'Workshop',
          featured: false,
          createdBy: 'system-seed',
          createdByName: 'Faculty Coordinator',
        },
      ];
      await Event.insertMany(defaultEvents);
      console.log(`[Seed Events]: Successfully seeded ${defaultEvents.length} default events in MongoDB.`);
    }
  } catch (err) {
    console.error('[Seed Events Error]:', err.message);
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

    // Seed initial demo users, campus locations, clubs & events
    await seedDefaultDemoAccounts();
    await seedDefaultCampusLocations();
    await seedDefaultClubs();
    await seedDefaultEvents();
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
    console.log(`Upload Endpoint: http://localhost:${PORT}/api/upload`);
    console.log(`Club Endpoints: http://localhost:${PORT}/api/clubs`);
    console.log(`Event Endpoints: http://localhost:${PORT}/api/events`);
    console.log(`Faculty Endpoints: http://localhost:${PORT}/api/faculty`);
    console.log(`Collections (Tables): faculty, students, visitors, locations, lost_found, lost_found_claims, clubs, events`);
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
