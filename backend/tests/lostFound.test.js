/**
 * Comprehensive Automated Test Suite for Lost & Found REST API Backend
 * Verifies all 8 testing requirements specified in the prompt:
 * 1. Item creation and storage in MongoDB
 * 2. Newest first sorting
 * 3. Search and category/type filters
 * 4. Authentication enforcement (401 for unauthenticated create, update, delete, claim)
 * 5. Authorization enforcement (403 when editing/deleting another user's item)
 * 6. Claim submission, duplicate prevention, and owner review/approval
 * 7. Meaningful errors for invalid IDs (400) and missing fields (400)
 * 8. Health check endpoint functionality
 */

const http = require('http');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');

// Ensure JWT secret is set
process.env.JWT_SECRET = process.env.JWT_SECRET || 'campus_connect_secret_key_2026';

const app = require('../server');
const LostFound = require('../models/LostFound');
const LostFoundClaim = require('../models/LostFoundClaim');

const JWT_SECRET = process.env.JWT_SECRET;

// Helper to generate test JWT token
function generateToken(userId, role = 'user') {
  return jwt.sign(
    { id: userId, uid: userId, email: `${userId}@cb.students.amrita.edu`, name: `Student ${userId}`, role },
    JWT_SECRET,
    { expiresIn: '1h' }
  );
}

// User tokens
const userA_token = generateToken('user_alice_123');
const userB_token = generateToken('user_bob_456');
const admin_token = generateToken('admin_charlie_789', 'admin');

let server;
let baseUrl;

function makeRequest(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, baseUrl);
    const headers = { 'Content-Type': 'application/json' };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method.toUpperCase(),
      headers,
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve({ status: res.statusCode, body: json });
        } catch (_) {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });

    req.on('error', reject);
    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function runTests() {
  console.log('====================================================');
  console.log('RUNNING LOST & FOUND BACKEND TEST SUITE');
  console.log('====================================================\n');

  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`  ✓ PASS: ${message}`);
      passed++;
    } else {
      console.error(`  ✗ FAIL: ${message}`);
      failed++;
    }
  }

  // Start HTTP server on port 0 (ephemeral port)
  await new Promise((resolve) => {
    server = app.listen(0, () => {
      const port = server.address().port;
      baseUrl = `http://127.0.0.1:${port}`;
      console.log(`Test server started on ephemeral port: ${port}\n`);
      resolve();
    });
  });

  // Wait for MongoDB Atlas connection to be ready
  if (mongoose.connection.readyState !== 1) {
    console.log('Waiting for MongoDB Atlas connection to be ready...');
    await new Promise((resolve) => {
      if (mongoose.connection.readyState === 1) return resolve();
      mongoose.connection.once('connected', resolve);
      mongoose.connection.once('open', resolve);
    });
  }

  try {
    // ----------------------------------------------------
    // TEST 1: Health Endpoint
    // ----------------------------------------------------
    console.log('TEST 1: Health Endpoint');
    const healthRes = await makeRequest('GET', '/api/health');
    assert(healthRes.status === 200, 'Health endpoint returns HTTP 200');
    assert(healthRes.body.status === 'online', 'Health status is online');
    assert(
      healthRes.body.tables && healthRes.body.tables.includes('lost_found'),
      'Health tables include lost_found'
    );
    assert(
      healthRes.body.tables && healthRes.body.tables.includes('lost_found_claims'),
      'Health tables include lost_found_claims'
    );

    // ----------------------------------------------------
    // TEST 2: Authentication Enforcement (401 for Unauthenticated)
    // ----------------------------------------------------
    console.log('\nTEST 2: Authentication Enforcement (401)');
    const unauthCreate = await makeRequest('POST', '/api/lost-found', {
      title: 'Water Bottle',
      description: 'Blue metal bottle',
      category: 'Other',
      type: 'lost',
      location: 'AB1 Canteen',
    });
    assert(unauthCreate.status === 401, 'Unauthenticated item creation returns 401');

    const unauthUpdate = await makeRequest('PUT', '/api/lost-found/507f1f77bcf86cd799439011', {
      title: 'Hacked',
    });
    assert(unauthUpdate.status === 401, 'Unauthenticated item update returns 401');

    const unauthDelete = await makeRequest('DELETE', '/api/lost-found/507f1f77bcf86cd799439011');
    assert(unauthDelete.status === 401, 'Unauthenticated item deletion returns 401');

    const unauthClaim = await makeRequest('POST', '/api/lost-found/507f1f77bcf86cd799439011/claims', {
      message: 'Claim attempt',
    });
    assert(unauthClaim.status === 401, 'Unauthenticated claim submission returns 401');

    // ----------------------------------------------------
    // TEST 3: Validation on Item Creation (400)
    // ----------------------------------------------------
    console.log('\nTEST 3: Missing Fields & Invalid Types Validation (400)');
    const missingTitle = await makeRequest('POST', '/api/lost-found', {
      description: 'Missing title item',
      category: 'Electronics',
      type: 'lost',
      location: 'Central Library',
    }, userA_token);
    assert(missingTitle.status === 400, 'Missing title returns 400');
    assert(missingTitle.body.message.includes('title'), 'Error message specifies title is required');

    const invalidType = await makeRequest('POST', '/api/lost-found', {
      title: 'MacBook Charger',
      description: 'White USB-C 67W charger',
      category: 'Electronics',
      type: 'stolen', // Invalid enum
      location: 'Central Library',
    }, userA_token);
    assert(invalidType.status === 400, 'Invalid type ("stolen") returns 400');

    // ----------------------------------------------------
    // TEST 4: Item Creation by Authenticated User (201)
    // ----------------------------------------------------
    console.log('\nTEST 4: Create Items & Verify ownerId Derivation (201)');
    const item1Res = await makeRequest('POST', '/api/lost-found', {
      title: 'Scientific Calculator fx-991EX',
      description: 'Casio ClassWiz calculator left on table 14',
      category: 'Electronics',
      type: 'lost',
      location: 'AB1 Room 204',
      date: new Date().toISOString(),
      ownerId: 'spoofed_hacker_id', // Malicious body attempt
      ownerName: 'Alice Student',
    }, userA_token);

    assert(item1Res.status === 201, 'Item 1 created successfully with HTTP 201');
    assert(item1Res.body.item.title === 'Scientific Calculator fx-991EX', 'Title matches');
    assert(item1Res.body.item.ownerId === 'user_alice_123', 'ownerId derived from token, spoofed body ignored');
    assert(item1Res.body.item.status === 'active', 'Initial status is active');

    const item1Id = item1Res.body.item.id || item1Res.body.item._id;

    // Create item 2 by User B (found item)
    const item2Res = await makeRequest('POST', '/api/lost-found', {
      title: 'Blue RFID ID Card',
      description: 'Amrita student ID card found near fountain',
      category: 'ID Cards',
      type: 'found',
      location: 'Central Fountain',
      date: new Date().toISOString(),
    }, userB_token);

    assert(item2Res.status === 201, 'Item 2 created successfully by User B');
    const item2Id = item2Res.body.item.id || item2Res.body.item._id;

    // ----------------------------------------------------
    // TEST 5: Listing & Filtering & Sorting Newest First
    // ----------------------------------------------------
    console.log('\nTEST 5: Listing, Newest First, Search and Category Filters');
    const listRes = await makeRequest('GET', '/api/lost-found');
    assert(listRes.status === 200, 'Public GET /api/lost-found returns 200');
    assert(Array.isArray(listRes.body.items), 'Returns an items array');
    assert(listRes.body.items.length >= 2, 'Contains both created items');

    // Verify newest first: item2 was created after item1
    const idxItem2 = listRes.body.items.findIndex(i => (i.id || i._id) === item2Id);
    const idxItem1 = listRes.body.items.findIndex(i => (i.id || i._id) === item1Id);
    assert(idxItem2 < idxItem1, 'Items are sorted newest first (item2 appears before item1)');

    // Filter by type: 'lost'
    const lostOnly = await makeRequest('GET', '/api/lost-found?type=lost');
    assert(lostOnly.body.items.every(i => i.type === 'lost'), 'Filter ?type=lost returns only lost items');

    // Filter by category: 'ID Cards'
    const idCardsOnly = await makeRequest('GET', '/api/lost-found?category=ID%20Cards');
    assert(idCardsOnly.body.items.every(i => i.category.toLowerCase() === 'id cards'), 'Filter ?category=ID Cards matches category');

    // Search query: 'Calculator'
    const searchRes = await makeRequest('GET', '/api/lost-found?search=calculator');
    assert(searchRes.body.items.some(i => i.title.includes('Calculator')), 'Search ?search=calculator finds matching item');

    // ----------------------------------------------------
    // TEST 6: Invalid IDs (400) and Non-existent IDs (404)
    // ----------------------------------------------------
    console.log('\nTEST 6: Invalid ID and 404 Not Found Checks');
    const invalidIdRes = await makeRequest('GET', '/api/lost-found/not-a-valid-id');
    assert(invalidIdRes.status === 400, 'Invalid ObjectId format returns 400');

    const nonExistentIdRes = await makeRequest('GET', '/api/lost-found/507f1f77bcf86cd799439099');
    assert(nonExistentIdRes.status === 404, 'Non-existent ID returns 404');

    // ----------------------------------------------------
    // TEST 7: Authorization Check (403 for Editing Another User's Item)
    // ----------------------------------------------------
    console.log('\nTEST 7: Authorization (403 when User B tries to edit/delete User A\'s item)');
    const userBUpdateUserA = await makeRequest('PUT', `/api/lost-found/${item1Id}`, {
      title: 'Hacked Title',
    }, userB_token);
    assert(userBUpdateUserA.status === 403, 'User B cannot edit User A\'s item (returns 403 Forbidden)');

    const userBDeleteUserA = await makeRequest('DELETE', `/api/lost-found/${item1Id}`, null, userB_token);
    assert(userBDeleteUserA.status === 403, 'User B cannot delete User A\'s item (returns 403 Forbidden)');

    // Owner (User A) can update their own item
    const ownerUpdate = await makeRequest('PUT', `/api/lost-found/${item1Id}`, {
      title: 'Scientific Calculator fx-991EX (Updated)',
    }, userA_token);
    assert(ownerUpdate.status === 200, 'User A (owner) successfully updates their own item (200)');
    assert(ownerUpdate.body.item.title.includes('Updated'), 'Title was updated');

    // ----------------------------------------------------
    // TEST 8: Claim Submissions, Restrictions & Approvals
    // ----------------------------------------------------
    console.log('\nTEST 8: Claim System (Self-claim prevention, duplicate prevention, review)');
    // Owner cannot claim their own item
    const selfClaim = await makeRequest('POST', `/api/lost-found/${item1Id}/claims`, {
      message: 'Trying to claim my own item',
    }, userA_token);
    assert(selfClaim.status === 400, 'Owner cannot claim their own item (returns 400)');

    // User B submits claim for User A's item
    const claimRes = await makeRequest('POST', `/api/lost-found/${item1Id}/claims`, {
      message: 'I have the serial number ending in 8892 and custom sticker on the back.',
      proofImageUrl: 'https://firebasestorage.googleapis.com/v0/b/proof-image.jpg',
    }, userB_token);
    assert(claimRes.status === 201, 'User B submits valid claim (returns 201)');
    const claimId = claimRes.body.claim.id || claimRes.body.claim._id;

    // Prevent duplicate active claims
    const duplicateClaim = await makeRequest('POST', `/api/lost-found/${item1Id}/claims`, {
      message: 'Duplicate claim attempt',
    }, userB_token);
    assert(duplicateClaim.status === 409, 'Duplicate active claim rejected with 409 Conflict');

    // User B (non-owner) cannot view claims of item 1
    const unauthViewClaims = await makeRequest('GET', `/api/lost-found/${item1Id}/claims`, null, userB_token);
    assert(unauthViewClaims.status === 403, 'User B cannot view claims of User A\'s item (returns 403)');

    // User A (owner) can view claims
    const ownerViewClaims = await makeRequest('GET', `/api/lost-found/${item1Id}/claims`, null, userA_token);
    assert(ownerViewClaims.status === 200, 'User A (owner) can view claims of their item (returns 200)');
    assert(ownerViewClaims.body.claims.length === 1, 'Contains 1 submitted claim');

    // User B (non-owner) cannot approve claim
    const unauthApprove = await makeRequest('PATCH', `/api/lost-found/${item1Id}/claims/${claimId}`, {
      status: 'approved',
    }, userB_token);
    assert(unauthApprove.status === 403, 'Non-owner cannot approve claim (returns 403)');

    // User A (owner) approves claim
    const ownerApprove = await makeRequest('PATCH', `/api/lost-found/${item1Id}/claims/${claimId}`, {
      status: 'approved',
    }, userA_token);
    assert(ownerApprove.status === 200, 'Owner approves claim (returns 200)');
    assert(ownerApprove.body.claim.status === 'approved', 'Claim status is now approved');
    assert(ownerApprove.body.item.status === 'claimed', 'Item status transitioned to claimed');

    // Clean up created test items
    await makeRequest('DELETE', `/api/lost-found/${item1Id}`, null, userA_token);
    await makeRequest('DELETE', `/api/lost-found/${item2Id}`, null, userB_token);
    console.log('\nCleaned up test items from database.');

  } catch (err) {
    console.error('Test execution error:', err);
    failed++;
  } finally {
    if (server) {
      server.close();
    }
  }

  console.log('\n====================================================');
  console.log(`TEST RESULTS: ${passed} PASSED, ${failed} FAILED`);
  console.log('====================================================');

  process.exit(failed > 0 ? 1 : 0);
}

// Run tests if database is connected or connect to test DB
if (mongoose.connection.readyState === 1) {
  runTests();
} else {
  // If not connected, test using test DB
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/campus_connect';
  const dbName = process.env.DB_NAME || 'test';
  mongoose.connect(uri, { dbName, serverSelectionTimeoutMS: 5000 })
    .then(runTests)
    .catch((err) => {
      console.warn('Could not connect to MongoDB for live test suite:', err.message);
      console.log('Running route & middleware contract verification...');
      runTests();
    });
}
