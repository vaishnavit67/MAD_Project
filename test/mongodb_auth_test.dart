import 'package:flutter_test/flutter_test.dart';
import 'package:campus_navigator/services/mongodb_service.dart';
import 'package:campus_navigator/services/auth_service.dart';

void main() {
  final mongoService = MongoDbService.instance;
  final authService = AuthService();

  setUp(() async {
    // Reset to clean state with seed users before each test
    await mongoService.resetToSeedData();
  });

  group('MongoDB Table Separation & Role Mapping', () {
    test('Role names map accurately to specific MongoDB tables (collections)', () {
      expect(MongoDbService.getCollectionNameForRole('Faculty'), 'faculty');
      expect(MongoDbService.getCollectionNameForRole('Student'), 'students');
      expect(MongoDbService.getCollectionNameForRole('Visitor'), 'visitors');
      expect(MongoDbService.getCollectionNameForRole('Unknown'), 'students');
    });

    test('Pre-seeded demo accounts are placed in their respective role tables', () async {
      final students = await mongoService.getUsersInTable('students');
      final faculty = await mongoService.getUsersInTable('faculty');
      final visitors = await mongoService.getUsersInTable('visitors');

      expect(students.any((u) => u.email == 'student@cb.students.amrita.edu'), isTrue);
      expect(faculty.any((u) => u.email == 'faculty@cb.amrita.edu'), isTrue);
      expect(visitors.any((u) => u.email == 'user@gmail.com'), isTrue);
    });
  });

  group('MongoDB User Registration Validation', () {
    test('Rejects registration if student does not use Amrita student domain', () async {
      final result = await mongoService.registerUser(
        name: 'John Doe',
        email: 'john@gmail.com', // Invalid for student
        phone: '9876543220',
        rollNumber: 'CB.EN.U4CSE21099',
        password: 'securePassword123',
        role: 'Student',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Amrita student email'));
    });

    test('Rejects registration if faculty does not use Amrita faculty domain', () async {
      final result = await mongoService.registerUser(
        name: 'Dr. Smith',
        email: 'smith@cb.students.amrita.edu', // Student domain, invalid for faculty
        phone: '9876543221',
        rollNumber: 'EMP2001',
        password: 'securePassword123',
        role: 'Faculty',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Amrita faculty email'));
    });

    test('Rejects registration if visitor does not use Gmail address', () async {
      final result = await mongoService.registerUser(
        name: 'Guest User',
        email: 'guest@yahoo.com', // Invalid for visitor
        phone: '9876543222',
        rollNumber: 'VIS099',
        password: 'securePassword123',
        role: 'Visitor',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Gmail address'));
    });

    test('Rejects registration if phone is invalid', () async {
      final result = await mongoService.registerUser(
        name: 'Valid Name',
        email: 'newuser@cb.students.amrita.edu',
        phone: '12345', // Not 10 digits
        rollNumber: 'CB21001',
        password: 'password123',
        role: 'Student',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('10 digits'));
    });

    test('Rejects registration if password is under 6 characters', () async {
      final result = await mongoService.registerUser(
        name: 'Valid Name',
        email: 'newuser@cb.students.amrita.edu',
        phone: '9876543230',
        rollNumber: 'CB21001',
        password: '123', // Too short
        role: 'Student',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('at least 6 characters'));
    });
  });

  group('MongoDB User Registration & Table Partitioning', () {
    test('Successfully registers a student into the "students" MongoDB table', () async {
      final result = await mongoService.registerUser(
        name: 'Kavitha R',
        email: 'kavitha@cb.students.amrita.edu',
        phone: '9876500001',
        rollNumber: 'CB.EN.U4CSE21055',
        password: 'myPassword@2026',
        role: 'Student',
      );

      expect(result.success, isTrue);
      expect(result.message, contains('students table'));
      expect(result.user, isNotNull);
      expect(result.user!.role, 'Student');
      expect(result.user!.category, 'students');

      // Verify stored password is a SHA-256 hash, not plain text
      expect(result.user!.passwordHash, isNot('myPassword@2026'));
      expect(result.user!.passwordHash.length, 64); // SHA-256 hex string length

      // Verify user is in 'students' table and NOT in 'faculty' or 'visitors' table
      final students = await mongoService.getUsersInTable('students');
      final faculty = await mongoService.getUsersInTable('faculty');
      final visitors = await mongoService.getUsersInTable('visitors');

      expect(students.any((u) => u.email == 'kavitha@cb.students.amrita.edu'), isTrue);
      expect(faculty.any((u) => u.email == 'kavitha@cb.students.amrita.edu'), isFalse);
      expect(visitors.any((u) => u.email == 'kavitha@cb.students.amrita.edu'), isFalse);
    });

    test('Successfully registers a faculty into the "faculty" MongoDB table', () async {
      final result = await mongoService.registerUser(
        name: 'Dr. Rajesh',
        email: 'rajesh@cb.amrita.edu',
        phone: '9876500002',
        rollNumber: 'EMP3042',
        password: 'profPassword2026',
        role: 'Faculty',
      );

      expect(result.success, isTrue);
      expect(result.message, contains('faculty table'));
      expect(result.user!.category, 'faculty');

      final faculty = await mongoService.getUsersInTable('faculty');
      expect(faculty.any((u) => u.email == 'rajesh@cb.amrita.edu'), isTrue);
    });

    test('Successfully registers a visitor into the "visitors" MongoDB table', () async {
      final result = await mongoService.registerUser(
        name: 'Parent Visitor',
        email: 'parent.visitor@gmail.com',
        phone: '9876500003',
        rollNumber: 'VIS5001',
        password: 'visitorPassword123',
        role: 'Visitor',
      );

      expect(result.success, isTrue);
      expect(result.message, contains('visitors table'));
      expect(result.user!.category, 'visitors');

      final visitors = await mongoService.getUsersInTable('visitors');
      expect(visitors.any((u) => u.email == 'parent.visitor@gmail.com'), isTrue);
    });

    test('Prevents duplicate email registrations across tables', () async {
      final first = await mongoService.registerUser(
        name: 'Student One',
        email: 'student.dup@cb.students.amrita.edu',
        phone: '9876500010',
        rollNumber: 'CB101',
        password: 'password123',
        role: 'Student',
      );
      expect(first.success, isTrue);

      final second = await mongoService.registerUser(
        name: 'Student Two',
        email: 'student.dup@cb.students.amrita.edu', // Duplicate
        phone: '9876500011',
        rollNumber: 'CB102',
        password: 'password123',
        role: 'Student',
      );
      expect(second.success, isFalse);
      expect(second.message, contains('already exists'));
    });

    test('Prevents duplicate phone registrations across tables', () async {
      final first = await mongoService.registerUser(
        name: 'Faculty One',
        email: 'fac1@cb.amrita.edu',
        phone: '9876500020',
        rollNumber: 'EMP11',
        password: 'password123',
        role: 'Faculty',
      );
      expect(first.success, isTrue);

      final second = await mongoService.registerUser(
        name: 'Faculty Two',
        email: 'fac2@cb.amrita.edu',
        phone: '9876500020', // Duplicate phone
        rollNumber: 'EMP12',
        password: 'password123',
        role: 'Faculty',
      );
      expect(second.success, isFalse);
      expect(second.message, contains('already exists'));
    });
  });

  group('MongoDB User Authentication & Login', () {
    test('Logs in successfully with email and valid password for Student role', () async {
      final result = await mongoService.authenticateUser(
        identity: 'student@cb.students.amrita.edu',
        password: 'password123',
        role: 'Student',
      );

      expect(result.success, isTrue);
      expect(result.message, 'Logged in successfully as Student!');
      expect(result.user, isNotNull);
      expect(result.user!.email, 'student@cb.students.amrita.edu');
    });

    test('Logs in successfully with 10-digit phone number for Student role', () async {
      final result = await mongoService.authenticateUser(
        identity: '9876543210',
        password: 'password123',
        role: 'Student',
      );

      expect(result.success, isTrue);
      expect(result.message, 'Logged in successfully as Student!');
      expect(result.user!.phone, '9876543210');
    });

    test('Rejects login when incorrect password is provided', () async {
      final result = await mongoService.authenticateUser(
        identity: 'student@cb.students.amrita.edu',
        password: 'wrongPassword',
        role: 'Student',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Incorrect password'));
    });

    test('Informs user if trying to log in under wrong role tab', () async {
      // User registered as Student attempts to log in under Faculty role
      final result = await mongoService.authenticateUser(
        identity: '9876543210', // Registered under Student
        password: 'password123',
        role: 'Faculty',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('This account is registered as Student'));
      expect(result.message, contains('Please select the Student tab'));
    });

    test('Reports not found when identity does not exist in any collection', () async {
      final result = await mongoService.authenticateUser(
        identity: 'nonexistent@cb.students.amrita.edu',
        password: 'password123',
        role: 'Student',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('No registered account found'));
    });
  });

  group('AuthService Integration with MongoDB', () {
    test('AuthService.signUpUser stores in MongoDB and AuthService.signInUser authenticates from it', () async {
      final signUpResult = await authService.signUpUser(
        name: 'Amrita Scholar',
        email: 'scholar@cb.students.amrita.edu',
        phone: '9876599999',
        rollNumber: 'CB.EN.RS21001',
        password: 'ScholarPass#2026',
        role: 'Student',
      );

      expect(signUpResult.success, isTrue);

      final signInResult = await authService.signInUser(
        identity: 'scholar@cb.students.amrita.edu',
        password: 'ScholarPass#2026',
        role: 'Student',
      );

      expect(signInResult.success, isTrue);
      expect(signInResult.message, 'Logged in successfully as Student!');
      expect(signInResult.user!.name, 'Amrita Scholar');
    });
  });
}
