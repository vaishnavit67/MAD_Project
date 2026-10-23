/**
 * Role-based validation middleware mirroring the Campus Connect Flutter FormValidators.
 */

function validateEmailForRole(email, role) {
  if (!email || !email.trim()) {
    return 'Please enter your email address';
  }

  const cleanEmail = email.trim().toLowerCase();
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  if (!emailRegex.hasMatch ? !emailRegex.test(cleanEmail) : false) {
    return 'Please enter a valid email format';
  }

  const parts = cleanEmail.split('@');
  if (parts.length !== 2) return 'Invalid email address format';
  const domain = parts[1];

  if (role === 'Visitor') {
    if (domain !== 'gmail.com') {
      return 'Visitors must use a Gmail address (@gmail.com)';
    }
  } else if (role === 'Student') {
    const isStudentDomain =
      domain === 'cb.students.amrita.edu' ||
      domain === 'students.amrita.edu' ||
      domain.endsWith('.students.amrita.edu');
    if (!isStudentDomain) {
      return 'Students must use an Amrita student email (@cb.students.amrita.edu)';
    }
  } else if (role === 'Faculty') {
    const isFacultyDomain =
      (domain === 'cb.amrita.edu' || domain === 'amrita.edu' || domain.endsWith('.amrita.edu')) &&
      !domain.includes('students');
    if (!isFacultyDomain) {
      return 'Faculty must use an Amrita faculty email (@cb.amrita.edu)';
    }
  }

  return null;
}

function validatePhone(phone) {
  if (!phone || !phone.trim()) {
    return 'Please enter your phone number';
  }
  const digits = phone.replace(/\D/g, '');
  if (digits.length !== 10) {
    return 'Phone number must be exactly 10 digits';
  }
  if (!/^[6-9]\d{9}$/.test(digits)) {
    return 'Please enter a valid 10-digit mobile number';
  }
  return null;
}

function validateName(name) {
  if (!name || !name.trim()) {
    return 'Please enter your full name';
  }
  const clean = name.trim();
  if (clean.length < 2) {
    return 'Full name must be at least 2 characters';
  }
  if (!/^[a-zA-Z\s.'-]+$/.test(clean)) {
    return 'Name can only contain alphabets and spaces';
  }
  return null;
}

function validateRollNumber(rollNumber) {
  if (!rollNumber || !rollNumber.trim()) {
    return 'Please enter your Roll Number or Campus ID';
  }
  if (rollNumber.trim().length < 3) {
    return 'Campus ID / Roll Number must be at least 3 characters';
  }
  return null;
}

function validatePassword(password) {
  if (!password) {
    return 'Please enter your password';
  }
  if (password.length < 6) {
    return 'Password must be at least 6 characters long';
  }
  return null;
}

function validateLoginIdentityForRole(identity, role) {
  if (!identity || !identity.trim()) {
    return 'Please enter your email, 10-digit phone number, or roll number';
  }

  const clean = identity.trim();
  const digits = clean.replace(/\D/g, '');

  if (clean.includes('@')) {
    return validateEmailForRole(clean, role);
  }

  if (digits.length >= 10 && (digits === clean || clean.startsWith('+'))) {
    return validatePhone(digits.slice(-10));
  }

  if (clean.length < 3) {
    return 'Please enter a valid email, 10-digit phone, or roll number';
  }

  return null;
}

function signupValidator(req, res, next) {
  const { name, email, phone, rollNumber, password, role } = req.body;

  if (!role || !['Faculty', 'Student', 'Visitor'].includes(role.trim())) {
    return res.status(400).json({
      success: false,
      message: 'Invalid role selected. Must be Faculty, Student, or Visitor.',
    });
  }

  const cleanRole = role.trim();

  const nameErr = validateName(name);
  if (nameErr) return res.status(400).json({ success: false, message: nameErr });

  const emailErr = validateEmailForRole(email, cleanRole);
  if (emailErr) return res.status(400).json({ success: false, message: emailErr });

  const phoneErr = validatePhone(phone);
  if (phoneErr) return res.status(400).json({ success: false, message: phoneErr });

  const rollErr = validateRollNumber(rollNumber);
  if (rollErr) return res.status(400).json({ success: false, message: rollErr });

  const passErr = validatePassword(password);
  if (passErr) return res.status(400).json({ success: false, message: passErr });

  next();
}

function loginValidator(req, res, next) {
  const { identity, password, role } = req.body;

  if (!role || !['Faculty', 'Student', 'Visitor'].includes(role.trim())) {
    return res.status(400).json({
      success: false,
      message: 'Invalid role selected. Must be Faculty, Student, or Visitor.',
    });
  }

  const cleanRole = role.trim();

  const idErr = validateLoginIdentityForRole(identity, cleanRole);
  if (idErr) return res.status(400).json({ success: false, message: idErr });

  if (!password) {
    return res.status(400).json({ success: false, message: 'Please enter your password' });
  }

  next();
}

module.exports = {
  validateEmailForRole,
  validatePhone,
  validateName,
  validateRollNumber,
  validatePassword,
  validateLoginIdentityForRole,
  signupValidator,
  loginValidator,
};
