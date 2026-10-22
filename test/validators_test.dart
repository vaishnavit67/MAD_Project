import 'package:flutter_test/flutter_test.dart';
import 'package:campus_navigator/utils/validators.dart';

void main() {
  group('Role-Specific Email Validation Tests', () {
    test('Visitor Role requires @gmail.com', () {
      expect(FormValidators.validateEmailForRole('john@gmail.com', 'Visitor'), isNull);
      expect(
        FormValidators.validateEmailForRole('student@cb.students.amrita.edu', 'Visitor'),
        'Visitors must use a Gmail address (@gmail.com)',
      );
    });

    test('Student Role requires @cb.students.amrita.edu', () {
      expect(FormValidators.validateEmailForRole('ram@cb.students.amrita.edu', 'Student'), isNull);
      expect(FormValidators.validateEmailForRole('student@students.amrita.edu', 'Student'), isNull);
      expect(
        FormValidators.validateEmailForRole('john@gmail.com', 'Student'),
        'Students must use an Amrita student email (@cb.students.amrita.edu)',
      );
      expect(
        FormValidators.validateEmailForRole('prof@cb.amrita.edu', 'Student'),
        'Students must use an Amrita student email (@cb.students.amrita.edu)',
      );
    });

    test('Faculty Role requires @cb.amrita.edu', () {
      expect(FormValidators.validateEmailForRole('prof@cb.amrita.edu', 'Faculty'), isNull);
      expect(FormValidators.validateEmailForRole('faculty@amrita.edu', 'Faculty'), isNull);
      expect(
        FormValidators.validateEmailForRole('student@cb.students.amrita.edu', 'Faculty'),
        'Faculty must use an Amrita faculty email (@cb.amrita.edu)',
      );
      expect(
        FormValidators.validateEmailForRole('john@gmail.com', 'Faculty'),
        'Faculty must use an Amrita faculty email (@cb.amrita.edu)',
      );
    });
  });

  group('FormValidators Phone Tests', () {
    test('Valid 10-digit phone returns null', () {
      expect(FormValidators.validatePhone('9876543210'), isNull);
    });

    test('Invalid digit count returns count error', () {
      expect(FormValidators.validatePhone('12345'), 'Phone number must be exactly 10 digits');
    });

    test('Empty phone returns empty error', () {
      expect(FormValidators.validatePhone(''), 'Please enter your phone number');
    });
  });

  group('FormValidators Login Identity Role Tests', () {
    test('Student Login Identity accepts valid student email or 10-digit phone', () {
      expect(FormValidators.validateLoginIdentityForRole('student@cb.students.amrita.edu', 'Student'), isNull);
      expect(FormValidators.validateLoginIdentityForRole('9876543210', 'Student'), isNull);
    });

    test('Visitor Login Identity rejects student email under Visitor role', () {
      final result = FormValidators.validateLoginIdentityForRole('student@cb.students.amrita.edu', 'Visitor');
      expect(result, contains('Gmail'));
    });
  });
}
