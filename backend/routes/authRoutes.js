const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const Faculty = require('../models/Faculty');
const Student = require('../models/Student');
const Visitor = require('../models/Visitor');
const { signupValidator, loginValidator } = require('../middleware/validator');

const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'campus_connect_secret_key_2026';

// Helper to get corresponding Mongoose model for a given role
function getModelForRole(role) {
  switch (role) {
    case 'Faculty':
      return Faculty;
    case 'Visitor':
      return Visitor;
    case 'Student':
    default:
      return Student;
  }
}

// All role models list
const allModels = [
  { role: 'Student', model: Student, collection: 'students' },
  { role: 'Faculty', model: Faculty, collection: 'faculty' },
  { role: 'Visitor', model: Visitor, collection: 'visitors' },
];

/**
 * @route   POST /api/auth/signup
 * @desc    Register a new user into role table ('faculty', 'students', 'visitors')
 * @access  Public
 */
router.post('/signup', signupValidator, async (req, res) => {
  try {
    const { name, email, phone, rollNumber, password, role } = req.body;
    const cleanEmail = email.trim().toLowerCase();
    const rawDigits = phone.replace(/\D/g, '');
    const cleanPhone = rawDigits.length >= 10 ? rawDigits.slice(-10) : rawDigits;
    const cleanRole = role.trim();

    // 1. Check if email already exists in any of the 3 role collections
    const escapedEmail = cleanEmail.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    for (const item of allModels) {
      const existingUser = await item.model.findOne({ email: new RegExp(`^${escapedEmail}$`, 'i') });
      if (existingUser) {
        return res.status(409).json({
          success: false,
          message: 'An account with this email address already exists. Please Log In.',
        });
      }
    }

    // 2. Check if phone already exists in any of the 3 role collections
    for (const item of allModels) {
      const existingUser = await item.model.findOne({
        $or: [
          { phone: cleanPhone },
          { phone: `91${cleanPhone}` },
          { phone: `+91${cleanPhone}` },
          { phone: new RegExp(`${cleanPhone}$`) },
        ],
      });
      if (existingUser) {
        return res.status(409).json({
          success: false,
          message: 'An account with this phone number already exists. Please Log In.',
        });
      }
    }

    // 3. Hash the password with bcrypt
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 4. Insert into the target role collection (table)
    const TargetModel = getModelForRole(cleanRole);
    const targetCollection = cleanRole === 'Faculty' ? 'faculty' : (cleanRole === 'Visitor' ? 'visitors' : 'students');

    const newUser = await TargetModel.create({
      name: name.trim(),
      email: cleanEmail,
      phone: cleanPhone,
      rollNumber: rollNumber.trim(),
      password: hashedPassword,
      role: cleanRole,
      category: targetCollection,
    });

    const userObj = newUser.toJSON();

    return res.status(201).json({
      success: true,
      message: `Account created successfully in ${targetCollection} table! Please log in to continue.`,
      user: userObj,
    });
  } catch (error) {
    console.error('[Signup Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Server error during registration.',
    });
  }
});

/**
 * @route   POST /api/auth/login
 * @desc    Authenticate user against the role-specific MongoDB table
 * @access  Public
 */
router.post('/login', loginValidator, async (req, res) => {
  try {
    const { identity, password, role } = req.body;
    const cleanIdentity = identity.trim().toLowerCase();
    const rawIdentity = identity.trim();
    const digitsOnly = identity.replace(/\D/g, '');
    const tenDigitPhone = digitsOnly.length >= 10 ? digitsOnly.slice(-10) : digitsOnly;
    const cleanRole = role.trim();

    const TargetModel = getModelForRole(cleanRole);

    // Build comprehensive search query for email, 10-digit phone, or rollNumber / Campus ID
    let searchFilter;
    if (cleanIdentity.includes('@')) {
      const escapedEmail = cleanIdentity.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      searchFilter = { email: new RegExp(`^${escapedEmail}$`, 'i') };
    } else if (digitsOnly.length >= 10) {
      searchFilter = {
        $or: [
          { phone: tenDigitPhone },
          { phone: `91${tenDigitPhone}` },
          { phone: `+91${tenDigitPhone}` },
          { phone: new RegExp(`${tenDigitPhone}$`) },
        ],
      };
    } else {
      const escapedRaw = rawIdentity.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      searchFilter = {
        $or: [
          { rollNumber: new RegExp(`^${escapedRaw}$`, 'i') },
          { email: new RegExp(`^${cleanIdentity.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') },
          { phone: tenDigitPhone || digitsOnly },
        ],
      };
    }

    // 1. Search in target role table first
    let user = await TargetModel.findOne(searchFilter);

    // 2. If not found in target table, check if user exists under a different role
    if (!user) {
      for (const item of allModels) {
        if (item.role === cleanRole) continue;
        const otherUser = await item.model.findOne(searchFilter);
        if (otherUser) {
          return res.status(403).json({
            success: false,
            message: `This account is registered as ${otherUser.role}. Please select the ${otherUser.role} tab to log in.`,
            registeredRole: otherUser.role,
          });
        }
      }

      return res.status(404).json({
        success: false,
        message: `No registered account found for "${identity.trim()}" under ${cleanRole}. Please check your details or Sign Up.`,
      });
    }

    // 3. Verify password (supports bcrypt, SHA-256, and plaintext)
    const storedPassword = user.password || user.passwordHash || '';
    let isMatch = false;
    if (storedPassword) {
      if (storedPassword.startsWith('$2a$') || storedPassword.startsWith('$2b$')) {
        isMatch = await bcrypt.compare(password, storedPassword);
      } else {
        const crypto = require('crypto');
        const shaHash = crypto.createHash('sha256').update(`CampusConnect_Salt_2026:${password}`).digest('hex');
        isMatch = storedPassword === password || storedPassword === shaHash;
      }
    }

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Incorrect password. Please verify and try again.',
      });
    }

    // 4. Generate JWT Token
    const token = jwt.sign(
      {
        id: user._id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    const userObj = user.toJSON();

    return res.status(200).json({
      success: true,
      message: `Logged in successfully as ${cleanRole}!`,
      token,
      user: userObj,
    });
  } catch (error) {
    console.error('[Login Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Server error during login.',
    });
  }
});

/**
 * @route   GET /api/auth/users/:role
 * @desc    Get all users from a specific role collection
 * @access  Public / Admin
 */
router.get('/users/:role', async (req, res) => {
  try {
    const rawRole = req.params.role;
    let formattedRole = 'Student';
    if (rawRole.toLowerCase().includes('fac')) formattedRole = 'Faculty';
    else if (rawRole.toLowerCase().includes('vis')) formattedRole = 'Visitor';

    const Model = getModelForRole(formattedRole);
    const users = await Model.find().sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      role: formattedRole,
      count: users.length,
      users,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

/**
 * @route   GET /api/auth/stats
 * @desc    Get user counts across all three tables (faculty, students, visitors)
 * @access  Public
 */
router.get('/stats', async (req, res) => {
  try {
    const facultyCount = await Faculty.countDocuments();
    const studentsCount = await Student.countDocuments();
    const visitorsCount = await Visitor.countDocuments();

    return res.status(200).json({
      success: true,
      stats: {
        faculty: facultyCount,
        students: studentsCount,
        visitors: visitorsCount,
        total: facultyCount + studentsCount + visitorsCount,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
