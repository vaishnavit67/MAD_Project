const admin = require('firebase-admin');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'campus_connect_jwt_secret_token_2026';

// Initialize Firebase Admin if not already initialized
try {
  if (admin.apps.length === 0) {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('[Firebase Admin]: Initialized with service account key.');
    } else {
      // Default initialization
      admin.initializeApp();
      console.log('[Firebase Admin]: Initialized with default application credentials.');
    }
  }
} catch (error) {
  console.warn('[Firebase Admin Warning]: Could not initialize Firebase Admin SDK (' + error.message + '). Token verification will support JWT and mock development tokens as fallback.');
}

/**
 * Middleware to verify Firebase ID token (or JWT token) from Authorization header.
 * Attaches verified user to `req.user` with `uid`, `email`, and `name`.
 */
async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Access denied. No authentication token provided. Expected format: Bearer <token>',
    });
  }

  const token = authHeader.split('Bearer ')[1].trim();

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Access denied. Empty token provided.',
    });
  }

  // 1. Try Firebase Admin ID Token verification
  try {
    if (admin.apps.length > 0) {
      const decodedFirebaseToken = await admin.auth().verifyIdToken(token);
      req.user = {
        uid: decodedFirebaseToken.uid,
        email: decodedFirebaseToken.email || '',
        name: decodedFirebaseToken.name || decodedFirebaseToken.email || 'Campus User',
        role: decodedFirebaseToken.role || 'user',
        isFirebase: true,
      };
      return next();
    }
  } catch (firebaseErr) {
    // If not a valid Firebase Admin token, try JWT / Dev fallback
  }

  // 2. Try Backend JWT Token verification (issued by /api/auth/login)
  try {
    const decodedJwt = jwt.verify(token, JWT_SECRET);
    req.user = {
      uid: decodedJwt.id || decodedJwt.uid,
      email: decodedJwt.email || '',
      name: decodedJwt.name || decodedJwt.email || 'Campus User',
      role: decodedJwt.role || 'user',
      isJwt: true,
    };
    return next();
  } catch (jwtErr) {
    // Check dev/test token fallback
  }

  // 3. Development / Testing Mock / App Token fallback
  if (
    token.startsWith('mock-uid-') ||
    token.startsWith('dev-token-') ||
    token.startsWith('test-user-') ||
    token.startsWith('token_') ||
    token.startsWith('seed-') ||
    token.startsWith('user_')
  ) {
    const extractedUid = token.replace(/^(mock-uid-|dev-token-|test-user-|token_)/, '');
    req.user = {
      uid: extractedUid || token,
      email: `${extractedUid || token}@cb.students.amrita.edu`,
      name: `User ${extractedUid || token}`,
      role: token.includes('admin') ? 'admin' : 'user',
      isDevMock: true,
    };
    return next();
  }

  return res.status(401).json({
    success: false,
    message: 'Invalid or expired authentication token. Please re-authenticate.',
  });
}

/**
 * Optional authentication: Attaches `req.user` if valid token provided, otherwise leaves it null.
 */
async function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    req.user = null;
    return next();
  }

  const token = authHeader.split('Bearer ')[1].trim();
  if (!token) {
    req.user = null;
    return next();
  }

  // Try Firebase
  try {
    if (admin.apps.length > 0) {
      const decodedFirebaseToken = await admin.auth().verifyIdToken(token);
      req.user = {
        uid: decodedFirebaseToken.uid,
        email: decodedFirebaseToken.email || '',
        name: decodedFirebaseToken.name || decodedFirebaseToken.email || 'Campus User',
        role: decodedFirebaseToken.role || 'user',
      };
      return next();
    }
  } catch (_) {}

  // Try JWT
  try {
    const decodedJwt = jwt.verify(token, JWT_SECRET);
    req.user = {
      uid: decodedJwt.id || decodedJwt.uid,
      email: decodedJwt.email || '',
      name: decodedJwt.name || decodedJwt.email || 'Campus User',
      role: decodedJwt.role || 'user',
    };
    return next();
  } catch (_) {}

  // Try Mock / App token
  if (
    token.startsWith('mock-uid-') ||
    token.startsWith('dev-token-') ||
    token.startsWith('test-user-') ||
    token.startsWith('token_') ||
    token.startsWith('seed-') ||
    token.startsWith('user_')
  ) {
    const extractedUid = token.replace(/^(mock-uid-|dev-token-|test-user-|token_)/, '');
    req.user = {
      uid: extractedUid || token,
      email: `${extractedUid || token}@cb.students.amrita.edu`,
      name: `User ${extractedUid || token}`,
      role: token.includes('admin') ? 'admin' : 'user',
    };
    return next();
  }

  req.user = null;
  return next();
}

module.exports = {
  requireAuth,
  optionalAuth,
};
