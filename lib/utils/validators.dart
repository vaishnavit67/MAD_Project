class FormValidators {
  /// Validates email address format and enforces role-based domain requirements:
  /// - Visitor: @gmail.com
  /// - Student: @cb.students.amrita.edu (or @*.students.amrita.edu)
  /// - Faculty: @cb.amrita.edu (or @amrita.edu)
  static String? validateEmailForRole(String? value, String role) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }

    final trimmed = value.trim().toLowerCase();

    // Standard email regex format
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email format';
    }

    final parts = trimmed.split('@');
    if (parts.length != 2) return 'Invalid email address format';

    final domain = parts[1];

    if (role == 'Visitor') {
      if (domain != 'gmail.com') {
        return 'Visitors must use a Gmail address (@gmail.com)';
      }
    } else if (role == 'Student') {
      final isStudentDomain = domain == 'cb.students.amrita.edu' ||
          domain == 'students.amrita.edu' ||
          domain.endsWith('.students.amrita.edu');
      if (!isStudentDomain) {
        return 'Students must use an Amrita student email (@cb.students.amrita.edu)';
      }
    } else if (role == 'Faculty') {
      final isFacultyDomain = (domain == 'cb.amrita.edu' ||
              domain == 'amrita.edu' ||
              domain.endsWith('.amrita.edu')) &&
          !domain.contains('students');
      if (!isFacultyDomain) {
        return 'Faculty must use an Amrita faculty email (@cb.amrita.edu)';
      }
    } else {
      // General check if role is unspecified
      final isGmail = domain == 'gmail.com';
      final isAmrita = domain == 'amrita.edu' || domain.endsWith('.amrita.edu');
      if (!isGmail && !isAmrita) {
        return 'Must be a valid Gmail (@gmail.com) or Amrita email (@amrita.edu)';
      }
    }

    return null;
  }

  /// Legacy helper for general email validation without role context
  static String? validateEmail(String? value) {
    return validateEmailForRole(value, '');
  }

  /// Validates mobile phone number to ensure proper digit count (10 digits).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digitsOnly)) {
      return 'Please enter a valid 10-digit mobile number';
    }

    return null;
  }

  /// Validates login identity input (Email, Phone, or Roll Number) based on the selected Role.
  static String? validateLoginIdentityForRole(String? value, String role) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email, phone, or roll number';
    }

    final trimmed = value.trim();

    // 1. If contains @, treat as email and validate domain for role
    if (trimmed.contains('@')) {
      return validateEmailForRole(trimmed, role);
    }

    // 2. If digits only (or international phone format with +), validate phone
    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if ((digitsOnly.length == 10 && digitsOnly == trimmed) || (trimmed.startsWith('+') && digitsOnly.length >= 10)) {
      return validatePhone(digitsOnly.substring(digitsOnly.length - 10));
    }

    // 3. Otherwise treat as Roll Number / Campus ID
    if (trimmed.length < 3) {
      return 'Please enter a valid email, 10-digit phone, or roll number';
    }

    return null;
  }

  /// Legacy helper for login identity validation without role context
  static String? validateLoginIdentity(String? value) {
    return validateLoginIdentityForRole(value, '');
  }

  /// Validates full name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }

    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Full name must be at least 2 characters';
    }

    if (!RegExp(r"^[a-zA-Z\s\.\'-]+$").hasMatch(trimmed)) {
      return 'Name can only contain alphabets and spaces';
    }

    return null;
  }

  /// Validates Roll Number / Campus ID
  static String? validateRollNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your Roll Number or Campus ID';
    }

    if (value.trim().length < 3) {
      return 'Campus ID / Roll Number must be at least 3 characters';
    }

    return null;
  }

  /// Validates password length and complexity
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  /// Validates password confirmation
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }
}
