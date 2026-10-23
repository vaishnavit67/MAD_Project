const request = require('supertest');
const path = require('path');
const fs = require('fs');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const app = require('../server');
const Club = require('../models/Club');
const Event = require('../models/Event');
const LostFound = require('../models/LostFound');
const LostFoundClaim = require('../models/LostFoundClaim');

const JWT_SECRET = process.env.JWT_SECRET || 'campus_connect_jwt_secret_token_2026';

function generateToken(user) {
  return jwt.sign(
    {
      id: user.id || 'test-user-id-123',
      email: user.email,
      name: user.name,
      role: user.role,
    },
    JWT_SECRET,
    { expiresIn: '1h' }
  );
}

const facultyToken = generateToken({
  id: 'fac-001',
  email: 'prof.smith@cb.amrita.edu',
  name: 'Prof. Smith',
  role: 'Faculty',
});

const studentToken = generateToken({
  id: 'stu-001',
  email: 'student@cb.students.amrita.edu',
  name: 'Student User',
  role: 'Student',
});

const visitorToken = generateToken({
  id: 'vis-001',
  email: 'visitor@gmail.com',
  name: 'Visitor User',
  role: 'Visitor',
});

beforeAll(async () => {
  let attempts = 0;
  while (mongoose.connection.readyState !== 1 && attempts < 30) {
    await new Promise((res) => setTimeout(res, 200));
    attempts++;
  }
});

describe('Additional Integration Requirements Tests', () => {
  let createdClubId;
  let createdEventId;
  let createdClaimId;

  // 1. Direct Image Upload Tests
  describe('Image Upload API (/api/upload)', () => {
    test('POST /api/upload should upload an image and return static URL', async () => {
      // Create a dummy small jpeg file
      const testFilePath = path.join(__dirname, 'test-image.jpg');
      fs.writeFileSync(testFilePath, Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46]));

      const res = await request(app)
        .post('/api/upload')
        .attach('image', testFilePath);

      fs.unlinkSync(testFilePath);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.url).toBeDefined();
      expect(res.body.url).toContain('/uploads/');
      expect(res.body.relativeUrl).toBeDefined();
    });

    test('POST /api/upload should reject non-image files', async () => {
      const testTxtPath = path.join(__dirname, 'test.txt');
      fs.writeFileSync(testTxtPath, 'Hello text file');

      const res = await request(app)
        .post('/api/upload')
        .attach('image', testTxtPath);

      fs.unlinkSync(testTxtPath);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });

  // 2. Faculty Dashboard — Create and Manage Clubs Tests
  describe('Clubs API (/api/clubs)', () => {
    test('GET /api/clubs should return list of clubs', async () => {
      const res = await request(app).get('/api/clubs');
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.clubs)).toBe(true);
    });

    test('POST /api/clubs should reject student with 403 Forbidden', async () => {
      const res = await request(app)
        .post('/api/clubs')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          name: 'Unauthorized Student Club',
          category: 'Technical',
          description: 'This should fail authorization.',
        });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Faculty privileges required');
    });

    test('POST /api/clubs should reject visitor with 403 Forbidden', async () => {
      const res = await request(app)
        .post('/api/clubs')
        .set('Authorization', `Bearer ${visitorToken}`)
        .send({
          name: 'Unauthorized Visitor Club',
          category: 'Technical',
          description: 'This should fail authorization.',
        });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    test('POST /api/clubs should allow faculty to create a club and persist in MongoDB', async () => {
      const res = await request(app)
        .post('/api/clubs')
        .set('Authorization', `Bearer ${facultyToken}`)
        .send({
          name: 'Robotics & Automation Society',
          category: 'Technical',
          description: 'Design autonomous robots, drones, and embedded systems.',
          imageUrl: 'http://localhost:5000/uploads/robotics.jpg',
          initialMembersCount: 25,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.club).toBeDefined();
      expect(res.body.club.name).toBe('Robotics & Automation Society');
      expect(res.body.club.createdBy).toBe('fac-001');

      createdClubId = res.body.club._id || res.body.club.id;
    });

    test('POST /api/clubs/:id/join should prevent visitors from joining clubs', async () => {
      const res = await request(app)
        .post(`/api/clubs/${createdClubId}/join`)
        .set('Authorization', `Bearer ${visitorToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Visitors cannot join campus clubs');
    });

    test('POST /api/clubs/:id/join should allow students to join clubs', async () => {
      const res = await request(app)
        .post(`/api/clubs/${createdClubId}/join`)
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.isPending || res.body.isJoined).toBeTruthy();
    });
  });

  // 3. Faculty Dashboard — Create and Manage Events Tests
  describe('Events API (/api/events)', () => {
    test('GET /api/events should return list of events', async () => {
      const res = await request(app).get('/api/events');
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.events)).toBe(true);
    });

    test('POST /api/events should reject student with 403 Forbidden', async () => {
      const res = await request(app)
        .post('/api/events')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          title: 'Unauthorized Event',
          date: new Date(),
          timeString: '10:00 AM',
          location: 'Hall A',
          description: 'Should fail',
        });

      expect(res.status).toBe(403);
    });

    test('POST /api/events should allow faculty to create event with image URL', async () => {
      const res = await request(app)
        .post('/api/events')
        .set('Authorization', `Bearer ${facultyToken}`)
        .send({
          title: 'National AI & Robotics Symposium 2026',
          description: 'Keynote speakers from leading research labs on robotics and computer vision.',
          date: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
          timeString: '10:30 AM',
          endTimeString: '04:00 PM',
          location: 'Main Auditorium, South Campus',
          organizer: 'Department of AI',
          category: 'Technology',
          capacity: 250,
          imageUrl: 'http://localhost:5000/uploads/symposium.jpg',
          featured: true,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.event.title).toBe('National AI & Robotics Symposium 2026');
      expect(res.body.event.imageUrl).toBe('http://localhost:5000/uploads/symposium.jpg');

      createdEventId = res.body.event._id || res.body.event.id;
    });

    test('POST /api/events/:id/register should allow users to register', async () => {
      const res = await request(app)
        .post(`/api/events/${createdEventId}/register`)
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.event.participantCount).toBeGreaterThanOrEqual(1);
    });
  });

  // 4. Faculty Dashboard — Pending Requests & Moderation Tests
  describe('Faculty Moderation API (/api/faculty)', () => {
    beforeAll(async () => {
      // Create a test item & claim
      const item = await LostFound.create({
        name: 'Faculty Test Watch',
        title: 'Faculty Test Watch',
        description: 'A silver wrist watch found near the library tables',
        category: 'Electronics',
        type: 'found',
        location: 'Library',
        date: new Date(),
        ownerId: 'finder-123',
        ownerName: 'Finder Person',
      });

      const claim = await LostFoundClaim.create({
        itemId: item._id,
        claimantId: 'claimant-456',
        claimantName: 'John Claimant',
        message: 'It has an engraved serial number CC-9981 on the back buckle.',
        status: 'pending',
      });

      createdClaimId = claim._id.toString();
    });

    test('GET /api/faculty/dashboard-stats should reject students with 403', async () => {
      const res = await request(app)
        .get('/api/faculty/dashboard-stats')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(403);
    });

    test('GET /api/faculty/dashboard-stats should return counts for faculty', async () => {
      const res = await request(app)
        .get('/api/faculty/dashboard-stats')
        .set('Authorization', `Bearer ${facultyToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.stats.pendingClaimsCount).toBeGreaterThanOrEqual(1);
      expect(res.body.stats.activeClubsCount).toBeGreaterThanOrEqual(1);
      expect(res.body.stats.upcomingEventsCount).toBeGreaterThanOrEqual(1);
    });

    test('GET /api/faculty/pending-requests should return pending verification claims', async () => {
      const res = await request(app)
        .get('/api/faculty/pending-requests')
        .set('Authorization', `Bearer ${facultyToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.requests)).toBe(true);
      const found = res.body.requests.find((r) => r.id === createdClaimId);
      expect(found).toBeDefined();
      expect(found.itemTitle).toBe('Faculty Test Watch');
    });

    test('PATCH /api/faculty/claims/:id should allow faculty to approve a claim', async () => {
      const res = await request(app)
        .patch(`/api/faculty/claims/${createdClaimId}`)
        .set('Authorization', `Bearer ${facultyToken}`)
        .send({ status: 'approved' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.claim.status).toBe('approved');
    });
  });

  afterAll(async () => {
    // Cleanup created test records
    if (createdClubId) await Club.findByIdAndDelete(createdClubId);
    if (createdEventId) await Event.findByIdAndDelete(createdEventId);
    if (createdClaimId) await LostFoundClaim.findByIdAndDelete(createdClaimId);
  });
});
